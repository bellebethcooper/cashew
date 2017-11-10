//
//  SRExtensionStore.m
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/1/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

#import "SRExtensionStore.h"
#import "Cashew-Swift.h"

@implementation SRExtensionStore


+ (void)saveExtension:(SRExtension *)extension;
{
    NSParameterAssert(extension);
    
    __block QBaseDatabaseOperation dbOperation = QBaseDatabaseOperation_Unknown;
    [SRExtensionStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT updated_at FROM extensions WHERE external_id = ?", extension.externalId];
        
        if ([rs next]) {
            NSDate *updatedAt = [rs dateForColumn:@"updated_at"];
            [rs close];
            
            if (updatedAt && [extension.updatedAt compare:updatedAt] != NSOrderedDescending) {
                return;
            }
            
            dbOperation = QBaseDatabaseOperation_Update;
            BOOL success = [db executeUpdate:@"UPDATE extensions SET source_code = ?, name = ?, draft_source_code = ?, keyboard_shortcut = ?, updated_at = ? WHERE external_id = ?", extension.sourceCode, extension.name, extension.draftSourceCode ?: NSNull.null, extension.keyboardShortcut ?: NSNull.null, extension.updatedAt, extension.externalId];
            NSParameterAssert(success);
            return;
        }
        
        dbOperation = QBaseDatabaseOperation_Insert;
        BOOL success = [db executeUpdate:@"INSERT INTO extensions ( source_code, external_id, name, draft_source_code, keyboard_shortcut, updated_at, extension_type) VALUES (?, ?, ?, ?, ?, ?, ?)", extension.sourceCode, extension.externalId, extension.name, extension.draftSourceCode ?: NSNull.null, extension.keyboardShortcut ?: NSNull.null, extension.updatedAt, @(extension.extensionType)];
        NSParameterAssert(success);
        
    }];
    
    if (dbOperation == QBaseDatabaseOperation_Insert) {
        [SRExtensionStore notifyInsertObserversForStore:SRExtensionStore.class record:extension];
    } else if (dbOperation == QBaseDatabaseOperation_Update) {
        [SRExtensionStore notifyUpdateObserversForStore:SRExtensionStore.class record:extension];
    }
    
}

+ (void)deleteExtension:(SRExtension *)extension;
{
    __block BOOL didDelete = false;
    [SRExtensionStore doWriteInTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT updated_at FROM extensions WHERE external_id = ?", extension.externalId];
        
        if ([rs next]) {
            NSDate *updatedAt = [rs dateForColumn:@"updated_at"];
            [rs close];
            
            if ([extension.updatedAt compare:updatedAt] != NSOrderedDescending && [extension.updatedAt compare:updatedAt] != NSOrderedSame) {
                return;
            }
            
        }
        didDelete = true;
        BOOL success = [db executeUpdate:@"DELETE FROM extensions WHERE external_id = ?", extension.externalId];
        NSParameterAssert(success);
        return;
    }];
    
    if (didDelete) {
        [SRExtensionStore notifyDeletionObserversForStore:SRExtensionStore.class record:extension];
    }
}

+ (NSArray<SRExtension *> *)extensionsForType:(SRExtensionType)extensionType;
{
    NSMutableArray<SRExtension *> *extensions = [NSMutableArray new];
    
    [SRExtensionStore doReadInTransaction:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM extensions WHERE extension_type = ? ORDER BY name COLLATE NOCASE ASC", @(extensionType)];
        
        while ([rs next]) {
            SRExtension *extension = [[SRExtension alloc] initWithSourceCode:[rs stringForColumn:@"source_code"]
                                                                  externalId:[rs stringForColumn:@"external_id"]
                                                                        name:[rs stringForColumn:@"name"]
                                                               extensionType:(SRExtensionType)[rs intForColumn:@"extension_type"]
                                                             draftSourceCode:[rs stringForColumn:@"draft_source_code"]
                                                            keyboardShortcut:[rs stringForColumn:@"keyboard_shortcut"]
                                                                   updatedAt:[rs dateForColumn:@"updated_at"]];
            
            [extensions addObject:extension];
        }
        
        [rs close];
    }];
    
    return extensions;
}

+ (SRExtension *)extensionForName:(NSString *)extensionName extensionType:(SRExtensionType)extensionType;
{
    NSParameterAssert(extensionName);
    
    __block SRExtension *extension = nil;
    
    [SRExtensionStore doReadInTransaction:^(FMDatabase *db) {
        
        FMResultSet *rs = [db executeQuery:@"SELECT * FROM extensions WHERE extension_type = ? AND name = ? COLLATE NOCASE", @(extensionType), extensionName];
        
        while ([rs next]) {
            extension = [[SRExtension alloc] initWithSourceCode:[rs stringForColumn:@"source_code"]
                                                                  externalId:[rs stringForColumn:@"external_id"]
                                                                        name:[rs stringForColumn:@"name"]
                                                               extensionType:(SRExtensionType)[rs intForColumn:@"extension_type"]
                                                             draftSourceCode:[rs stringForColumn:@"draft_source_code"]
                                                            keyboardShortcut:[rs stringForColumn:@"keyboard_shortcut"]
                                                                   updatedAt:[rs dateForColumn:@"updated_at"]];
            
        }
        
        [rs close];
    }];
    
    return extension;
}

@end
