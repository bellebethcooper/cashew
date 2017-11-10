//
//  ExtensionCloudKitService.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/1/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import CloudKit

class ExtensionCloudKitService: BaseCloudKitService {
    
    func syncCodeExtensions(onCompletion: CloudOnCompletion) {
        let container = CKContainer.defaultContainer()
        container.fetchUserRecordIDWithCompletionHandler { (currentUserId, err) in
            guard let currentUserId = currentUserId where err == nil else {
                onCompletion(nil, err)
                return
            }

            
            let predicate = NSPredicate(format: "creatorUserRecordID = %@", currentUserId)
            let query = CKQuery(recordType: CloudRecordType.CodeExtension.rawValue, predicate: predicate)
            let db = CKContainer.defaultContainer().publicCloudDatabase
            
            db.performQuery(query, inZoneWithID: nil, completionHandler: { (records, queryErr) in
                guard let records = records where queryErr == nil else {
                    onCompletion(nil, queryErr)
                    return;
                }
                
                var codeExtensions = [SRExtension]()
                records.forEach({ (record) in
                    guard let sourceCode = record["sourceCode"] as? String, name = record["name"] as? String, extensionTypeInt = record["extensionType"] as? UInt else { return }
                    let extensionType = SRExtensionType(rawValue: extensionTypeInt)
                    let keyboardShortcut = record["keyboardShortcut"] as? String
                    
                    let codeExtension = SRExtension(sourceCode: sourceCode, externalId: record.recordID.recordName, name: name, extensionType: extensionType, draftSourceCode: nil, keyboardShortcut: keyboardShortcut, updatedAt: record.modificationDate ?? record.creationDate!)
                    
                    if let isDeleted = record["deleted"] as? Bool where isDeleted == true {
                        SRExtensionStore.deleteExtension(codeExtension)
                    } else {
                        SRExtensionStore.saveExtension(codeExtension)
                        codeExtensions.append(codeExtension)
                    }
                })
                
                onCompletion(codeExtensions, nil)
            })
            
        }
        
    }
    
    
    func saveCodeExtension(sourceCode: String, name: String, recordNameId: String?, keyboardShortcut: String?, extensionType: SRExtensionType, onCompletion: CloudOnCompletion) {
        let db = CKContainer.defaultContainer().publicCloudDatabase
        
        if let recordName = recordNameId {
            let recordId = CKRecordID(recordName: recordName)
            db.fetchRecordWithID(recordId, completionHandler: { (record, err) in
                guard let record = record where err == nil else {
                    onCompletion(nil, err)
                    return;
                }
                
                record["name"] = name
                record["sourceCode"] = sourceCode
                //record["keyboardShortcut"] = keyboardShortcut
                record["extensionType"] = extensionType.rawValue
                record["deleted"] = false
                
                db.saveRecord(record, completionHandler: { (saveRecord, saveError) in
                    guard let saveRecord = saveRecord where saveError == nil else {
                        onCompletion(nil, saveError)
                        return;
                    }
                    let codeExtension = SRExtension(sourceCode: sourceCode, externalId: saveRecord.recordID.recordName, name: name, extensionType: extensionType, draftSourceCode: nil, keyboardShortcut: keyboardShortcut, updatedAt: saveRecord.modificationDate ?? saveRecord.creationDate!)
                    SRExtensionStore.saveExtension(codeExtension)
                    onCompletion(codeExtension, nil)
                })
                
                
            })
        } else {
            
            let record = CKRecord(recordType: CloudRecordType.CodeExtension.rawValue)
            record["name"] = name
            record["sourceCode"] = sourceCode
            //record["keyboardShortcut"] = keyboardShortcut
            record["extensionType"] = extensionType.rawValue
            record["deleted"] = false
            
            db.saveRecord(record, completionHandler: { (saveRecord, saveError) in
                guard let saveRecord = saveRecord where saveError == nil else {
                    onCompletion(nil, saveError)
                    return;
                }
                
                let codeExtension = SRExtension(sourceCode: sourceCode, externalId: saveRecord.recordID.recordName, name: name, extensionType: extensionType, draftSourceCode: nil, keyboardShortcut: keyboardShortcut, updatedAt: saveRecord.modificationDate ?? saveRecord.creationDate!)
                SRExtensionStore.saveExtension(codeExtension)
                onCompletion(codeExtension, nil)
            })
        }
        
    }
    
    
    func deleteCodeExtension(codeExtension: SRExtension, onCompletion: CloudOnCompletion) {
        let db = CKContainer.defaultContainer().publicCloudDatabase
        let recordId = CKRecordID(recordName: codeExtension.externalId)
        
        SRExtensionStore.deleteExtension(codeExtension)
        
        db.fetchRecordWithID(recordId, completionHandler: { (currentRecord, err) in
            guard let currentRecord = currentRecord where err == nil else {
                onCompletion(nil, err)
                return;
            }
            
            currentRecord["deleted"] = true
            
            db.saveRecord(currentRecord, completionHandler: { (record, saveError) in
                
                guard let record = record where saveError == nil else {
                    onCompletion(nil, saveError)
                    return;
                }
                
                guard let sourceCode = record["sourceCode"] as? String, name = record["name"] as? String, extensionTypeInt = record["extensionType"] as? UInt else { return }
                let extensionType = SRExtensionType(rawValue: extensionTypeInt)
                let keyboardShortcut = record["keyboardShortcut"] as? String
                
                let updatedCodeExtension = SRExtension(sourceCode: sourceCode, externalId: record.recordID.recordName, name: name, extensionType: extensionType, draftSourceCode: nil, keyboardShortcut: keyboardShortcut, updatedAt: record.modificationDate ?? record.creationDate!)
                
                onCompletion(updatedCodeExtension, nil)
            })
            
        })
    }
    
    
}
