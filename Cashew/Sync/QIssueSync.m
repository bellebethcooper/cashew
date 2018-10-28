//
//  QIssueSync.m
//  Issues
//
//  Created by Hicham Bouabdallah on 1/12/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QIssueSync.h"
#import "QAccountStore.h"
#import "QIssueStore.h"
#import "QIssueCommentStore.h"
#import "QIssueEVENTStore.h"
#import "QIssuesService.h"
#import "QThrottler.h"
#import "QRepositoryStore.h"
#import "Cashew-Swift.h"
#import "SRNotificationService.h"
#import "QIssueNotificationStore.h"

typedef NS_ENUM(NSInteger, SRIssueSyncherType)
{
    SRIssueSyncherTypeFull = 0,
    SRIssueSyncherTypeDelta = 1,
    SRIssueSyncherTypeManual = 2
};

typedef void(^SRFetcherCompletion)(NSError *err);
typedef void(^_QIssueSyncOnIssueSaveCompletion)(QIssue *issue);

@interface QIssueSync () <QStoreObserver>
@property (nonatomic) BOOL stopSyncher;
@end

@interface QIssueSync ()

@property (nonatomic, strong) NSOperationQueue *repositorySyncherOperationQueue;
@property (nonatomic, strong) dispatch_queue_t eventsAndCommentSyncherFetchQueue;
@property (nonatomic, strong) dispatch_queue_t refreshEventsAndCommentFetchQueue;

@property (nonatomic, strong) dispatch_queue_t repositoryAccessQueue;
@property (nonatomic, strong) NSMutableSet<QRepository *> *repositorySet;
// @property (nonatomic, strong) NSCache *repositorySerialQueues;

@end

@implementation QIssueSync {
    // QThrottler *_throttler;
}

//- (void)dealloc
//{
//    [QAccountStore remove:self];
//    [QRepositoryStore remove:self];
//}

+ (instancetype)sharedIssueSync;
{
    static dispatch_once_t onceToken;
    static QIssueSync *sync;
    dispatch_once(&onceToken, ^{
        (void)[SRIssueSyncWatcher sharedWatcher]; // start watcher
        
        sync = [[QIssueSync alloc] init];
        //        sync->_repositorySerialQueues = [NSCache new];
        //        [sync->_repositorySerialQueues setCountLimit:10000];
        sync.eventsAndCommentSyncherFetchQueue = dispatch_queue_create("co.hellocode.issueSync.eventsAndCommentsFetchQueue", DISPATCH_QUEUE_CONCURRENT);
        sync.refreshEventsAndCommentFetchQueue = dispatch_queue_create("co.hellocode.cashew.refreshEventsAndCommentFetchQueue", DISPATCH_QUEUE_CONCURRENT);
        
        sync.repositorySyncherOperationQueue = [NSOperationQueue new];
        sync.repositorySyncherOperationQueue.maxConcurrentOperationCount = 3;
        sync.repositorySyncherOperationQueue.name = @"co.cashewapp.QIssueSync.repositorySyncer";
        
        sync.repositorySet = [NSMutableSet new];
        sync.repositoryAccessQueue = dispatch_queue_create("co.hellocode.cashew.sync.repositoryAccessQueue", DISPATCH_QUEUE_CONCURRENT);
        
//        [QRepositoryStore addObserver:sync];
//        [QAccountStore addObserver:sync];
    });
    
    return sync;
}

//- (NSOperationQueue *)_serialOperationQueueForRepository:(QRepository *)repo deltaSyncher:(BOOL)deltaSyncher
//{
//    NSString *queueName = [NSString stringWithFormat:@"com.simplerocket.issueSync.serialQueue.%@.%@[%@].%@[%@]", (deltaSyncher?@"delta":@"full"), repo.account.username, repo.account.identifier, repo.name, repo.identifier];
//    NSOperationQueue  *queue = [self.repositorySerialQueues objectForKey:queueName];
//    if (!queue) {
//        queue = [NSOperationQueue new]; //dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);
//        [queue setMaxConcurrentOperationCount:1];
//        [queue setName:queueName];
//        [self.repositorySerialQueues setObject:queue forKey:queueName];
//    }
//    return queue;
//}

- (BOOL)_isSynchableRepository:(QRepository *)repo
{
    if (self.stopSyncher) {
        return NO;
    }
    
    __block BOOL sync = NO;
    dispatch_sync(self.repositoryAccessQueue, ^{
        sync = [self.repositorySet containsObject:repo];
    });
    
    return sync;
}

- (void)stop
{
    self.stopSyncher = YES;
}

- (void)start {
    DDLogDebug(@"QIssueSync start");
    self.stopSyncher = NO;
    
    NSArray<QAccount *> *accounts = [QAccountStore accounts];
    
    [accounts enumerateObjectsUsingBlock:^(QAccount * _Nonnull account, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSArray<QRepository *> *repos = [QRepositoryStore repositoriesForAccountId:account.identifier];
        
        dispatch_barrier_sync(self.repositoryAccessQueue, ^{
            [self.repositorySet addObjectsFromArray:repos];
        });
        
        [repos enumerateObjectsUsingBlock:^(QRepository * _Nonnull repository, NSUInteger idx, BOOL * _Nonnull stop) {
            
            [self.repositorySyncherOperationQueue addOperationWithBlock:^{
                NSParameterAssert(![NSThread isMainThread]);
                
                
                if ([[SRIssueSyncWatcher sharedWatcher] isPartiallySynchingRepository:repository]) {
                    DDLogDebug(@"Already running delta syncher for repo -> %@", repository.name);
                    return;
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kWillStartSynchingRepositoryNotification object:repository userInfo:@{@"isFullSync": @NO}];
                   DDLogDebug(@"Starting Sync Issues Job For Repository = [%@]", [repository fullName]);
                
                // fetch milestones
                __block NSError *error = nil;
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                NSMutableSet<QMilestone *> *currentMilestones = [[NSMutableSet alloc] initWithArray:[QMilestoneStore milestonesForAccountId:repository.account.identifier repositoryId:repository.identifier includeHidden:YES]];
                [self _fetchMilestonesForRepository:repository pageNumber:1 pageSize:100 currentMilestones:currentMilestones onCompletion:^(NSError *err) {
                    error = err;
                    dispatch_semaphore_signal(semaphore);
                }];
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                if ([self _isSynchableRepository:repository] && !error) {
                    [currentMilestones enumerateObjectsUsingBlock:^(QMilestone * _Nonnull obj, BOOL * _Nonnull stop) {
                        [QMilestoneStore hideMilestone:obj];
                    }];
                }
                [QMilestoneStore unhideMilestonesNotInMilestoneSet:currentMilestones forAccountId:repository.account.identifier repositoryId:repository.identifier];
                
                // fetch labels
                semaphore = dispatch_semaphore_create(0);
                NSMutableSet<QLabel *> *currentLabels = [[NSMutableSet alloc] initWithArray:[QLabelStore labelsForAccountId:repository.account.identifier repositoryId:repository.identifier includeHidden:YES]];
                 DDLogDebug(@"currentLabel => %@", currentLabels);
                [self _fetchLabelsForRepository:repository pageNumber:1 pageSize:100 currentLabels:currentLabels onCompletion:^(NSError *err) {
                    error = err;
                    dispatch_semaphore_signal(semaphore);
                }];
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                if ([self _isSynchableRepository:repository] && !error) {
                    [currentLabels enumerateObjectsUsingBlock:^(QLabel * _Nonnull obj, BOOL * _Nonnull stop) {
                        [QLabelStore hideLabel:obj];
                    }];
                }
                [QLabelStore unhideLabelsNotInLabelSet:currentLabels accountId:repository.account.identifier repositoryId:repository.identifier];
                
                // fetch assignees
                semaphore = dispatch_semaphore_create(0);
                NSMutableSet<QOwner *> *currentAssignees = [[NSMutableSet alloc] initWithArray:[QOwnerStore ownersForAccountId:repository.account.identifier repositoryId:repository.identifier]];
                [self _fetchAssigneesForRepository:repository pageNumber:1 pageSize:100 currentAssignees:currentAssignees onCompletion:^(NSError *err) {
                    error = err;
                    dispatch_semaphore_signal(semaphore);
                }];
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                if ([self _isSynchableRepository:repository] && !error) {
                    [currentAssignees enumerateObjectsUsingBlock:^(QOwner * _Nonnull obj, BOOL * _Nonnull stop) {
                        [QRepositoryStore deleteAssignee:obj forRepository:repository];
                    }];
                }
                
                // fetch issues
                semaphore = dispatch_semaphore_create(0);
                QIssue *issue = [QIssueStore mostRecentUpdatedIssueForRepository:repository];
                if (!issue) {
                    // // DDLogDebug(@"initial pull did not run. skipping regular syncher for now");
                    [[NSNotificationCenter defaultCenter] postNotificationName:kDidFinishSynchingRepositoryNotification object:repository userInfo:@{@"isFullSync": @NO}];
                    return;
                }
                
                NSDate *deltaSyncDate = repository.deltaSyncDate;
                if (!deltaSyncDate) {
//                     DDLogDebug(@"Delta sync date not setup yet. for repo %@", repository.fullName);
                    [[NSNotificationCenter defaultCenter] postNotificationName:kDidFinishSynchingRepositoryNotification object:repository userInfo:@{@"isFullSync": @NO}];
                    return;
                }
                
                [self _fetchIssuesForRepository:repository pageNumber:1 syncType:SRIssueSyncherTypeDelta identifierSet:nil dateMarker:deltaSyncDate pageSize:100 onIssueSaveCompletion:nil onCompletion:^ (NSError *err){
                    dispatch_semaphore_signal(semaphore);
                }];
                
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kDidFinishSynchingRepositoryNotification object:repository userInfo:@{@"isFullSync": @NO}];
                 DDLogDebug(@"Finishing Sync Issues Job For Repository = [%@]", [repository fullName]);
                
                // make sure all repo data are deleted if repo is not synchable
                __block BOOL deletedRepository = NO;
                dispatch_sync(self.repositoryAccessQueue, ^{
                    deletedRepository = ![self.repositorySet containsObject:repository];
                });
                
                if (deletedRepository) {
                    [QRepositoryStore delete:repository];
                }
                
            }];
            
        }];
    }];
    
}

- (void)runInitialPullSyncher
{
    NSArray<QAccount *> *accounts = [QAccountStore accounts];
    
    [accounts enumerateObjectsUsingBlock:^(QAccount * _Nonnull account, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<QRepository *> *repos = [QRepositoryStore repositoriesForAccountId:account.identifier];
        
        dispatch_barrier_sync(self.repositoryAccessQueue, ^{
            [self.repositorySet addObjectsFromArray:repos];
        });
        
        [repos enumerateObjectsUsingBlock:^(QRepository * _Nonnull repo, NSUInteger idx, BOOL * _Nonnull stop) {
            [self _runInitialPullSyncherForRepository:repo];
            
        }];
    }];
}


- (void)_runInitialPullSyncherForRepository:(QRepository *)repository
{
    self.stopSyncher = NO;
    
    if (repository.initialSyncCompleted) {
        // // DDLogDebug(@"Initial Sync already completed for repository = %@", repository.fullName);
        
        // make sure the delta sync date is set
        QIssue *issue = [QIssueStore mostRecentUpdatedIssueForRepository:repository];
        if (issue) {
            NSDate *syncDate = issue.updatedAt ?: issue.createdAt;
            [QRepositoryStore saveDeltaSyncDate:syncDate forRepository:repository];
        }
        
        return;
    }
    
    if ([[SRIssueSyncWatcher sharedWatcher] isFullySynchingRepository:repository]) {
        DDLogDebug(@"Already running full syncher for repo -> %@", repository.name);
        return;
    }
    [self.repositorySyncherOperationQueue addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kWillStartSynchingRepositoryNotification object:repository userInfo:@{@"isFullSync": @YES}];
          DDLogDebug(@"Starting [Initial Pull] Sync Issues Job For Repository = [%@]", [repository fullName]);
        
        // fetch milestones
        __block NSError *error = nil;
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSMutableSet<QMilestone *> *currentMilestones = [[NSMutableSet alloc] initWithArray:[QMilestoneStore milestonesForAccountId:repository.account.identifier repositoryId:repository.identifier includeHidden:YES]];
        [self _fetchMilestonesForRepository:repository pageNumber:1 pageSize:100 currentMilestones:currentMilestones onCompletion:^(NSError *err) {
            error = err;
            dispatch_semaphore_signal(semaphore);
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        if ([self _isSynchableRepository:repository] && !error) {
            [currentMilestones enumerateObjectsUsingBlock:^(QMilestone * _Nonnull obj, BOOL * _Nonnull stop) {
                [QMilestoneStore hideMilestone:obj];
            }];
        }
        [QMilestoneStore unhideMilestonesNotInMilestoneSet:currentMilestones forAccountId:repository.account.identifier repositoryId:repository.identifier];
        
        // fetch labels
        semaphore = dispatch_semaphore_create(0);
        NSMutableSet<QLabel *> *currentLabels = [[NSMutableSet alloc] initWithArray:[QLabelStore labelsForAccountId:repository.account.identifier repositoryId:repository.identifier includeHidden:YES]];
         DDLogDebug(@"currentLabel => %@", currentLabels);
        [self _fetchLabelsForRepository:repository pageNumber:1 pageSize:100 currentLabels:currentLabels onCompletion:^(NSError *err) {
            error = err;
            dispatch_semaphore_signal(semaphore);
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        if ([self _isSynchableRepository:repository] && !error) {
            //// DDLogDebug(@"currentLabel deletions => %@", currentLabels);
            [currentLabels enumerateObjectsUsingBlock:^(QLabel * _Nonnull obj, BOOL * _Nonnull stop) {
                [QLabelStore hideLabel:obj];
            }];
        }
        [QLabelStore unhideLabelsNotInLabelSet:currentLabels accountId:repository.account.identifier repositoryId:repository.identifier];
        
        // fetch assignees
        semaphore = dispatch_semaphore_create(0);
        NSMutableSet<QOwner *> *currentAssignees = [[NSMutableSet alloc] initWithArray:[QOwnerStore ownersForAccountId:repository.account.identifier repositoryId:repository.identifier]];
        [self _fetchAssigneesForRepository:repository pageNumber:1 pageSize:100 currentAssignees:currentAssignees onCompletion:^(NSError *err) {
            error = err;
            dispatch_semaphore_signal(semaphore);
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        if ([self _isSynchableRepository:repository] && !error) {
            [currentAssignees enumerateObjectsUsingBlock:^(QOwner * _Nonnull obj, BOOL * _Nonnull stop) {
                [QRepositoryStore deleteAssignee:obj forRepository:repository];
            }];
        }
        
        // fetch issues
        NSIndexSet *identifierSet = [QIssueStore issuesIdsForRepository:repository];
        semaphore = dispatch_semaphore_create(0);
        [self _fetchIssuesForRepository:repository pageNumber:1 syncType:SRIssueSyncherTypeFull identifierSet:identifierSet dateMarker:nil pageSize:100 onIssueSaveCompletion:nil onCompletion:^(NSError *err){
            dispatch_semaphore_signal(semaphore);
            error = err;
        }];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        if (!error) {
            [QRepositoryStore markAsCompletedSyncForRepository:repository];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kDidFinishSynchingRepositoryNotification object:repository userInfo:@{@"isFullSync": @YES}];
         DDLogDebug(@"Finishing [Initial Pull] Sync Issues Job For Repository = [%@]", [repository fullName]);
        
        // make sure all repo data are deleted if repo is not synchable
        __block BOOL deletedRepository = NO;
        dispatch_sync(self.repositoryAccessQueue, ^{
            deletedRepository = ![self.repositorySet containsObject:repository];
        });
        if (deletedRepository) {
            [QRepositoryStore delete:repository];
        } else {
            
            // make sure the delta sync date is set
            QIssue *issue = [QIssueStore mostRecentUpdatedIssueForRepository:repository];
            if (issue) {
                NSDate *syncDate = issue.updatedAt ?: issue.createdAt;
                [QRepositoryStore saveDeltaSyncDate:syncDate forRepository:repository];
            }
            
        }
        
    }];
    
}

#pragma mark - Helpers

- (void)_fetchIssuesForRepository:(QRepository *)repo
                       pageNumber:(NSInteger)pageNumber
                         syncType:(SRIssueSyncherType)syncType
                    identifierSet:(NSIndexSet *)identifierSet
                       dateMarker:(NSDate *)dateMarker
                         pageSize:(NSInteger)pageSize
            onIssueSaveCompletion:(_QIssueSyncOnIssueSaveCompletion)onIssueSaveCompletion
                     onCompletion:(SRFetcherCompletion)onCompletion;
{
    NSParameterAssert(![NSThread isMainThread]);
    //// DDLogDebug(@"syncing issues for repository = [%@] pageNumber = [%ld] pageSize = [%ld] since = [%@]", repo.fullName, pageNumber, pageSize, since);
    
    if (![self _isSynchableRepository:repo]) {
        onCompletion(nil);
        return;
    }
    
    QIssuesService *service = [QIssuesService serviceForAccount:repo.account];
    
    NSString *sortKey = @"updated";
    BOOL ascending = YES;
    if (syncType == SRIssueSyncherTypeFull) {
        sortKey = @"created";
        ascending = NO;
    }
    
    [service issuesForRepository:repo pageNumber:pageNumber pageSize:pageSize sortKey:sortKey ascending:ascending since:dateMarker onCompletion:^(NSArray<QIssue *> *issues, QServiceResponseContext *context, NSError *error) {
        
        if (error) {
            // DDLogDebug(@"error [%@] synching issues for repository = [%@] final page = [%ld] since = [%@]", error, repo.fullName, pageNumber, dateMarker);
            if (onCompletion) {
                onCompletion(error);
            }
            return;
        }
        
        if (![self _isSynchableRepository:repo]) {
            onCompletion(nil);
            return;
        }
        
        NSMutableArray<NSNumber *> *issueNumbers = [NSMutableArray new];
        NSMutableDictionary<NSNumber *, QIssue *> *issueMap = [NSMutableDictionary new];
        
        [issues enumerateObjectsUsingBlock:^(QIssue *issue, NSUInteger idx, BOOL * _Nonnull stop) {
            [issueNumbers addObject:issue.number];
        }];
        
        NSArray<QIssue *> *localIssues = [QIssueStore issuesWithNumbers:issueNumbers forRepository:repo];
        [localIssues enumerateObjectsUsingBlock:^(QIssue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            issueMap[obj.number] = obj;
        }];
        
        if (syncType == SRIssueSyncherTypeFull) {
            if (issues.count > 0) {
                
                NSMutableArray<QIssue *> *newIssues = [[NSMutableArray alloc] init];
                [issues enumerateObjectsUsingBlock:^(QIssue * _Nonnull issue, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([identifierSet containsIndex:issue.number.unsignedIntegerValue] == NO) {
                        [newIssues addObject:issue];
                    } else {
                        // DDLogDebug(@"Already synched issue number [%@] for repository = [%@] createdAt = [%@] vs dateMarker = [%@]", issue.number, repo.fullName, issue.createdAt, dateMarker);
                    }
                }];
                
                if (newIssues.count == 0) {
                    // DDLogDebug(@"Skipping to next set of issues for repo = [%@] pageNumber = [%@] dateMarker = [%@]", repo.fullName, @(pageNumber), dateMarker);
                } else {
                    
                    [self _doSaveIssues:newIssues forRepository:repo syncType:syncType localIssues:issueMap onSaveCompletion:onIssueSaveCompletion];
                    
                }
                
            } else {
                [self _doSaveIssues:issues forRepository:repo syncType:syncType localIssues:issueMap onSaveCompletion:onIssueSaveCompletion];
            }
        }
        else {
            [self _doSaveIssues:issues forRepository:repo syncType:syncType localIssues:issueMap onSaveCompletion:onIssueSaveCompletion];
        }
        
        [self _sleepIfSyncherReachingRateLimitWithContext:context syncType:syncType];
        
        if (context.nextPageNumber) {
            [self _fetchIssuesForRepository:repo pageNumber:context.nextPageNumber.integerValue syncType:syncType identifierSet:identifierSet dateMarker:dateMarker pageSize:pageSize onIssueSaveCompletion:onIssueSaveCompletion onCompletion:onCompletion];
        } else {
            // // DDLogDebug(@"done synching issues for repository = [%@] final page = [%ld] since = [%@]", repo.fullName, pageNumber, since);
            if (onCompletion) {
                onCompletion(nil);
            }
        }
    }];
}


- (void)_sleepIfSyncherReachingRateLimitWithContext:(QServiceResponseContext *)context syncType:(SRIssueSyncherType)syncType
{
    if (syncType == SRIssueSyncherTypeManual) {
        return;
    }
    
    // sleep if about to hit rate limit
    if (context.nextRateLimitResetDate && context.rateLimitRemaining) {
        NSTimeInterval sleepSeconds = [context.nextRateLimitResetDate timeIntervalSinceDate:[NSDate new]];
        //// DDLogDebug(@"Next Rate Limit (%@) Reset on %@ seconds = %@", context.rateLimitRemaining, context.nextRateLimitResetDate, @([context.nextRateLimitResetDate timeIntervalSinceDate:[NSDate new]]) );
        
        if (context.rateLimitRemaining.integerValue < (syncType == SRIssueSyncherTypeFull ? 2000 : 1000) && sleepSeconds > 0) {
            DDLogDebug(@"Sleeping for %@ due to rate limit", @(sleepSeconds));
            [NSThread sleepForTimeInterval:sleepSeconds];
        }
    }
}

- (void)_doSaveIssues:(NSArray<QIssue *> *)issues forRepository:(QRepository *)repo syncType:(SRIssueSyncherType)syncType localIssues:(NSDictionary<NSNumber *, QIssue *> *)locaIssues onSaveCompletion:(_QIssueSyncOnIssueSaveCompletion)onIssueSaveCompletion
{
    
    // MAKE SURE NOT TO CALL THIS OUTSIDE THE SYNCH RUNNERS
    
    [issues enumerateObjectsUsingBlock:^(QIssue * _Nonnull issue, NSUInteger idx, BOOL * _Nonnull stop) {
        
        QIssue *currentIssue = [locaIssues objectForKey:issue.number]; //[QIssueStore issueWithNumber:issue.number forRepository:issue.repository];
        
        if ( [currentIssue.updatedAt isEqualToDate:issue.updatedAt] || ![self _isSynchableRepository:issue.repository] ) {
            if (onIssueSaveCompletion) {
                onIssueSaveCompletion(issue);
            }
            // // DDLogDebug(@"Skipping. No new changes on issue => %@", issue);
            return;
        }
        
        //DDLogDebug(@"Saving issue [%@/%@] -> [%@] vs existing update [%@]", issue.repository.fullName, issue.number, issue.updatedAt, currentIssue.updatedAt);
        
        //        NSMutableSet<NSNumber *> *currentIssueCommentIdSet = [NSMutableSet setWithArray:[QIssueCommentStore issueCommentIdsForAccountId:issue.account.identifier repositoryId:issue.repo.identifier issueNumber:issue.number] ?: [NSArray new]];
        //
        //        [self syncIssueEventsAndCommentsForIssueNumber:issue.number syncType:syncType repository:repo currentIssueCommentIdSet: currentIssueCommentIdSet];
        //
        //        [currentIssueCommentIdSet enumerateObjectsUsingBlock:^(NSNumber * _Nonnull issueCommentId, BOOL * _Nonnull stop) {
        //            // // DDLogDebug(@"deleted issue comment -> %@", issueCommentId);
        //            [QIssueCommentStore deleteIssueCommentId:issueCommentId accountId:issue.account.identifier repositoryId:issue.repo.identifier];
        //        }];
        
       // [self _syncIssueEventsForIssueNumber:issue.number syncType:syncType repository:repo dispatchQueue:self.refreshEventsAndCommentFetchQueue];
        
        [QIssueStore saveIssue:issue];
        NSDate *syncDate = issue.updatedAt ?: issue.createdAt;
        [QRepositoryStore saveDeltaSyncDate:syncDate forRepository:repo];
        
        if (onIssueSaveCompletion) {
            onIssueSaveCompletion(issue);
        }
    }];
}


- (void)refreshIssueEventsAndCommentsForIssueNumber:(NSNumber *)issueNumber repository:(QRepository *)repo skipIssueCheck:(BOOL)skipIssueCheck;
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        QIssuesService *service = [QIssuesService serviceForAccount:repo.account];
       // SRReactionsService *reactionsService = [SRReactionsService serviceForAccount:repo.account];
        [service issueForRepository:repo issueNumber:issueNumber onCompletion:^(QIssue *issue, QServiceResponseContext * _Nonnull context, NSError * _Nullable error) {
            if (error || !issue) {
                return;
            }
            
            if (!skipIssueCheck) {
                QIssue *currentIssue = [QIssueStore issueWithNumber:issue.number forRepository:issue.repository];
                if (currentIssue && [currentIssue.updatedAt isEqualToDate:issue.updatedAt] && currentIssue.htmlURL != nil) {
                    return;
                }
            }
            
            [QIssueStore saveIssue:issue];
            
            NSMutableSet<NSNumber *> *currentIssueCommentIdSet = [NSMutableSet setWithArray:[QIssueCommentStore issueCommentIdsForAccountId:repo.account.identifier repositoryId:repo.identifier issueNumber:issueNumber] ?: [NSArray new]];
            [self syncIssueEventsAndCommentsForIssueNumber:issueNumber syncType:SRIssueSyncherTypeManual repository:repo dispatchQueue:self.refreshEventsAndCommentFetchQueue currentIssueCommentIdSet:currentIssueCommentIdSet];
            
            
            [currentIssueCommentIdSet enumerateObjectsUsingBlock:^(NSNumber * _Nonnull issueCommentId, BOOL * _Nonnull stop) {
                // // DDLogDebug(@"deleted issue comment -> %@", issueCommentId);
                [QIssueCommentStore deleteIssueCommentId:issueCommentId accountId:repo.account.identifier repositoryId:repo.identifier];
            }];
            
        }];
    });
}

- (void)syncIssueEventsAndCommentsForIssueNumber:(NSNumber *)issueNumber syncType:(SRIssueSyncherType)syncType repository:(QRepository *)repo currentIssueCommentIdSet:(NSMutableSet<NSNumber *> *)currentIssueCommentIdSet
{
    [self syncIssueEventsAndCommentsForIssueNumber:issueNumber syncType:syncType repository:repo dispatchQueue:self.eventsAndCommentSyncherFetchQueue currentIssueCommentIdSet:currentIssueCommentIdSet];
}

- (void)syncIssueEventsAndCommentsForIssueNumber:(NSNumber *)issueNumber syncType:(SRIssueSyncherType)syncType repository:(QRepository *)repo dispatchQueue:(dispatch_queue_t)queue currentIssueCommentIdSet:(NSMutableSet<NSNumber *> *)currentIssueCommentIdSet
{
    if ((syncType != SRIssueSyncherTypeManual) && [self _isSynchableRepository:repo] == NO) {
        return;
    }
    
    // Issue Comments
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(queue, ^{
        [self _fetchIssueCommentsForRepository:repo issueNumber:issueNumber pageNumber:1 since:nil pageSize:100 syncType:syncType currentIssueCommentIdSet:currentIssueCommentIdSet onCompletion:^{
            dispatch_semaphore_signal(semaphore);
        }];
        
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    [self _syncIssueEventsForIssueNumber:issueNumber syncType:syncType repository:repo dispatchQueue:queue];
}

- (void)_syncIssueEventsForIssueNumber:(NSNumber *)issueNumber syncType:(SRIssueSyncherType)syncType repository:(QRepository *)repo dispatchQueue:(dispatch_queue_t)queue
{
    // Issue Events
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(queue, ^{
        [self _fetchIssueEventsForRepository:repo issueNumber:issueNumber pageNumber:1 since:nil pageSize:100 syncType:syncType onCompletion:^{
            dispatch_semaphore_signal(semaphore);
        }];
        
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}


- (void)_fetchIssueCommentsForRepository:(QRepository *)repo
                             issueNumber:(NSNumber *)issueNumber
                              pageNumber:(NSInteger)pageNumber
                                   since:(NSDate *)since
                                pageSize:(NSInteger)pageSize
                                syncType:(SRIssueSyncherType)syncType
                currentIssueCommentIdSet:(NSMutableSet<NSNumber *> *)currentIssueCommentIdSet
                            onCompletion:(dispatch_block_t)onCompletion;
{
    
    NSParameterAssert(onCompletion);
    
    if ((syncType != SRIssueSyncherTypeManual) && ![self _isSynchableRepository:repo]) {
        onCompletion();
        return;
    }
    
    QIssuesService *service = [QIssuesService serviceForAccount:repo.account];
    //SRReactionsService *reactionsService = [SRReactionsService serviceForAccount:repo.account];
    [service issuesCommentsForRepository:repo issueNumber:issueNumber pageNumber:pageNumber pageSize:pageSize since:since onCompletion:^(NSArray<QIssueComment *> *issueComments, QServiceResponseContext *context, NSError *error) {
        
        if ((syncType != SRIssueSyncherTypeManual) && ![self _isSynchableRepository:repo]) {
            onCompletion();
            return;
        }
        
        if (error) {
            // DDLogDebug(@"error [%@] synching issue comments for repository = [%@] final page = [%ld] since = [%@]", error, repo.fullName, pageNumber, since);
            if (onCompletion) {
                onCompletion();
            }
            return;
        }
        
        //        if (issueComments.count) {
        //            // DDLogDebug(@"saved [%@] issue comments for repository = [%@] issueNumber = [%@] pageNumber = [%ld] pageSize = [%ld] since = [%@]", @(issueComments.count), issueNumber, repo.fullName, pageNumber, pageSize, since);
        //        }
        
        [issueComments enumerateObjectsUsingBlock:^(QIssueComment * _Nonnull issueComment, NSUInteger idx, BOOL * _Nonnull stop) {
            // [_throttler throttle];
            if ((syncType != SRIssueSyncherTypeManual) && ![self _isSynchableRepository:repo]) {
                *stop = true;
                return;
            }
            
            [currentIssueCommentIdSet removeObject:issueComment.identifier];
            [QIssueCommentStore saveIssueComment:issueComment];
        
            
        }];
        
        [self _sleepIfSyncherReachingRateLimitWithContext:context syncType:syncType];
        
        if (context.nextPageNumber) {
            [self _fetchIssueCommentsForRepository:repo issueNumber:issueNumber pageNumber:context.nextPageNumber.integerValue since:since pageSize:pageSize syncType:syncType currentIssueCommentIdSet:currentIssueCommentIdSet onCompletion:onCompletion];
        } else {
            //// DDLogDebug(@"done synching issue comments for issueNumber = [%@] repository = [%@] final page = [%ld] since = [%@]", issueNumber, repo.fullName, pageNumber, since);
            if (onCompletion) {
                onCompletion();
            }
        }
        // });
    }];
}

- (void)_fetchIssueEventsForRepository:(QRepository *)repo
                           issueNumber:(NSNumber *)issueNumber
                            pageNumber:(NSInteger)pageNumber
                                 since:(NSDate *)since
                              pageSize:(NSInteger)pageSize
                              syncType:(SRIssueSyncherType)syncType
                          onCompletion:(dispatch_block_t)onCompletion;
{
    
    NSParameterAssert(onCompletion);
    
    if ((syncType != SRIssueSyncherTypeManual) && ![self _isSynchableRepository:repo]) {
        onCompletion();
        return;
    }
    
    QIssuesService *service = [QIssuesService serviceForAccount:repo.account];
    [service issuesEventsForRepository:repo issueNumber:issueNumber pageNumber:pageNumber pageSize:pageSize since:since onCompletion:^(NSArray<QIssueEvent *> *issueEvents, QServiceResponseContext *context, NSError *error) {
        if ((syncType != SRIssueSyncherTypeManual) && ![self _isSynchableRepository:repo]) {
            onCompletion();
            return;
        }
        
        if (error) {
            // DDLogDebug(@"error [%@] synching issue events for repository = [%@] final page = [%ld] since = [%@]", error, repo.fullName, pageNumber, since);
            //  if (onCompletion) {
            onCompletion();
            //  }
            return;
        }
        
        [issueEvents enumerateObjectsUsingBlock:^(QIssueEvent * _Nonnull issueEvent, NSUInteger idx, BOOL * _Nonnull stop) {
            //  [_throttler throttle];
            
            NSParameterAssert(onCompletion);
            
            if ((syncType != SRIssueSyncherTypeManual) && ![self _isSynchableRepository:repo]) {
                *stop = true;
                return;
            }
            
            [QIssueEventStore saveIssueEvent:issueEvent];
        }];
        
        [self _sleepIfSyncherReachingRateLimitWithContext:context syncType:syncType];
        
        if (context.nextPageNumber) {
            [self _fetchIssueEventsForRepository:repo issueNumber:issueNumber pageNumber:context.nextPageNumber.integerValue since:since pageSize:pageSize syncType:syncType onCompletion:onCompletion];
        } else {
            // // DDLogDebug(@"done synching issue events for issueNumber = [%@] repository = [%@] final page = [%ld] since = [%@]", issueNumber, repo.fullName, pageNumber, since);
            //   if (onCompletion) {
            onCompletion();
            //  }
        }
        //  });
    }];
}

- (void)_fetchMilestonesForRepository:(QRepository *)repo pageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize currentMilestones:(NSMutableSet<QMilestone *> *)currentMilestones onCompletion:(SRFetcherCompletion)onCompletion;
{
    NSParameterAssert(onCompletion);
    
    if (![self _isSynchableRepository:repo]) {
        onCompletion([NSError errorWithDomain:@"co.hellocode.syncher.error" code:0 userInfo:nil]);
        return;
    }
    
    QRepositoriesService *service = [QRepositoriesService serviceForAccount:repo.account];
    [service milestonesForRepository:repo pageNumber:pageNumber pageSize:pageSize onCompletion:^(NSArray<QMilestone *> *milestones, QServiceResponseContext *context, NSError *error) {
        
        if (![self _isSynchableRepository:repo]) {
            onCompletion([NSError errorWithDomain:@"co.hellocode.syncher.error" code:0 userInfo:nil]);
            return;
        }
        
        [milestones enumerateObjectsUsingBlock:^(QMilestone * _Nonnull milestone, NSUInteger idx, BOOL * _Nonnull stop) {
            //  [_throttler throttle];
            
            NSParameterAssert(onCompletion);
            
            if (![self _isSynchableRepository:repo]) {
                *stop = true;
                return;
            }
            
            [QMilestoneStore saveMilestone:milestone];
            [currentMilestones removeObject:milestone];
        }];
        
        if (context.nextPageNumber) {
            [self  _fetchMilestonesForRepository:repo pageNumber:context.nextPageNumber.integerValue pageSize:pageSize currentMilestones:currentMilestones onCompletion:onCompletion];
        } else {
            onCompletion(error);
        }
    }];
}

- (void)_fetchLabelsForRepository:(QRepository *)repo pageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize currentLabels:(NSMutableSet<QLabel *> *)currentLabels onCompletion:(SRFetcherCompletion)onCompletion;
{
    NSParameterAssert(onCompletion);
    
    if (![self _isSynchableRepository:repo]) {
        onCompletion([NSError errorWithDomain:@"co.hellocode.syncher.error" code:0 userInfo:nil]);
        return;
    }
    
    QRepositoriesService *service = [QRepositoriesService serviceForAccount:repo.account];
    [service labelsForRepository:repo pageNumber:pageNumber pageSize:pageSize onCompletion:^(NSArray<QLabel *> *labels, QServiceResponseContext *context, NSError *error) {
        
        if (![self _isSynchableRepository:repo]) {
            onCompletion([NSError errorWithDomain:@"co.hellocode.syncher.error" code:0 userInfo:nil]);
            return;
        }
        
        [labels enumerateObjectsUsingBlock:^(QLabel * _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
            // [_throttler throttle];
            
            if (![self _isSynchableRepository:repo]) {
                *stop = true;
                return;
            }
            
            [QLabelStore saveLabel:label allowUpdate:YES];
            [currentLabels removeObject:label];
        }];
        
        if (context.nextPageNumber) {
            [self  _fetchLabelsForRepository:repo pageNumber:context.nextPageNumber.integerValue pageSize:pageSize currentLabels:currentLabels onCompletion:onCompletion];
        } else {
            onCompletion(error);
        }
    }];
}

- (void)_fetchAssigneesForRepository:(QRepository *)repo pageNumber:(NSInteger)pageNumber pageSize:(NSInteger)pageSize currentAssignees:(NSMutableSet<QOwner *> *)currentAssignees onCompletion:(SRFetcherCompletion)onCompletion;
{
    NSParameterAssert(onCompletion);
    
    if (![self _isSynchableRepository:repo]) {
        onCompletion([NSError errorWithDomain:@"co.hellocode.syncher.error" code:0 userInfo:nil]);
        return;
    }
    
    QRepositoriesService *service = [QRepositoriesService serviceForAccount:repo.account];
    [service assigneesForRepository:repo pageNumber:pageNumber pageSize:pageSize onCompletion:^(NSArray<QOwner *> *assignees, QServiceResponseContext *context, NSError *error) {
        
        if (![self _isSynchableRepository:repo]) {
            onCompletion([NSError errorWithDomain:@"co.hellocode.syncher.error" code:0 userInfo:nil]);
            return;
        }
        
        [assignees enumerateObjectsUsingBlock:^(QOwner * _Nonnull assignee, NSUInteger idx, BOOL * _Nonnull stop) {
            //  [_throttler throttle];
            
            if (![self _isSynchableRepository:repo]) {
                *stop = true;
                return;
            }
            
            [QRepositoryStore saveAssignee:assignee forRepository:repo];
            [currentAssignees removeObject:assignee];
        }];
        
        if (context.nextPageNumber) {
            [self  _fetchAssigneesForRepository:repo pageNumber:context.nextPageNumber.integerValue pageSize:pageSize currentAssignees:currentAssignees onCompletion:onCompletion];
        } else {
            onCompletion(error);
        }
    }];
}

#pragma mark - QStoreObserver
- (void)store:(Class)store didInsertRecord:(id)record;
{
    if ([record isKindOfClass:QRepository.class]) {
        dispatch_barrier_sync(self.repositoryAccessQueue, ^{
            [self.repositorySet addObject:record];
        });
    }
    
    if ([record isKindOfClass:QRepository.class]) {
        [self _runInitialPullSyncherForRepository:record];
    }
}


- (void)store:(Class)store didUpdateRecord:(id)record;
{
    
}

- (void)store:(Class)store didRemoveRecord:(id)record;
{
    if ([record isKindOfClass:QRepository.class]) {
        dispatch_barrier_sync(self.repositoryAccessQueue, ^{
            [self.repositorySet removeObject:record];
        });
    } else if ([record isKindOfClass:QAccount.class]) {
        dispatch_barrier_sync(self.repositoryAccessQueue, ^{
            NSMutableArray<QRepository *> *removals = [NSMutableArray new];
            [self.repositorySet enumerateObjectsUsingBlock:^(QRepository * _Nonnull repo, BOOL * _Nonnull stop) {
                if ([repo.account isEqual:record]) {
                    [removals addObject:repo];
                }
            }];
            
            [removals enumerateObjectsUsingBlock:^(QRepository *repo, NSUInteger idx, BOOL * _Nonnull stop) {
                [self.repositorySet removeObject:repo];
            }];
        });
    }
}


@end
