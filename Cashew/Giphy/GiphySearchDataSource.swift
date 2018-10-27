//
//  GiphySearchDataSource.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/29/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa

@objc(SRGiphySearchDataSource)
class GiphySearchDataSource: NSObject {

    fileprivate var items = [GiphyImage]()
    fileprivate let service = GiphyService()
    fileprivate var currentSearch = ""
    fileprivate let coalescer = Coalescer(interval: 0.4, name: "co.cashewapp.GiphySearchDataSource", executionQueue: DispatchQueue(label: "co.cashewapp.GiphySearchDataSource.resultExecutionQueue", attributes: []))
    
    var numberOfRows: Int {
        return items.count
    }
    
    
    func itemAtIndex(_ index: Int) -> GiphyImage {
        return items[index]
    }
    
    func search(_ query: String, onCompletion: @escaping ()->()) {
        coalescer.executeBlock { [weak self] in
            if (query as NSString).trimmedString().length == 0 {
                self?.currentSearch = ""
                self?.items = [GiphyImage]()
                onCompletion()
                return
            }
            
            self?.currentSearch = query
            self?.service.search(query, onCompletion: { (obj, context, err) in
                if let obj = obj as? [AnyHashable: Any], let searchQuery = obj["searchQuery"] as? String, let result = obj["data"] as? [GiphyImage] , self?.currentSearch == searchQuery {
                    self?.items = result
                }
                onCompletion()
            })
        }
    }
}
