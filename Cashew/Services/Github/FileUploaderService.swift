//
//  FileUploaderService.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 6/19/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa
import AFNetworking
import Foundation

class FileUploaderService: NSObject {
    
    fileprivate static let baseURL = "http://cashew-api.herokuapp.com"
    fileprivate static let apiPath = "/file/get_upload_url"
    fileprivate static let basicAuthUsername = "cashewapp"
    fileprivate static let basicAuthPassword = "<FILL_ON_RELEASE>"
    
    func uploadFile(_ filename: String, onCompletion: @escaping QServiceOnCompletion) {
        var fileExtension: String = ""
        
        let ext = URL(fileURLWithPath: filename).pathExtension
        fileExtension = ext
        
        let account = QContext.shared().currentAccount
        let username = QOwnerStore.owner(forAccountId: account?.identifier, identifier: account?.userId).login
        let params = [ "username": username, "extension": fileExtension, "hostname": account?.baseURL.host ]
        
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        let manager = AFHTTPSessionManager(baseURL: URL(string: FileUploaderService.baseURL), sessionConfiguration: sessionConfig)
        manager.responseSerializer = AFJSONResponseSerializer()
        manager.requestSerializer.setAuthorizationHeaderFieldWithUsername(FileUploaderService.basicAuthUsername, password: FileUploaderService.basicAuthPassword)
        manager.post(FileUploaderService.apiPath, parameters: params, progress: nil, success: { (task, obj) in
            if let obj = obj as? [String: Any], let uploadURL = obj["upload_url"] as? String, let contentURL = obj["content_url"] as? String {
                self.doUpload(filename, uploadURL: uploadURL, contentURL: contentURL, onCompletion: onCompletion)
            } else {
                onCompletion(nil, QServiceResponseContext(), NSError(domain: "com.simplerocket.cashew.FileUploaderService", code: 0, userInfo: nil))
            }
        }) { (task, err) in
            onCompletion(nil, QServiceResponseContext(), err)
            
        }
    }
    
    func uploadImage(_ image: NSImage, onCompletion: @escaping QServiceOnCompletion) {
        guard let data = image.imagePNGRepresentation else {
            onCompletion(nil, QServiceResponseContext(), NSError(domain: "com.simplerocket.cashew.FileUploaderService.uploadImage.PNGData", code: 0, userInfo: nil))
            return
        }
        
        let account = QContext.shared().currentAccount
        let username = QOwnerStore.owner(forAccountId: account?.identifier, identifier: account?.userId).login
        let params = [ "username": username, "extension": "png" ]
        
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        let manager = AFHTTPSessionManager(baseURL: URL(string: FileUploaderService.baseURL), sessionConfiguration: sessionConfig)
        manager.responseSerializer = AFJSONResponseSerializer()
        manager.requestSerializer.setAuthorizationHeaderFieldWithUsername(FileUploaderService.basicAuthUsername, password: FileUploaderService.basicAuthPassword)
        manager.post(FileUploaderService.apiPath, parameters: params, progress: nil, success: {[weak self] (task, obj) in
            if let obj = obj as? [String: Any], let uploadURL = obj["upload_url"] as? String, let contentURL = obj["content_url"] as? String {
                self?.doUploadUsingData(data as Data, mimeType: "image/png", uploadURL: uploadURL, contentURL: contentURL, onCompletion: onCompletion)
                
            } else {
                onCompletion(nil, QServiceResponseContext(), NSError(domain: "com.simplerocket.cashew.FileUploaderService", code: 0, userInfo: nil))
            }
        }) { (task, err) in
            onCompletion(nil, QServiceResponseContext(), err)
            
        }
    }
    
    fileprivate func doUpload(_ filename: String, uploadURL: String, contentURL: String, onCompletion: @escaping QServiceOnCompletion) {
        guard let data = FileManager.default.contents(atPath: filename) , (Double(data.count)/1024.0/1024.0) <= 10.0 else {
            onCompletion(nil, QServiceResponseContext(), NSError(domain: "com.simplerocket.cashew.FileUploaderService.doUpload", code: 80085, userInfo: nil))
            return
        }
        
        doUploadUsingData(data, mimeType: filename.mimeType(), uploadURL: uploadURL, contentURL: contentURL, onCompletion: onCompletion)
    }
    
    fileprivate func doUploadUsingData(_ data: Data, mimeType: String, uploadURL: String, contentURL: String, onCompletion: @escaping QServiceOnCompletion) {
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        let manager = AFHTTPSessionManager(sessionConfiguration: sessionConfig)
        manager.requestSerializer.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        
        let request = manager.requestSerializer.request(withMethod: "PUT", urlString: uploadURL, parameters: nil, error: nil)
        let task = manager.uploadTask(with: request as URLRequest, from: data, progress: nil) { (response, obj, err) in
            if let err = err as? NSError {
                if let errData = err.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] as? Data, let errorString = NSString(data: errData, encoding:String.Encoding.utf8.rawValue) {
                    DDLogDebug("error_json \(errorString)")
                }
                onCompletion(nil, QServiceResponseContext(), err)
            } else {
                onCompletion(["content_url": contentURL], QServiceResponseContext(), nil)
            }
        }
        task.resume()
    }
}

