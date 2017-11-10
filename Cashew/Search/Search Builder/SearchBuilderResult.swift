//
//  SearchBuilderResult.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/27/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation


@objc(SRSearchBuilderResult)
class SearchBuilderResult: NSObject {
    
    let criteriaType: String
    let partOfSpeech: String?
    let criteriaValue: String?
    
    required init(criteriaType: String, partOfSpeech: String?, criteriaValue: String?) {
        self.criteriaType = criteriaType
        self.partOfSpeech = partOfSpeech
        self.criteriaValue = criteriaValue
        super.init()
    }
    
}