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

    private var items = [GiphyImage]()
    private let service = GiphyService()
    private var currentSearch = ""
    private let coalescer = Coalescer(interval: 0.4, name: "co.cashewapp.GiphySearchDataSource", executionQueue: dispatch_queue_create("co.cashewapp.GiphySearchDataSource.resultExecutionQueue", DISPATCH_QUEUE_SERIAL))
    
    var numberOfRows: Int {
        return items.count
    }
    
    
    func itemAtIndex(index: Int) -> GiphyImage {
        return items[index]
    }
    
    func search(query: String, onCompletion: dispatch_block_t) {
        coalescer.executeBlock { [weak self] in
            if (query as NSString).trimmedString().length == 0 {
                self?.currentSearch = ""
                self?.items = [GiphyImage]()
                onCompletion()
                return
            }
            
            self?.currentSearch = query
            self?.service.search(query, onCompletion: { (obj, context, err) in
                if let obj = obj as? [NSObject:AnyObject], searchQuery = obj["searchQuery"] as? String, result = obj["data"] as? [GiphyImage] where self?.currentSearch == searchQuery {
                    self?.items = result
                }
                onCompletion()
            })
        }
    }
}
