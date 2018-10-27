//
//  FMResultSet.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/21/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation
import FMDB


extension FMResultSet {
    
    func hasColumnNamed(_ named: String) -> Bool {
        return columnNameToIndexMap[named] != nil
    }
}
