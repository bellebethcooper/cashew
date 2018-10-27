//
//  QBaseStore.h
//  Issues
//
//  Created by Hicham Bouabdallah on 1/19/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FMDB/FMDB.h>

typedef NS_ENUM(NSInteger, QBaseDatabaseOperation)
{
    QBaseDatabaseOperation_Unknown = 0,
    QBaseDatabaseOperation_Insert = 1,
    QBaseDatabaseOperation_Update = 2,
    QBaseDatabaseOperation_Delete = 3
};

typedef void(^QBaseStoreCompletion)(id obj, NSError *err);

@class QBaseStore;

@protocol QStoreObserver <NSObject>

- (void)store:(Class)store didInsertRecord:(id)record;
- (void)store:(Class)store didUpdateRecord:(id)record;
- (void)store:(Class)store didRemoveRecord:(id)record;

@end

@interface QBaseStore : NSObject

+ (void)doWriteInTransaction:(void (^)(FMDatabase *db, BOOL *rollback))block;
+ (void)doReadInTransaction:(void (^)(FMDatabase *db))block;
+ (void)dbDispatchAsync:(dispatch_block_t)block;
+ (void)addObserver:(id<QStoreObserver>)observer;
+ (void)remove:(id<QStoreObserver>)observer;
+ (NSArray<QStoreObserver> *)allObservers;
//+ (void)reset;
+ (void)notifyInsertObserversForStore:(Class)store record:(id)record;
+ (void)notifyUpdateObserversForStore:(Class)store record:(id)record;
+ (void)notifyDeletionObserversForStore:(Class)store record:(id)record;

+ (void)setupDatabaseQueues;

@end
