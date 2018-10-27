//
//  QBaseStore.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/19/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QBaseStore.h"
#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"
#import "Cashew-Swift.h"
#import <sqlite3.h>

@interface QBaseStoreFMDatabasePoolDelegate: NSObject

@end

@implementation QBaseStoreFMDatabasePoolDelegate
- (BOOL)databasePool:(FMDatabasePool*)pool shouldAddDatabaseToPool:(FMDatabase*)database;
{
    return YES;
}

- (void)databasePool:(FMDatabasePool *)pool didAddDatabase:(FMDatabase *)database;
{
    [database executeStatements:@"PRAGMA journal_mode=WAL"];
}

@end

@interface QBaseStore ()

@end

@implementation QBaseStore


//+ (dispatch_queue_t)_observersSerialQueue
//{
//    static dispatch_once_t onceToken;
//    static NSMutableDictionary *hashTables;
//    dispatch_once(&onceToken, ^{
//        hashTables = [[NSMutableDictionary alloc] init];
//    });
//    
//    dispatch_queue_t queue;
//    NSString *key = NSStringFromClass([self class]);
//    queue = hashTables[key];
//    if (!queue) {
//        @synchronized(hashTables) {
//            NSString *serialQueueName = [NSString stringWithFormat:@"com.simplerocket.baseStore.observersSerialQueue.%@", key];
//            queue = dispatch_queue_create([serialQueueName cStringUsingEncoding:NSUTF8StringEncoding], DISPATCH_QUEUE_SERIAL);
//            hashTables[key] = queue;
//        }
//    }
//    
//    return queue;
//}

+ (NSHashTable *)_observers
{
    static dispatch_once_t onceToken;
    static NSMutableDictionary *hashTables;
    dispatch_once(&onceToken, ^{
        hashTables = [[NSMutableDictionary alloc] init];
    });
    
    NSHashTable *hashTable;
    NSString *key = NSStringFromClass([self class]);
    hashTable = hashTables[key];
    if (!hashTable) {
        @synchronized(hashTables) {
            hashTable = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory capacity:10000];
            hashTables[key] = hashTable;
        }
    }
    
    return hashTable;
}

#pragma mark - Observers
+ (NSArray<QStoreObserver> *)allObservers;
{
    __block NSArray<QStoreObserver> *observers = nil;
    
//    dispatch_sync([[self class] _observersSerialQueue], ^{
//        
//    });
//    
    dispatch_block_t block = ^{
        observers = (NSArray<QStoreObserver> *)[[[self class] _observers] allObjects];
    };
    
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
    
    return observers;
}

+ (void)addObserver:(id<QStoreObserver>)observer;
{
//    dispatch_sync([[self class] _observersSerialQueue], ^{
//        
//    });
    
    dispatch_block_t block = ^{
        [[[self class] _observers] addObject:observer];
    };
    
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

+ (void)remove:(id<QStoreObserver>)observer;
{
//    dispatch_sync([[self class] _observersSerialQueue], ^{
//        [[[self class] _observers] removeObject:observer];
//    });
    
    dispatch_block_t block = ^{
        [[[self class] _observers] removeObject:observer];
    };
    
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

+ (void)notifyInsertObserversForStore:(Class)store record:(id)record
{
    NSArray *observers = [[self class] allObservers];
    [observers enumerateObjectsUsingBlock:^(id<QStoreObserver>  _Nonnull observer, NSUInteger idx, BOOL * _Nonnull stop) {
        [observer store:store didInsertRecord:record];
    }];
}

+ (void)notifyUpdateObserversForStore:(Class)store record:(id)record
{
    NSArray *observers = [[self class] allObservers];
    [observers enumerateObjectsUsingBlock:^(id<QStoreObserver>  _Nonnull observer, NSUInteger idx, BOOL * _Nonnull stop) {
        [observer store:store didUpdateRecord:record];
    }];
}


+ (void)notifyDeletionObserversForStore:(Class)store record:(id)record
{
    NSArray *observers = [[self class] allObservers];
    [observers enumerateObjectsUsingBlock:^(id<QStoreObserver>  _Nonnull observer, NSUInteger idx, BOOL * _Nonnull stop) {
        [observer store:store didRemoveRecord:record];
    }];
}


#pragma -
+ (void)dbDispatchAsync:(dispatch_block_t)block;
{
    static dispatch_once_t onceToken;
    static dispatch_queue_t queue;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.simplerocket.issues.baseStoreConcurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    });
    
    dispatch_async(queue, block);
}


#pragma mark - Database

void traceFunc(void *uData, const char *statement) {
    DDLogDebug(@"%s", statement);
}

+ (void)doReadInTransaction:(void (^)(FMDatabase *db))block;
{
    FMDatabasePool *db = [QBaseStore _sharedReadDatabasePool];
    [db inDatabase:^(FMDatabase *db) {
        //sqlite3_trace([db sqliteHandle], traceFunc, NULL);
        //DDLogDebug(@"executing..... %@", NSDate.new);
        // NSParameterAssert(![NSThread mainThread]);
        // FIXME: hicham - make sure all DB access goes to background - NSParameterAssert(![NSThread mainThread]);
        
//        BOOL didRollBack = *rollback;
//        if (didRollBack) {
//            
//        }
        //sqlite3_trace([db sqliteHandle], traceFunc, NULL);
        //NSParameterAssert(!didRollBack);
        block(db);
        
        if ([db hasOpenResultSets]) {
            [db closeOpenResultSets];
        }
        
        NSParameterAssert(![db hasOpenResultSets]);
    }];
}

+ (void)doWriteInTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block;
{
    FMDatabaseQueue *db = [QBaseStore _sharedWriteDatabaseQueue];
    [db inTransaction:^(FMDatabase *db, BOOL *rollback) {
       //sqlite3_trace([db sqliteHandle], traceFunc, NULL);
        //DDLogDebug(@"executing..... %@", NSDate.new);
        // NSParameterAssert(![NSThread mainThread]);
        // FIXME: hicham - make sure all DB access goes to background - NSParameterAssert(![NSThread mainThread]);
        
        BOOL didRollBack = *rollback;
        if (didRollBack) {
            sqlite3_trace([db sqliteHandle], traceFunc, NULL);
        }
        NSParameterAssert(!didRollBack);
        block(db, rollback);
        
        if ([db hasOpenResultSets]) {
            [db closeOpenResultSets];
        }
        
        NSParameterAssert(![db hasOpenResultSets]);
    }];
}

static dispatch_once_t writeDbOnceToken;
static FMDatabaseQueue *writeDatabasePool;

static dispatch_once_t readDbOnceToken;
static QBaseStoreFMDatabasePoolDelegate *poolDelegate;
static FMDatabasePool *readDatabasePool;

//+ (void)reset
//{
//    NSURL *dbDirURL = [self _dbDirURL];
//    onceToken = 0;
//    db = nil;
//    NSError *err;
//    [[NSFileManager defaultManager] removeItemAtPath:dbDirURL.path error:&err];
//    NSParameterAssert(!err);
//}

+ (NSURL *)_dbDirURL
{
    AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
    NSURL *dbDirURL = [[appDelegate applicationDocumentsDirectory] URLByAppendingPathComponent:@"database"];
    return  dbDirURL;
}

+ (void)setupDatabaseQueues;
{
    [QBaseStore _sharedWriteDatabaseQueue];
    [QBaseStore _sharedReadDatabasePool];
}

+ (FMDatabasePool *)_sharedReadDatabasePool
{
    dispatch_once(&readDbOnceToken, ^{
        readDatabasePool = [FMDatabasePool databasePoolWithPath:[[self _dbURL] absoluteString]];
        poolDelegate = [[QBaseStoreFMDatabasePoolDelegate alloc] init];
        readDatabasePool.delegate = poolDelegate;
        readDatabasePool.maximumNumberOfDatabasesToCreate = 30;
    });
    
    return readDatabasePool;
}

+ (NSURL *)_dbURL
{
    NSURL *dbDirURL = [self _dbDirURL];
    
    if (![NSFileManager.defaultManager fileExistsAtPath:dbDirURL.path]) {
        NSError *err;
        [NSFileManager.defaultManager createDirectoryAtURL:dbDirURL withIntermediateDirectories:YES attributes:nil error:&err];
        NSParameterAssert(!err);
    }
    
    NSURL *dbURL = [dbDirURL URLByAppendingPathComponent:@"issues.db"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dbURL.path]) {
        NSURL *vanillaDatabaseURL = [[NSBundle mainBundle] URLForResource:@"vanilla_database" withExtension:@"db"];
        NSError *err = nil;
        [[NSFileManager defaultManager] copyItemAtURL:vanillaDatabaseURL toURL:dbURL error:&err];
        NSParameterAssert(!err);
    }
    
    DDLogDebug(@"Database path: %@", dbURL);
    return dbURL;
}

+ (FMDatabaseQueue *)_sharedWriteDatabaseQueue
{
    dispatch_once(&writeDbOnceToken, ^{
        
        NSURL *dbURL = [self _dbURL];
        writeDatabasePool = [FMDatabaseQueue databaseQueueWithPath:[dbURL absoluteString]];
        
        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            [db executeStatements:@"PRAGMA journal_mode=WAL"];
        }];
        
        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            FMResultSet *rs4 = [db executeQuery:@"SELECT * FROM app_settings WHERE  settings_name = 'db.schema.version' AND CAST(settings_value as decimal) >= 4"];
            if (![rs4 next]) {
                [rs4 close];
                [db executeUpdate:@"ALTER TABLE label ADD COLUMN deleted integer NOT NULL DEFAULT(0)"];
                [db executeUpdate:@"CREATE INDEX IF NOT EXISTS label_deleted_index ON label (deleted ASC)"];
                
                [db executeUpdate:@"ALTER TABLE milestone ADD COLUMN deleted integer NOT NULL DEFAULT(0)"];
                [db executeUpdate:@"CREATE INDEX IF NOT EXISTS milestone_deleted_index ON milestone (deleted ASC)"];
                
                [db executeUpdate:@"UPDATE app_settings SET settings_value = '4' WHERE settings_name = 'db.schema.version'"];

            } else {
                [rs4 close];
            }
        }];
        
        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            FMResultSet *rs5 = [db executeQuery:@"SELECT * FROM app_settings WHERE  settings_name = 'db.schema.version' AND CAST(settings_value as decimal) >= 5"];
            if (![rs5 next]) {
                [rs5 close];
                [db executeUpdate:@"ALTER TABLE owner ADD COLUMN html_url varchar"];
                [db executeUpdate:@"UPDATE app_settings SET settings_value = '5' WHERE settings_name = 'db.schema.version'"];
            } else {
                [rs5 close];
            }
        }];
        
        
        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            FMResultSet *rs5 = [db executeQuery:@"SELECT * FROM app_settings WHERE  settings_name = 'db.schema.version' AND CAST(settings_value as decimal) >= 6"];
            if (![rs5 next]) {
                [rs5 close];
                [db executeUpdate:@"ALTER TABLE repository ADD COLUMN delta_sync_date timestamp"];
                [db executeUpdate:@"UPDATE app_settings SET settings_value = '6' WHERE settings_name = 'db.schema.version'"];
            } else {
                [rs5 close];
            }
        }];
        
        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM app_settings WHERE  settings_name = 'db.schema.version' AND CAST(settings_value as decimal) >= 7"];
            if (![rs next]) {
                [rs close];
                [db executeUpdate:@"DROP INDEX repository_assingee_unique_indx"];
                [db executeUpdate:@"CREATE UNIQUE INDEX IF NOT EXISTS repository_assingee_unique_indx ON repository_assignee (repository_id, owner_id, account_id)"];
                [db executeUpdate:@"UPDATE app_settings SET settings_value = '7' WHERE settings_name = 'db.schema.version'"];
            } else {
                [rs close];
            }
        }];
        
        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM app_settings WHERE  settings_name = 'db.schema.version' AND CAST(settings_value as decimal) >= 8"];
            if (![rs next]) {
                [rs close];
        
                [db executeUpdate:@"CREATE TABLE IF NOT EXISTS issue_comment_draft ( account_id integer NOT NULL, repository_id char NOT NULL, issue_comment_id integer, issue_number integer NOT NULL, body text NOT NULL, type integer NOT NULL )"];
                [db executeUpdate:@"CREATE UNIQUE INDEX IF NOT EXISTS issue_comment_draft_uniq_indx ON issue_comment_draft (account_id ASC, repository_id ASC, issue_comment_id ASC, issue_number ASC)"];
                [db executeUpdate:@"UPDATE app_settings SET settings_value = '8' WHERE settings_name = 'db.schema.version'"];
            } else {
                [rs close];
            }
        }];
        
        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM app_settings WHERE  settings_name = 'db.schema.version' AND CAST(settings_value as decimal) >= 9"];
            if (![rs next]) {
                [rs close];
                
                [db executeUpdate:@"CREATE TABLE IF NOT EXISTS issue_notification ( account_id integer NOT NULL, repository_id integer NOT NULL, issue_number integer NOT NULL, thread_id integer NOT NULL, reason text NOT NULL, read integer NOT NULL DEFAULT(0), updated_at timestamp NOT NULL, search_uniq_key varchar NOT NULL )"];
                [db executeUpdate:@"CREATE UNIQUE INDEX IF NOT EXISTS issue_notification_thread_indx ON issue_notification (account_id ASC, repository_id ASC, thread_id ASC)"];
                [db executeUpdate:@"CREATE UNIQUE INDEX IF NOT EXISTS issue_notification_search_uniq_key_indx ON issue_notification (search_uniq_key ASC)"];
                [db executeUpdate:@"CREATE UNIQUE INDEX IF NOT EXISTS issue_notification_uniq_indx ON issue_notification (account_id ASC, repository_id ASC, issue_number ASC)"];
                [db executeUpdate:@"UPDATE app_settings SET settings_value = '9' WHERE settings_name = 'db.schema.version'"];
            } else {
                [rs close];
            }
        }];
        
        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM app_settings WHERE  settings_name = 'db.schema.version' AND CAST(settings_value as decimal) >= 10"];
            if (![rs next]) {
                [rs close];
                [db executeUpdate:@"CREATE UNIQUE INDEX IF NOT EXISTS issue_number_uniq_indx ON issue (account_id ASC, repository_id ASC, number ASC)"];
                [db executeUpdate:@"UPDATE app_settings SET settings_value = '10' WHERE settings_name = 'db.schema.version'"];
            } else {
                [rs close];
            }
        }];
        
        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM app_settings WHERE  settings_name = 'db.schema.version' AND CAST(settings_value as decimal) >= 11"];
            if (![rs next]) {
                [rs close];
                [db executeUpdate:@"ALTER TABLE account ADD COLUMN notification_modified_on timestamp"];
                [db executeUpdate:@"UPDATE app_settings SET settings_value = '11' WHERE settings_name = 'db.schema.version'"];
            } else {
                [rs close];
            }
        }];
        
        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM app_settings WHERE  settings_name = 'db.schema.version' AND CAST(settings_value as decimal) >= 12"];
            if (![rs next]) {
                [rs close];
                
                [db executeUpdate:@"CREATE TABLE IF NOT EXISTS issue_favorite ( account_id integer NOT NULL, repository_id integer NOT NULL, issue_number integer NOT NULL)"];
                [db executeUpdate:@"CREATE UNIQUE INDEX IF NOT EXISTS issue_favorite_number_uniq_indx ON issue_favorite (account_id ASC, repository_id ASC, issue_number ASC)"];
                [db executeUpdate:@"UPDATE app_settings SET settings_value = '12' WHERE settings_name = 'db.schema.version'"];
            } else {
                [rs close];
            }
        }];
        
        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM app_settings WHERE  settings_name = 'db.schema.version' AND CAST(settings_value as decimal) >= 13"];
            if (![rs next]) {
                [rs close];
                [db executeUpdate:@"ALTER TABLE issue_favorite ADD COLUMN search_uniq_key varchar"];
                [db executeUpdate:@"CREATE UNIQUE INDEX IF NOT EXISTS issue_favorite_search_uniq_key_indx ON issue_favorite (search_uniq_key ASC)"];
                [db executeUpdate:@"UPDATE app_settings SET settings_value = '13' WHERE settings_name = 'db.schema.version'"];
            } else {
                [rs close];
            }
        }];
        
        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM app_settings WHERE  settings_name = 'db.schema.version' AND CAST(settings_value as decimal) >= 14"];
            if (![rs next]) {
                [rs close];
                [db executeUpdate:@"ALTER TABLE issue ADD COLUMN labels text"];
                [db executeUpdate:@"UPDATE app_settings SET settings_value = '14' WHERE settings_name = 'db.schema.version'"];
            } else {
                [rs close];
            }
        }];
        
        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM app_settings WHERE  settings_name = 'db.schema.version' AND CAST(settings_value as decimal) >= 15"];
            if (![rs next]) {
                [rs close];
                [db executeUpdate:@"ALTER TABLE issue_comment ADD COLUMN html_url varchar"];
                [db executeUpdate:@"UPDATE app_settings SET settings_value = '15' WHERE settings_name = 'db.schema.version'"];
            } else {
                [rs close];
            }
        }];
        
        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM app_settings WHERE  settings_name = 'db.schema.version' AND CAST(settings_value as decimal) >= 16"];
            if (![rs next]) {
                [rs close];
                [db executeUpdate:@"ALTER TABLE issue ADD COLUMN html_url varchar"];
                [db executeUpdate:@"UPDATE app_settings SET settings_value = '16' WHERE settings_name = 'db.schema.version'"];
            } else {
                [rs close];
            }
        }];
        
        
        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM app_settings WHERE  settings_name = 'db.schema.version' AND CAST(settings_value as decimal) >= 17"];
            if (![rs next]) {
                [rs close];
                [db executeUpdate:@"CREATE TABLE IF NOT EXISTS extensions ( source_code text PRIMARY KEY NOT NULL, external_id varchar NOT NULL, name varchar NOT NULL, draft_source_code text, keyboard_shortcut varchar, extension_type integer )"];
                [db executeUpdate:@"CREATE UNIQUE INDEX IF NOT EXISTS NewIndex1 ON extensions (name ASC, extension_type ASC)"];
                [db executeUpdate:@"CREATE UNIQUE INDEX IF NOT EXISTS NewIndex0 ON extensions (external_id ASC)"];
                [db executeUpdate:@"UPDATE app_settings SET settings_value = '17' WHERE settings_name = 'db.schema.version'"];
            } else {
                [rs close];
            }
        }];
        
        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM app_settings WHERE  settings_name = 'db.schema.version' AND CAST(settings_value as decimal) >= 18"];
            if (![rs next]) {
                [rs close];
                [db executeUpdate:@"ALTER TABLE extensions ADD COLUMN updated_at timestamp"];
                [db executeUpdate:@"UPDATE app_settings SET settings_value = '18' WHERE settings_name = 'db.schema.version'"];
            } else {
                [rs close];
            }
        }];
        

        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM app_settings WHERE  settings_name = 'db.schema.version' AND CAST(settings_value as decimal) >= 19"];
            if (![rs next]) {
                [rs close];
                
                [db executeUpdate:@"CREATE TABLE IF NOT EXISTS issue_comment_reaction ( identifier integer NOT NULL, user_id integer NOT NULL, repository_id integer NOT NULL, account_id integer NOT NULL, content varchar NOT NULL, created_at timestamp NOT NULL, issue_comment_id integer NOT NULL)"];
                [db executeUpdate:@"CREATE UNIQUE INDEX IF NOT EXISTS issue_comment_reaction_identifer_uniq_idx ON issue_comment_reaction (identifier ASC)"];
                [db executeUpdate:@"CREATE INDEX IF NOT EXISTS issue_comment_reaction_issue_idx ON issue_comment_reaction (issue_comment_id, repository_id, account_id)"];
                
                [db executeUpdate:@"CREATE TABLE IF NOT EXISTS issue_reaction ( identifier integer NOT NULL, user_id integer NOT NULL, repository_id integer NOT NULL, account_id integer NOT NULL, content varchar NOT NULL, created_at timestamp NOT NULL, issue_number integer NOT NULL)"];
                [db executeUpdate:@"CREATE INDEX IF NOT EXISTS issue_reaction_issue_idx ON issue_reaction (issue_number, repository_id, account_id)"];
                [db executeUpdate:@"CREATE UNIQUE INDEX IF NOT EXISTS issue_reaction_identifer_uniq_idx ON issue_reaction (identifier ASC)"];
                [db executeUpdate:@"UPDATE app_settings SET settings_value = '19' WHERE settings_name = 'db.schema.version'"];
            } else {
                [rs close];
            }
        }];
        
        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM app_settings WHERE  settings_name = 'db.schema.version' AND CAST(settings_value as decimal) >= 20"];
            if (![rs next]) {
                [rs close];

                [db executeUpdate:@"CREATE UNIQUE INDEX IF NOT EXISTS issue_reaction_unique_user_indx ON issue_reaction (user_id, repository_id, account_id, content, issue_number)"];
                [db executeUpdate:@"CREATE UNIQUE INDEX IF NOT EXISTS issue_comment_reaction_unique_user_indx ON issue_comment_reaction (user_id, repository_id, account_id, content, issue_comment_id)"];
                [db executeUpdate:@"UPDATE app_settings SET settings_value = '20' WHERE settings_name = 'db.schema.version'"];
            } else {
                [rs close];
            }
        }];
        
        
        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM app_settings WHERE  settings_name = 'db.schema.version' AND CAST(settings_value as decimal) >= 21"];
            if (![rs next]) {
                [rs close];
                [db executeUpdate:@"ALTER TABLE issue ADD COLUMN thumbsup_count integer NOT NULL DEFAULT(0)"];
                [db executeUpdate:@"ALTER TABLE issue ADD COLUMN thumbsdown_count integer NOT NULL DEFAULT(0)"];
                [db executeUpdate:@"ALTER TABLE issue ADD COLUMN laugh_count integer NOT NULL DEFAULT(0)"];
                [db executeUpdate:@"ALTER TABLE issue ADD COLUMN hooray_count integer NOT NULL DEFAULT(0)"];
                [db executeUpdate:@"ALTER TABLE issue ADD COLUMN confused_count integer NOT NULL DEFAULT(0)"];
                [db executeUpdate:@"ALTER TABLE issue ADD COLUMN heart_count integer NOT NULL DEFAULT(0)"];
                
                [db executeUpdate:@"ALTER TABLE issue_comment ADD COLUMN thumbsup_count integer NOT NULL DEFAULT(0)"];
                [db executeUpdate:@"ALTER TABLE issue_comment ADD COLUMN thumbsdown_count integer NOT NULL DEFAULT(0)"];
                [db executeUpdate:@"ALTER TABLE issue_comment ADD COLUMN laugh_count integer NOT NULL DEFAULT(0)"];
                [db executeUpdate:@"ALTER TABLE issue_comment ADD COLUMN hooray_count integer NOT NULL DEFAULT(0)"];
                [db executeUpdate:@"ALTER TABLE issue_comment ADD COLUMN confused_count integer NOT NULL DEFAULT(0)"];
                [db executeUpdate:@"ALTER TABLE issue_comment ADD COLUMN heart_count integer NOT NULL DEFAULT(0)"];
                
                [db executeUpdate:@"UPDATE app_settings SET settings_value = '21' WHERE settings_name = 'db.schema.version'"];
            } else {
                [rs close];
            }
        }];
        
        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM app_settings WHERE  settings_name = 'db.schema.version' AND CAST(settings_value as decimal) >= 22"];
            if (![rs next]) {
                [rs close];
                [db executeUpdate:@"ALTER TABLE repository ADD COLUMN external_id varchar"];
                [db executeUpdate:@"ALTER TABLE repository ADD COLUMN updated_at timestamp"];
                
                [db executeUpdate:@"ALTER TABLE user_search_query ADD COLUMN external_id varchar"];
                [db executeUpdate:@"ALTER TABLE user_search_query ADD COLUMN updated_at timestamp"];
    
                [db executeUpdate:@"UPDATE app_settings SET settings_value = '22' WHERE settings_name = 'db.schema.version'"];
            } else {
                [rs close];
            }
        }];
        
        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT * FROM app_settings WHERE  settings_name = 'db.schema.version' AND CAST(settings_value as decimal) >= 23"];
            if (![rs next]) {
                [rs close];
                [db executeUpdate:@"ALTER TABLE issue ADD COLUMN issue_type varchar"];                
                [db executeUpdate:@"UPDATE app_settings SET settings_value = '23' WHERE settings_name = 'db.schema.version'"];
            } else {
                [rs close];
            }
        }];
        
        
        __block NSNumber *currentVersion = nil;
        [writeDatabasePool inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT settings_value FROM app_settings WHERE settings_name = 'db.schema.version'  AND CAST(settings_value as decimal) <= 23"];
            if ([rs next]) {
                currentVersion = @([rs intForColumn:@"settings_value"]);
                [rs close];
            }
        }];
        
        if (currentVersion && currentVersion.intValue != 23) {
            [writeDatabasePool close];
            
            NSError *removalError = nil;
            [[NSFileManager defaultManager] removeItemAtURL:dbURL error:&removalError];
            [SRAnalytics logCustomEventWithName:@"Fixing corrupted database" customAttributes:@{@"db_version": [NSString stringWithFormat:@"%@", currentVersion]}];
            if (removalError) {
                [SRAnalytics logCustomEventWithName:@"Unable to delete corrupted database" customAttributes:@{@"db_version": [NSString stringWithFormat:@"%@", currentVersion]}];
                [NSException raise:@"Invalid database version" format:@"currentVersion = %@", currentVersion];
            }
            
            NSURL *vanillaDatabaseURL = [[NSBundle mainBundle] URLForResource:@"vanilla_database" withExtension:@"db"];
            NSError *err = nil;
            [[NSFileManager defaultManager] copyItemAtURL:vanillaDatabaseURL toURL:dbURL error:&err];
            NSParameterAssert(!err);
            
            writeDatabasePool = [FMDatabaseQueue databaseQueueWithPath:[dbURL absoluteString]]; //[FMDatabase databaseWithPath:[dbURL absoluteString]];
        }
        
        
        // FIXME: hicham - turn on foreign keys
        //        [db inDatabase:^(FMDatabase *db) {
        //            BOOL success = [db executeUpdate:@"PRAGMA foreign_keys = YES"];
        //            NSParameterAssert(success);
        //        }];
        
        
        
    });
    
    return writeDatabasePool;
}


@end
