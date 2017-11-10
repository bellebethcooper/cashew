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
    
    private static let baseURL = "http://cashew-api.herokuapp.com"
    private static let apiPath = "/file/get_upload_url"
    private static let basicAuthUsername = "cashewapp"
    private static let basicAuthPassword = "<FILL_ON_RELEASE>"
    
    func uploadFile(filename: String, onCompletion: QServiceOnCompletion) {
        var fileExtension: String = ""
        
        if let ext = NSURL(fileURLWithPath: filename).pathExtension {
            fileExtension = ext
        }
        
        let account = QContext.sharedContext().currentAccount
        let username = QOwnerStore.ownerForAccountId(account.identifier, identifier: account.userId).login
        let params = [ "username": username, "extension": fileExtension, "hostname": account.baseURL.host ]
        
        let sessionConfig = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        sessionConfig.requestCachePolicy = .ReloadIgnoringLocalCacheData
        let manager = AFHTTPSessionManager(baseURL: NSURL(string: FileUploaderService.baseURL), sessionConfiguration: sessionConfig)
        manager.responseSerializer = AFJSONResponseSerializer()
        manager.requestSerializer.setAuthorizationHeaderFieldWithUsername(FileUploaderService.basicAuthUsername, password: FileUploaderService.basicAuthPassword)
        manager.POST(FileUploaderService.apiPath, parameters: params, progress: nil, success: { (task, obj) in
            if let obj = obj, uploadURL = obj["upload_url"] as? String, contentURL = obj["content_url"] as? String {
                self.doUpload(filename, uploadURL: uploadURL, contentURL: contentURL, onCompletion: onCompletion)
            } else {
                onCompletion(nil, QServiceResponseContext(), NSError(domain: "com.simplerocket.cashew.FileUploaderService", code: 0, userInfo: nil))
            }
        }) { (task, err) in
            onCompletion(nil, QServiceResponseContext(), err)
            
        }
    }
    
    func uploadImage(image: NSImage, onCompletion: QServiceOnCompletion) {
        guard let data = image.imagePNGRepresentation else {
            onCompletion(nil, QServiceResponseContext(), NSError(domain: "com.simplerocket.cashew.FileUploaderService.uploadImage.PNGData", code: 0, userInfo: nil))
            return
        }
        
        let account = QContext.sharedContext().currentAccount
        let username = QOwnerStore.ownerForAccountId(account.identifier, identifier: account.userId).login
        let params = [ "username": username, "extension": "png" ]
        
        let sessionConfig = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        sessionConfig.requestCachePolicy = .ReloadIgnoringLocalCacheData
        let manager = AFHTTPSessionManager(baseURL: NSURL(string: FileUploaderService.baseURL), sessionConfiguration: sessionConfig)
        manager.responseSerializer = AFJSONResponseSerializer()
        manager.requestSerializer.setAuthorizationHeaderFieldWithUsername(FileUploaderService.basicAuthUsername, password: FileUploaderService.basicAuthPassword)
        manager.POST(FileUploaderService.apiPath, parameters: params, progress: nil, success: {[weak self] (task, obj) in
            if let obj = obj, uploadURL = obj["upload_url"] as? String, contentURL = obj["content_url"] as? String {
                self?.doUploadUsingData(data, mimeType: "image/png", uploadURL: uploadURL, contentURL: contentURL, onCompletion: onCompletion)
                
            } else {
                onCompletion(nil, QServiceResponseContext(), NSError(domain: "com.simplerocket.cashew.FileUploaderService", code: 0, userInfo: nil))
            }
        }) { (task, err) in
            onCompletion(nil, QServiceResponseContext(), err)
            
        }
    }
    
    private func doUpload(filename: String, uploadURL: String, contentURL: String, onCompletion: QServiceOnCompletion) {
        guard let data = NSFileManager.defaultManager().contentsAtPath(filename) where (Double(data.length)/1024.0/1024.0) <= 10.0 else {
            onCompletion(nil, QServiceResponseContext(), NSError(domain: "com.simplerocket.cashew.FileUploaderService.doUpload", code: 80085, userInfo: nil))
            return
        }
        
        doUploadUsingData(data, mimeType: filename.mimeType(), uploadURL: uploadURL, contentURL: contentURL, onCompletion: onCompletion)
    }
    
    private func doUploadUsingData(data: NSData, mimeType: String, uploadURL: String, contentURL: String, onCompletion: QServiceOnCompletion) {
        let sessionConfig = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        sessionConfig.requestCachePolicy = .ReloadIgnoringLocalCacheData
        
        let manager = AFHTTPSessionManager(sessionConfiguration: sessionConfig)
        manager.requestSerializer.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        
        let request = manager.requestSerializer.requestWithMethod("PUT", URLString: uploadURL, parameters: nil, error: nil)
        let task = manager.uploadTaskWithRequest(request, fromData: data, progress: nil) { (response, obj, err) in
            if let err = err {
                if let errData = err.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] as? NSData, errorString = NSString(data: errData, encoding:NSUTF8StringEncoding) {
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

