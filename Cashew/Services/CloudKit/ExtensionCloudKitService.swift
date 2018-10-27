//
//  ExtensionCloudKitService.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/1/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import CloudKit

class ExtensionCloudKitService: BaseCloudKitService {
    
    func syncCodeExtensions(_ onCompletion: @escaping CloudOnCompletion) {
        let container = CKContainer.default()
        container.fetchUserRecordID { (currentUserId, err) in
            guard let currentUserId = currentUserId , err == nil else {
                onCompletion(nil, err as NSError?)
                return
            }

            
            let predicate = NSPredicate(format: "creatorUserRecordID = %@", currentUserId)
            let query = CKQuery(recordType: CloudRecordType.CodeExtension.rawValue, predicate: predicate)
            let db = CKContainer.default().publicCloudDatabase
            
            db.perform(query, inZoneWith: nil, completionHandler: { (records, queryErr) in
                guard let records = records , queryErr == nil else {
                    onCompletion(nil, queryErr as NSError?)
                    return;
                }
                
                var codeExtensions = [SRExtension]()
                records.forEach({ (record) in
                    guard let sourceCode = record["sourceCode"] as? String, let name = record["name"] as? String, let extensionTypeInt = record["extensionType"] as? UInt else { return }
                    let extensionType = SRExtensionType(rawValue: extensionTypeInt)
                    let keyboardShortcut = record["keyboardShortcut"] as? String
                    
                    let codeExtension = SRExtension(sourceCode: sourceCode, externalId: record.recordID.recordName, name: name, extensionType: extensionType, draftSourceCode: nil, keyboardShortcut: keyboardShortcut, updatedAt: record.modificationDate ?? record.creationDate!)
                    
                    if let isDeleted = record["deleted"] as? Bool , isDeleted == true {
                        SRExtensionStore.delete(codeExtension)
                    } else {
                        SRExtensionStore.save(codeExtension)
                        codeExtensions.append(codeExtension)
                    }
                })
                
                onCompletion(codeExtensions as AnyObject, nil)
            })
            
        }
        
    }
    
    
    func saveCodeExtension(_ sourceCode: String, name: String, recordNameId: String?, keyboardShortcut: String?, extensionType: SRExtensionType, onCompletion: @escaping CloudOnCompletion) {
        let db = CKContainer.default().publicCloudDatabase
        
        if let recordName = recordNameId {
            let recordId = CKRecordID(recordName: recordName)
            db.fetch(withRecordID: recordId, completionHandler: { (record, err) in
                guard let record = record , err == nil else {
                    onCompletion(nil, err as NSError?)
                    return;
                }
                
                record["name"] = name as CKRecordValue?
                record["sourceCode"] = sourceCode as CKRecordValue?
                //record["keyboardShortcut"] = keyboardShortcut
                record["extensionType"] = extensionType.rawValue as CKRecordValue
                record["deleted"] = false as CKRecordValue?
                
                db.save(record, completionHandler: { (saveRecord, saveError) in
                    guard let saveRecord = saveRecord , saveError == nil else {
                        onCompletion(nil, saveError as NSError?)
                        return;
                    }
                    let codeExtension = SRExtension(sourceCode: sourceCode, externalId: saveRecord.recordID.recordName, name: name, extensionType: extensionType, draftSourceCode: nil, keyboardShortcut: keyboardShortcut, updatedAt: saveRecord.modificationDate ?? saveRecord.creationDate!)
                    SRExtensionStore.save(codeExtension)
                    onCompletion(codeExtension, nil)
                })
                
                
            })
        } else {
            
            let record = CKRecord(recordType: CloudRecordType.CodeExtension.rawValue)
            record["name"] = name as CKRecordValue?
            record["sourceCode"] = sourceCode as CKRecordValue?
            //record["keyboardShortcut"] = keyboardShortcut
            record["extensionType"] = extensionType.rawValue as CKRecordValue
            record["deleted"] = false as CKRecordValue?
            
            db.save(record, completionHandler: { (saveRecord, saveError) in
                guard let saveRecord = saveRecord , saveError == nil else {
                    onCompletion(nil, saveError as NSError?)
                    return;
                }
                
                let codeExtension = SRExtension(sourceCode: sourceCode, externalId: saveRecord.recordID.recordName, name: name, extensionType: extensionType, draftSourceCode: nil, keyboardShortcut: keyboardShortcut, updatedAt: saveRecord.modificationDate ?? saveRecord.creationDate!)
                SRExtensionStore.save(codeExtension)
                onCompletion(codeExtension, nil)
            })
        }
        
    }
    
    
    func deleteCodeExtension(_ codeExtension: SRExtension, onCompletion: @escaping CloudOnCompletion) {
        let db = CKContainer.default().publicCloudDatabase
        let recordId = CKRecordID(recordName: codeExtension.externalId)
        
        SRExtensionStore.delete(codeExtension)
        
        db.fetch(withRecordID: recordId, completionHandler: { (currentRecord, err) in
            guard let currentRecord = currentRecord , err == nil else {
                onCompletion(nil, err as! NSError)
                return;
            }
            
            currentRecord["deleted"] = true as CKRecordValue
            
            db.save(currentRecord, completionHandler: { (record, saveError) in
                
                guard let record = record , saveError == nil else {
                    onCompletion(nil, saveError as! NSError)
                    return;
                }
                
                guard let sourceCode = record["sourceCode"] as? String, let name = record["name"] as? String, let extensionTypeInt = record["extensionType"] as? UInt else { return }
                let extensionType = SRExtensionType(rawValue: extensionTypeInt)
                let keyboardShortcut = record["keyboardShortcut"] as? String
                
                let updatedCodeExtension = SRExtension(sourceCode: sourceCode, externalId: record.recordID.recordName, name: name, extensionType: extensionType, draftSourceCode: nil, keyboardShortcut: keyboardShortcut, updatedAt: record.modificationDate ?? record.creationDate!)
                
                onCompletion(updatedCodeExtension, nil)
            })
            
        })
    }
    
    
}
