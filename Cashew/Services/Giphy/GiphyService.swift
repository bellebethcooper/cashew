//
//  GiphyService.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/29/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa
import AFNetworking

class GiphyService: NSObject {

    
    func search(_ query: String, onCompletion: @escaping QServiceOnCompletion) {
        
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
        let manager = AFHTTPSessionManager(baseURL: URL(string: "http://api.giphy.com"), sessionConfiguration: sessionConfig)
        manager.responseSerializer = AFJSONResponseSerializer()
        
        let params = ["q": query, "api_key": "l46ClSDSscTCNPM7m"]
        manager.get("v1/gifs/search", parameters: params, progress: nil, success: { (task, obj) in
            
            if let obj = obj as? [String: Any], let data = obj["data"] as? [NSDictionary] {
                
                var giphys = [GiphyImage]()
                data.forEach({ (gif) in
                    guard let images = gif["images"] as? NSDictionary else { return }
                    guard let original = images["original"] as? NSDictionary  else { return }
                    
                    if let urlString = original["url"] as? String, let url = NSURL(string: urlString), let width = original["width"] as? String, let height = original["height"] as? String, let mp4URLString = original["mp4"] as? String, let mp4URL = NSURL(string: mp4URLString) {
                        //DDLogDebug("Giphy URL -> \(url)")
                        if let caption = images["caption"] as? String {
                            let giphy = GiphyImage(url:  url as URL, mp4URL: mp4URL as URL, width: CGFloat(Int(width)!), height: CGFloat(Int(height)!), caption: caption)
                            giphys.append(giphy)
                        } else {
                            let giphy = GiphyImage(url:  url as URL, mp4URL: mp4URL as URL, width: CGFloat(Int(width)!), height: CGFloat(Int(height)!), caption: nil)
                            giphys.append(giphy)
                        }
                    }
                })
                
                onCompletion([ "searchQuery": query, "data" : giphys ], QServiceResponseContext(), NSError(domain: "co.cashewapp.GiphyService", code: 0, userInfo: nil))
            }
            
            onCompletion(nil, QServiceResponseContext(), NSError(domain: "co.cashewapp.GiphyService", code: 0, userInfo: nil))
        }) { (task, err) in
            onCompletion(nil, QServiceResponseContext(), err)
            
        }
    }
    
}

