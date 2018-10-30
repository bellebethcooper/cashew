//
//  QRepositoriesDataSource.m
//  Queues
//
//  Created by Hicham Bouabdallah on 1/9/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QSourceListDataSource.h"
#import "QRepositoriesService.h"
#import "QRepository.h"
#import "QAccount.h"
#import "QContext.h"
#import "QAccountStore.h"
#import "QRepositoryStore.h"
#import "QIssueFilter.h"
#import "QIssueStore.h"
#import "QOwnerStore.h"
#import "QIssueConstants.h"
#import "QMilestoneStore.h"
#import "QUserQueryStore.h"
#import "QCommonConstants.h"
#import "QOwnerStore.h"
#import "QUserQueryStore.h"
#import "Cashew-Swift.h"

@interface QSourceListDataSource ()<QStoreObserver>
@property (nonatomic) NSMutableArray<QSourceListNode *> *sections;
@property (nonatomic) NSMutableArray<QSourceListNode *> *filteredSections;
@property (nonatomic) dispatch_queue_t accessQueue;
@property (nonatomic) NSString *filterText;
@end


@implementation QSourceListDataSource

+ (instancetype)dataSource
{
    QSourceListDataSource *ds = [QSourceListDataSource new];
    return ds;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.accessQueue = dispatch_queue_create("co.cashewapp.QSourceListDataSource.accessQueue", DISPATCH_QUEUE_CONCURRENT);
        [QRepositoryStore addObserver:self];
        [QUserQueryStore addObserver:self];
        [QMilestoneStore addObserver:self];
    }
    return self;
}

- (void)dealloc
{
    [QRepositoryStore remove:self];
    [QUserQueryStore remove:self];
    [QMilestoneStore remove:self];
}

- (BOOL)_isShowingFilteredSections
{
    return self.filterText.length > 0;
}

- (NSArray *)_nodes
{
    return [self _isShowingFilteredSections]? self.filteredSections : self.sections;
}

- (QSourceListNode *)_menuNodeForUser:(QOwner *)user
{
    NSMutableArray<QSourceListNode *> *children = [NSMutableArray new];
    
    QSourceListNode *menuNode = [QSourceListNode new];
    menuNode.title =  @"MAIN MENU";
    menuNode.nodeType = QSourceListNodeType_Menu;
    menuNode.children = children;
    
    QUserQuery *allUserQuery = [[QUserQuery alloc] initWithIdentifier:nil account:_account displayName:@"All Issues" query:@""];
    QSourceListNode *allNode = [QSourceListNode new];
    allNode.title = allUserQuery.displayName;
    allNode.nodeType = QSourceListNodeType_All;
    allNode.userQuery = allUserQuery;
    allNode.issueFilter = [QIssueFilter filterWithSearchTokens:allUserQuery.query];
    allNode.issueFilter.filterType = SRFilterType_Search;
    allNode.issueFilter.account = self.account;
    allNode.parentNode = menuNode;
    
    QUserQuery *notificationUserQuery = [[QUserQuery alloc] initWithIdentifier:nil account:_account displayName:@"Notifications" query:@""];
    QSourceListNode *notificationNode = [QSourceListNode new];
    notificationNode.title = notificationUserQuery.displayName;
    notificationNode.nodeType = QSourceListNodeType_Notifications;
    notificationNode.userQuery = notificationUserQuery;
    notificationNode.issueFilter = [QIssueFilter filterWithSearchTokens:notificationUserQuery.query];
    notificationNode.issueFilter.filterType = SRFilterType_Notifications;
    notificationNode.issueFilter.account = self.account;
    notificationNode.parentNode = menuNode;
    
    QUserQuery *draftsUserQuery = [[QUserQuery alloc] initWithIdentifier:nil account:_account displayName:@"Drafts" query:@""];
    QSourceListNode *draftsNode = [QSourceListNode new];
    draftsNode.title = draftsUserQuery.displayName;
    draftsNode.nodeType = QSourceListNodeType_Drafts;
    draftsNode.userQuery = draftsUserQuery;
    draftsNode.issueFilter = [QIssueFilter filterWithSearchTokens:draftsUserQuery.query];
    draftsNode.issueFilter.filterType = SRFilterType_Drafts;
    draftsNode.issueFilter.account = self.account;
    draftsNode.parentNode = menuNode;
    
//    QUserQuery *favoritesQuery = [[QUserQuery alloc] initWithIdentifier:nil account:_account displayName:@"Favorites" query:@""];
//    QSourceListNode *favoritesNode = [QSourceListNode new];
//    favoritesNode.title = favoritesQuery.displayName;
//    favoritesNode.nodeType = QSourceListNodeType_Favorites;
//    favoritesNode.userQuery = favoritesQuery;
//    favoritesNode.issueFilter = [QIssueFilter filterWithSearchTokens:favoritesQuery.query];
//    favoritesNode.issueFilter.filterType = SRFilterType_Favorites;
//    favoritesNode.issueFilter.account = self.account;
//    favoritesNode.parentNode = menuNode;
    
    [children addObject:allNode];
    [children addObject:notificationNode];
    [children addObject:draftsNode];
//    [children addObject:favoritesNode];
    //    [children addObject:mentionsMeNode];
    
    return menuNode;
}

- (QSourceListNode *)_openIssuesNodeForUser:(QOwner *)user
{
    NSMutableArray<QSourceListNode *> *children = [NSMutableArray new];
    
    QSourceListNode *openIssuesNode = [QSourceListNode new];
    openIssuesNode.title =  @"OPEN ISSUES";
    openIssuesNode.nodeType = QSourceListNodeType_OpenIssues;
    openIssuesNode.children = children;
    
    QUserQuery *assignedToMeQuery = [[QUserQuery alloc] initWithIdentifier:nil account:_account displayName:@"Assigned to me" query:[NSString stringWithFormat:@"is:open assignee:%@", user.login]];
    QSourceListNode *assignedToMeNode = [QSourceListNode new];
    assignedToMeNode.title = assignedToMeQuery.displayName;
    assignedToMeNode.nodeType = QSourceListNodeType_AssignedToMe;
    assignedToMeNode.userQuery = assignedToMeQuery;
    assignedToMeNode.issueFilter = [QIssueFilter filterWithSearchTokens:assignedToMeQuery.query];
    assignedToMeNode.issueFilter.account = _account;
    assignedToMeNode.parentNode = openIssuesNode;
    
    QUserQuery *reportedByMeQuery = [[QUserQuery alloc] initWithIdentifier:nil account:_account displayName:@"Reported by me" query:[NSString stringWithFormat:@"is:open author:%@", user.login]];
    QSourceListNode *reportedByMeNode = [QSourceListNode new];
    reportedByMeNode.title = reportedByMeQuery.displayName;
    reportedByMeNode.nodeType = QSourceListNodeType_ReportedByMe;
    reportedByMeNode.userQuery = reportedByMeQuery;
    reportedByMeNode.issueFilter = [QIssueFilter filterWithSearchTokens:reportedByMeQuery.query];
    reportedByMeNode.issueFilter.account = _account;
    reportedByMeNode.parentNode = openIssuesNode;
    
    QUserQuery *mentionsMeQuery = [[QUserQuery alloc] initWithIdentifier:nil account:_account displayName:@"Mentions me" query:[NSString stringWithFormat:@"is:open mentions:%@", user.login]];
    QSourceListNode *mentionsMeNode = [QSourceListNode new];
    mentionsMeNode.title = mentionsMeQuery.displayName;
    mentionsMeNode.nodeType = QSourceListNodeType_MentionsMe;
    mentionsMeNode.userQuery = mentionsMeQuery;
    mentionsMeNode.issueFilter = [QIssueFilter filterWithSearchTokens:mentionsMeQuery.query];
    mentionsMeNode.issueFilter.account = _account;
    mentionsMeNode.parentNode = openIssuesNode;
    
    NSParameterAssert([assignedToMeNode isKindOfClass:QSourceListNode.class]);
    NSParameterAssert([reportedByMeNode isKindOfClass:QSourceListNode.class]);
    NSParameterAssert([mentionsMeNode isKindOfClass:QSourceListNode.class]);
    
    [children addObject:assignedToMeNode];
    [children addObject:reportedByMeNode];
    [children addObject:mentionsMeNode];
    
    return openIssuesNode;
}

- (QSourceListNode *)_repositoriesNodeForUser:(QOwner *)user
{
    NSArray<QRepository *> *repositories = [QRepositoryStore repositoriesForAccountId:_account.identifier];
    NSMutableArray<QSourceListNode *> *children = [NSMutableArray new];
    
    QSourceListNode *repositoriesNode = [QSourceListNode new];
    repositoriesNode.title =  @"REPOSITORIES";
    repositoriesNode.nodeType = QSourceListNodeType_Repositories;
    repositoriesNode.children = children;
    
    [repositories enumerateObjectsUsingBlock:^(QRepository * _Nonnull repo, NSUInteger idx, BOOL * _Nonnull stop) {
        QSourceListNode *repositoryNode = [self _createNodeForRepository:repo];
        repositoryNode.parentNode = repositoriesNode;
        NSParameterAssert([repositoryNode isKindOfClass:QSourceListNode.class]);
        [children addObject:repositoryNode];
    }];
    
    return repositoriesNode;
}

- (QSourceListNode *)_createNodeForRepository:(QRepository *)repo
{
    NSMutableArray<QSourceListNode *> *repoChildren = [NSMutableArray new];
    QUserQuery *repositoryQuery = [[QUserQuery alloc] initWithIdentifier:nil account:_account displayName:repo.fullName query:[NSString stringWithFormat:@"repo:%@", repo.fullName]];
    QSourceListNode *repositoryNode = [QSourceListNode new];
    
    repositoryNode.title = repositoryQuery.displayName;
    repositoryNode.nodeType = QSourceListNodeType_Repository;
    repositoryNode.userQuery = repositoryQuery;
    repositoryNode.representedObject = repo;
    repositoryNode.issueFilter = [QIssueFilter filterWithSearchTokens:repositoryQuery.query];
    repositoryNode.issueFilter.account = _account;
    repositoryNode.children = repoChildren;
    
    NSArray<QMilestone *> *milestones = [QMilestoneStore openMilestonesForAccountId:repo.account.identifier repositoryId:repo.identifier];
    [milestones enumerateObjectsUsingBlock:^(QMilestone * _Nonnull milestone, NSUInteger idx, BOOL * _Nonnull stop) {
        QSourceListNode *milestoneNode = [self _createNodeForMilestone:milestone];
        milestoneNode.parentNode = repositoryNode;
        NSParameterAssert([milestoneNode isKindOfClass:QSourceListNode.class]);
        [repoChildren addObject:milestoneNode];
    }];
    
    return repositoryNode;
}

- (QSourceListNode *)_createNodeForMilestone:(QMilestone *)milestone
{
    NSString *milestoneValue = [milestone.title containsString:@" "] ? [NSString stringWithFormat:@"\"%@\"", milestone.title] : milestone.title;
    QUserQuery *milestoneQuery = [[QUserQuery alloc] initWithIdentifier:nil account:_account displayName:milestone.repository.fullName query:[NSString stringWithFormat:@"is:open milestone:%@", milestoneValue]];
    QSourceListNode *milestoneNode = [QSourceListNode new];
    
    milestoneNode.title = milestone.title;
    milestoneNode.nodeType = QSourceListNodeType_Milestone;
    milestoneNode.userQuery = milestoneQuery;
    milestoneNode.representedObject = milestone;
    milestoneNode.issueFilter = [QIssueFilter filterWithSearchTokens:milestoneQuery.query];
    milestoneNode.issueFilter.account = self.account;
    
    return milestoneNode;
}


- (QSourceListNode *)_customSearchesNodeWithItems:(NSArray<QUserQuery *> *)items
{
    NSMutableArray<QSourceListNode *> *children = [NSMutableArray new];
    QSourceListNode *savedSearchesNode = [QSourceListNode new];
    savedSearchesNode.title =  @"SEARCHES";
    savedSearchesNode.nodeType = QSourceListNodeType_CustomFilters;
    savedSearchesNode.children = children;
    
    [items enumerateObjectsUsingBlock:^(QUserQuery * _Nonnull userQuery, NSUInteger idx, BOOL * _Nonnull stop) {
        QSourceListNode *saveSearchNode = [self _createNodeForUserQuery:userQuery];
        saveSearchNode.parentNode = savedSearchesNode;
        
        NSParameterAssert(savedSearchesNode && [saveSearchNode isKindOfClass:QSourceListNode.class]);
        [children addObject:saveSearchNode];
    }];
    
    return savedSearchesNode;
}

- (QSourceListNode *)_createNodeForUserQuery:(QUserQuery *)userQuery
{
    QSourceListNode *saveSearchNode = [QSourceListNode new];
    
    saveSearchNode.title = userQuery.displayName;
    saveSearchNode.nodeType = QSourceListNodeType_CustomFilter;
    saveSearchNode.userQuery = userQuery;
    saveSearchNode.representedObject = userQuery;
    saveSearchNode.issueFilter = [QIssueFilter filterWithSearchTokens:userQuery.query];
    saveSearchNode.issueFilter.account = userQuery.account;
    
    return saveSearchNode;
}

- (void)filterNodesUsingText:(NSString *)filterText onCompletion:(QRepositiesFetchDataCompletion)completion;
{
    self.filterText = filterText.trimmedString;
    
    if (![self _isShowingFilteredSections]) {
        self.filteredSections = @[].mutableCopy;
        completion(nil);
        return;
    }
    
    NSMutableArray<QSourceListNode *> *filteredSections = [NSMutableArray new];
    NSArray<QSourceListNode *> *sections = [self.sections copy];
    NSString *lowercasedFilterString = [filterText lowercaseString];
    
    [sections enumerateObjectsUsingBlock:^(QSourceListNode * _Nonnull parentNode, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<QSourceListNode *> *children = [parentNode.children copy];
        NSMutableArray<QSourceListNode *> *filterdChildren = [NSMutableArray new];
        QSourceListNode *copiedParent = [QSourceListNode new];
        
        [children enumerateObjectsUsingBlock:^(QSourceListNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([node.title.lowercaseString containsString:lowercasedFilterString]) {
                
                QSourceListNode *copiedNode = [QSourceListNode new];
                copiedNode.parentNode = copiedParent;
                //copiedParent.children = filterdChildren;
                copiedNode.title = node.title;
                copiedNode.issueFilter = node.issueFilter;
                copiedNode.userQuery = node.userQuery;
                copiedNode.nodeType = node.nodeType;
                copiedNode.representedObject = node.representedObject;
                
                [filterdChildren addObject:copiedNode];
            }
        }];
        
        if (filterdChildren.count > 0) {
            copiedParent.parentNode = nil;
            copiedParent.children = filterdChildren;
            copiedParent.title = parentNode.title;
            copiedParent.issueFilter = parentNode.issueFilter;
            copiedParent.userQuery = parentNode.userQuery;
            copiedParent.nodeType = parentNode.nodeType;
            copiedParent.representedObject = parentNode.representedObject;
            
            [filteredSections addObject:copiedParent];
            //            @property (nonatomic, weak) QSourceListNode *parentNode;
            //            @property (nonatomic) NSMutableArray<QSourceListNode *> *children;
            //            @property (nonatomic) NSString *title;
            //            @property (nonatomic) QIssueFilter *issueFilter;
            //            @property (nonatomic) QUserQuery *userQuery;
            //            @property (nonatomic) QSourceListNodeType nodeType;
            //            @property (nonatomic) NSObject *representedObject;
        }
        
    }];
    
    dispatch_barrier_sync(self.accessQueue, ^{
        self.filteredSections = filteredSections;
    });
    completion(nil);
}

- (void)fetchItemsForAccount:(QAccount *)account onCompletion:(QRepositiesFetchDataCompletion)completion
{
    NSParameterAssert(account);
    
    _account = account;
    QOwner *user = [QOwnerStore ownerForAccountId:account.identifier identifier:account.userId];
    NSMutableArray<QUserQuery *> * items =[QUserQueryStore fetchUserQueriesForAccount:account];
    
    QSourceListNode *menuNode = [self _menuNodeForUser:user];
    QSourceListNode *openIssuesNode = [self _openIssuesNodeForUser:user];
    QSourceListNode *repositoriesNode = [self _repositoriesNodeForUser:user];
    QSourceListNode *customSearchesNode = [self _customSearchesNodeWithItems:items];
    
    NSMutableArray *sections = [[NSMutableArray alloc] initWithObjects:menuNode, openIssuesNode, nil];
    
    if (repositoriesNode.children.count > 0) {
        NSParameterAssert([repositoriesNode isKindOfClass:QSourceListNode.class]);
        [sections addObject:repositoriesNode];
    }
    
    if (customSearchesNode.children.count > 0) {
        NSParameterAssert([customSearchesNode isKindOfClass:QSourceListNode.class]);
        [sections addObject:customSearchesNode];
    }
    
    dispatch_barrier_sync(self.accessQueue, ^{
        self.sections = sections;
    });
    
    if ([self _isShowingFilteredSections]) {
        [self filterNodesUsingText:self.filterText onCompletion:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(nil);
                }
            });
        }];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(nil);
            }
        });
    }
}

- (NSInteger)numberOfSections;
{
    __block NSInteger count = 0;
    dispatch_sync(self.accessQueue, ^{
        count = [self _nodes].count;
    });
    return count;
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section;
{
    __block NSInteger count = 0;
    dispatch_sync(self.accessQueue, ^{
        QSourceListNode *node = [self _nodes][section];
        count = [node.children count];
    });
    return count;
}

- (QSourceListNode *)childNodeAtIndex:(NSInteger)row forItem:(QSourceListNode *)node;
{
    __block QSourceListNode *returnNode = nil;
    
    dispatch_sync(self.accessQueue, ^{
        if (node == nil) {
            returnNode = row < [self _nodes].count ? [self _nodes][row] : nil;
        } else {
            returnNode = node.children[row];
        }
    });
    
    return returnNode;
}

#pragma mark - section lookup

- (QSourceListNode *)notificationNode
{
    QSourceListNode *mainMenu = [self _sectionNodeForNodeType:QSourceListNodeType_Menu];
    __block QSourceListNode *notificationNode = nil;
    [[mainMenu children] enumerateObjectsUsingBlock:^(QSourceListNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.nodeType == QSourceListNodeType_Notifications) {
            notificationNode = obj;
            *stop = true;
            return;
        }
    }];
    return notificationNode;
}

- (QSourceListNode *)favoritesNode
{
    QSourceListNode *mainMenu = [self _sectionNodeForNodeType:QSourceListNodeType_Menu];
    __block QSourceListNode *favoritesNode = nil;
    [[mainMenu children] enumerateObjectsUsingBlock:^(QSourceListNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.nodeType == QSourceListNodeType_Favorites) {
            favoritesNode = obj;
            *stop = true;
            return;
        }
    }];
    return favoritesNode;
}

- (QSourceListNode *)_openIssuesSectionNode
{
    return [self _sectionNodeForNodeType:QSourceListNodeType_OpenIssues];
}

- (QSourceListNode *)_repositoriesSectionNode
{
    return [self _sectionNodeForNodeType:QSourceListNodeType_Repositories];
}

- (QSourceListNode *)_userSearchQuerySectionNode
{
    return [self _sectionNodeForNodeType:QSourceListNodeType_CustomFilters];
}

- (QSourceListNode *)_sectionNodeForNodeType:(QSourceListNodeType)nodeType;
{
    __block QSourceListNode *node = nil;
    
    dispatch_sync(self.accessQueue, ^{
        [self.sections enumerateObjectsUsingBlock:^(QSourceListNode * sectionNode, NSUInteger idx, BOOL * _Nonnull stop) {
            if (sectionNode.nodeType == nodeType) {
                node = sectionNode;
                *stop = true;
            }
        }];
    });
    
    return node;
}

#pragma mark - Repository Helpers

- (void)_didInsertRepository:(QRepository *)repository
{
    if (!self.sections) {
        return;
    }
    
    QSourceListNode *repoSectionNode = [self _repositoriesSectionNode];
    
    if (repoSectionNode) {
        __block QSourceListNode *repositoryNode = nil;
        __block NSInteger index = NSNotFound;
        dispatch_barrier_sync(self.accessQueue, ^{
            repositoryNode = [self _createNodeForRepository:repository];
            repositoryNode.parentNode = repoSectionNode;
            
            index = [repoSectionNode.children insertionIndexOf:repositoryNode comparator:^NSComparisonResult(QSourceListNode *obj1, QSourceListNode *obj2) {
                QRepository *repo1 = (QRepository *)obj1.representedObject;
                QRepository *repo2 = (QRepository *)obj2.representedObject;
                return [repo1.fullName compare:repo2.fullName];
            }];
            
            NSParameterAssert([repositoryNode isKindOfClass:QSourceListNode.class]);
            [repoSectionNode.children insertObject:repositoryNode atIndex:index];
        });
        NSParameterAssert(index != NSNotFound);
        NSParameterAssert(repositoryNode.parentNode);
        if (![self _isShowingFilteredSections]) {
            [self.delegate sourceListDataSource:self didInsertNode:repositoryNode atIndex:index];
        }
        
    } else {
        NSInteger index = 2;
        QOwner *user = [QOwnerStore ownerForAccountId:self.account.identifier identifier:self.account.userId];
        repoSectionNode = [self _repositoriesNodeForUser:user];
        dispatch_barrier_sync(self.accessQueue, ^{
            NSParameterAssert([repoSectionNode isKindOfClass:QSourceListNode.class]);
            [self.sections insertObject:repoSectionNode atIndex:index];
        });
        
        NSParameterAssert(!repoSectionNode.parentNode);
        if (![self _isShowingFilteredSections]) {
            [self.delegate sourceListDataSource:self didInsertNode:repoSectionNode atIndex:index];
        }
    }
}

- (void)_didUpdateRepository:(QRepository *)repository
{
    if (!self.sections) {
        return;
    }
    
    QSourceListNode *repoSectionNode = [self _repositoriesSectionNode];
    
    if (!repoSectionNode) {
        return;
    }
    
    __block QSourceListNode *foundNode = nil;
    dispatch_barrier_sync(self.accessQueue, ^{
        [repoSectionNode.children enumerateObjectsUsingBlock:^(QSourceListNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([repository isEqual:node.representedObject]) {
                foundNode = node;
                foundNode.representedObject = repository;
                foundNode.title = repository.fullName;
                repoSectionNode.children[idx] = node;
                *stop = true;
            }
        }];
    });
    
    if (foundNode != nil) {
        NSParameterAssert(foundNode.parentNode);
        if (![self _isShowingFilteredSections]) {
            [self.delegate sourceListDataSource:self didUpdateNode:foundNode];
        }
    }
    
}

- (void)_didUpdateUserQuery:(QUserQuery *)userQuery
{
    if (!self.sections) {
        return;
    }
    
    QSourceListNode *userQuerySectionNode = [self _userSearchQuerySectionNode];
    
    if (!userQuerySectionNode) {
        return;
    }
    
    __block QSourceListNode *foundNode = nil;
    dispatch_barrier_sync(self.accessQueue, ^{
        [userQuerySectionNode.children enumerateObjectsUsingBlock:^(QSourceListNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([userQuery isEqual:node.representedObject]) {
                foundNode = node;
                foundNode.representedObject = userQuery;
                foundNode.title = userQuery.displayName;
                userQuerySectionNode.children[idx] = node;
                *stop = true;
            }
        }];
    });
    
    if (foundNode != nil) {
        NSParameterAssert(foundNode.parentNode);
        if (![self _isShowingFilteredSections]) {
            [self.delegate sourceListDataSource:self didUpdateNode:foundNode];
        }
    }
}

- (void)_didRemoveRepository:(QRepository *)repository
{
    if (!self.sections) {
        return;
    }
    
    QSourceListNode *repoSectionNode = [self _repositoriesSectionNode];
    
    if (!repoSectionNode) {
        return;
    }
    
    __block QSourceListNode *foundNode = nil;
    __block NSUInteger index = NSNotFound;
    dispatch_barrier_sync(self.accessQueue, ^{
        [repoSectionNode.children enumerateObjectsUsingBlock:^(QSourceListNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([repository isEqual:node.representedObject]) {
                foundNode = node;
                index = idx;
                *stop = true;
            }
        }];
        if (index != NSNotFound) {
            [repoSectionNode.children removeObjectAtIndex:index];
        }
    });
    
    if (foundNode != nil) {
        __block NSUInteger sectionCount = 0;
        __block NSUInteger indexOfSection = NSNotFound;
        dispatch_barrier_sync(self.accessQueue, ^{
            sectionCount = repoSectionNode.children.count;
            indexOfSection = [self.sections indexOfObject:repoSectionNode];
            
            if (sectionCount == 0) {
                [self.sections removeObjectAtIndex:indexOfSection];
            }
        });
        
        if (![self _isShowingFilteredSections]) {
            if (sectionCount == 0) {
                NSParameterAssert(!repoSectionNode.parentNode);
                [self.delegate sourceListDataSource:self didRemoveNode:repoSectionNode atIndex:indexOfSection];
            } else {
                NSParameterAssert(foundNode.parentNode);
                [self.delegate sourceListDataSource:self didRemoveNode:foundNode atIndex:index];
            }
        }
    }
}

#pragma mark - Milestone Helpers

- (void)_didInsertMilestone:(QMilestone *)milestone
{
    if (!self.sections || milestone.closedAt != nil) {
        return;
    }
    
    QSourceListNode *repoSectionNode = [self _repositoriesSectionNode];
    
    if (!repoSectionNode) {
        return;
    }
    __block QSourceListNode *repositoryNode = nil;
    dispatch_sync(self.accessQueue, ^{
        [repoSectionNode.children enumerateObjectsUsingBlock:^(QSourceListNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([milestone.repository isEqual:node.representedObject]) {
                repositoryNode = node;
                *stop = true;
            }
        }];
    });
    
    if (!repositoryNode) {
        return;
    }
    
    __block QSourceListNode *milestoneNode = nil;
    __block NSInteger index = NSNotFound;
    
    dispatch_barrier_sync(self.accessQueue, ^{
        milestoneNode = [self _createNodeForMilestone:milestone];
        milestoneNode.parentNode = repositoryNode;
        
        index = [repositoryNode.children indexOfObjectPassingTest:^BOOL(QSourceListNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [milestone isEqual:obj.representedObject];
        }];
        
        if (index != NSNotFound) {
            return;
        }
        
        index = [repositoryNode.children insertionIndexOf:milestoneNode comparator:^NSComparisonResult(QSourceListNode *obj1, QSourceListNode *obj2) {
            QMilestone *milestone1 = (QMilestone *)obj1.representedObject;
            QMilestone *milestone2 = (QMilestone *)obj2.representedObject;
            return [milestone1.title compare:milestone2.title];
        }];
        
        NSParameterAssert([milestoneNode isKindOfClass:QSourceListNode.class]);
        [repositoryNode.children insertObject:milestoneNode atIndex:index];
    });
    
    NSParameterAssert(milestoneNode.parentNode);
    if (![self _isShowingFilteredSections]) {
        [self.delegate sourceListDataSource:self didInsertNode:milestoneNode atIndex:index];
    }
    
    
}

- (void)_didUpdateMilestone:(QMilestone *)milestone
{
    if (!self.sections) {
        return;
    }
    
    QSourceListNode *repoSectionNode = [self _repositoriesSectionNode];
    
    if (!repoSectionNode) {
        return;
    }
    
    __block QSourceListNode *foundNode = nil;
    dispatch_barrier_sync(self.accessQueue, ^{
        [repoSectionNode.children enumerateObjectsUsingBlock:^(QSourceListNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([milestone.repository isEqual:node.representedObject]) {
                
                [node.children enumerateObjectsUsingBlock:^(QSourceListNode * _Nonnull milestoneNode, NSUInteger idx2, BOOL * _Nonnull stop2) {
                    if ([milestone isEqual:milestoneNode.representedObject]) {
                        foundNode = milestoneNode;
                        foundNode.title = milestone.title;
                        foundNode.representedObject = milestone;
                        node.children[idx2] = foundNode;
                        *stop2 = true;
                    }
                }];
                
                *stop = true;
            }
        }];
    });
    
    if (foundNode != nil && ![self _isShowingFilteredSections]) {
        NSParameterAssert(foundNode.parentNode);
        [self.delegate sourceListDataSource:self didUpdateNode:foundNode];
    }
    
}

- (void)_didRemoveMilestone:(QMilestone *)milestone
{
    if (!self.sections) {
        return;
    }
    
    QSourceListNode *repoSectionNode = [self _repositoriesSectionNode];
    
    if (!repoSectionNode) {
        return;
    }
    
    __block QSourceListNode *foundRepositoryNode = nil;
    __block QSourceListNode *foundNode = nil;
    __block NSUInteger index = NSNotFound;
    dispatch_barrier_sync(self.accessQueue, ^{
        [repoSectionNode.children enumerateObjectsUsingBlock:^(QSourceListNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([milestone.repository isEqual:node.representedObject]) {
                foundRepositoryNode = node;
                [node.children enumerateObjectsUsingBlock:^(QSourceListNode * _Nonnull milestoneNode, NSUInteger idx2, BOOL * _Nonnull stop2) {
                    if ([milestone isEqual:milestoneNode.representedObject]) {
                        foundNode = milestoneNode;
                        index = idx2;
                        *stop2 = true;
                    }
                }];
                
                *stop = true;
            }
        }];
        
        if (index != NSNotFound) {
            NSParameterAssert(foundNode.parentNode);
            [foundNode.parentNode.children removeObjectAtIndex:index];
        }
    });
    
    if (foundNode != nil && ![self _isShowingFilteredSections] ) {
        __block NSUInteger sectionCount = 0;
        dispatch_sync(self.accessQueue, ^{
            sectionCount = [foundRepositoryNode children].count;
        });
        
        NSParameterAssert(foundNode.parentNode);
        [self.delegate sourceListDataSource:self didRemoveNode:foundNode atIndex:index];
        if (sectionCount == 0 && foundRepositoryNode) {
            [self.delegate sourceListDataSource:self didUpdateNode:foundRepositoryNode];
        }
    }
}

#pragma mark - User Query Helpers

- (void)_didInsertUserQuery:(QUserQuery *)userQuery
{
    if (!self.sections) {
        return;
    }
    
    __block QSourceListNode *userQuerySectionNode = [self _userSearchQuerySectionNode];
    
    if (userQuerySectionNode) {
        
        __block QSourceListNode *userQueryNode = nil;
        __block NSInteger index = NSNotFound;
        dispatch_barrier_sync(self.accessQueue, ^{
            userQueryNode = [self _createNodeForUserQuery:userQuery];
            userQueryNode.parentNode = userQuerySectionNode;
            
            index = [userQuerySectionNode.children insertionIndexOf:userQueryNode comparator:^NSComparisonResult(QSourceListNode *obj1, QSourceListNode *obj2) {
                QUserQuery *query1 = (QUserQuery *)obj1.representedObject;
                QUserQuery *query2 = (QUserQuery *)obj2.representedObject;
                return [query1.displayName compare:query2.displayName];
            }];
            
            
            NSParameterAssert([userQuerySectionNode isKindOfClass:QSourceListNode.class]);
            [userQuerySectionNode.children insertObject:userQueryNode atIndex:index];
        });
        
        NSParameterAssert(userQueryNode.parentNode);
        if (![self _isShowingFilteredSections]) {
            [self.delegate sourceListDataSource:self didInsertNode:userQueryNode atIndex:index];
        }
        
    } else {
        NSMutableArray<QUserQuery *> *items = [QUserQueryStore fetchUserQueriesForAccount:self.account];
        userQuerySectionNode = [self _customSearchesNodeWithItems:items];
        
        NSUInteger index = self.sections.count;
        dispatch_barrier_sync(self.accessQueue, ^{
            NSParameterAssert([userQuerySectionNode isKindOfClass:QSourceListNode.class]);
            [self.sections insertObject:userQuerySectionNode atIndex:index];
        });
        
        NSParameterAssert(!userQuerySectionNode.parentNode);
        if (![self _isShowingFilteredSections]) {
            [self.delegate sourceListDataSource:self didInsertNode:userQuerySectionNode atIndex:index];
        }
    }
}

- (void)_didRemoveUserQuery:(QUserQuery *)userQuery
{
    if (!self.sections) {
        return;
    }
    
    __block QSourceListNode *userQuerySectionNode = [self _userSearchQuerySectionNode];
    
    if (!userQuerySectionNode) {
        return;
    }
    
    __block QSourceListNode *foundNode = nil;
    __block NSUInteger index = NSNotFound;
    dispatch_barrier_sync(self.accessQueue, ^{
        [userQuerySectionNode.children enumerateObjectsUsingBlock:^(QSourceListNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([userQuery isEqual:node.representedObject]) {
                foundNode = node;
                index = idx;
                *stop = true;
            }
        }];
        
        if (index != NSNotFound) {
            [userQuerySectionNode.children removeObjectAtIndex:index];
        }
    });
    
    if (foundNode != nil) {
        __block NSUInteger sectionCount = 0;
        __block NSUInteger indexOfSection = NSNotFound;
        dispatch_barrier_sync(self.accessQueue, ^{
            sectionCount = userQuerySectionNode.children.count;
            indexOfSection = [self.sections indexOfObject:userQuerySectionNode];
            
            if (sectionCount == 0) {
                [self.sections removeObjectAtIndex:indexOfSection];
            }
        });
        if (![self _isShowingFilteredSections]) {
            if (sectionCount == 0) {
                NSParameterAssert(!userQuerySectionNode.parentNode);
                [self.delegate sourceListDataSource:self didRemoveNode:userQuerySectionNode atIndex:indexOfSection];
            } else {
                NSParameterAssert(foundNode.parentNode);
                [self.delegate sourceListDataSource:self didRemoveNode:foundNode atIndex:index];
            }
        }
    }
}

#pragma mark - QStoreObserver

- (void)store:(Class)store didInsertRecord:(id<NSObject>)record;
{
    // DDLogDebug(@"SOURCE_LIST: inserting record %@", record);
    if ([record isKindOfClass:QRepository.class]) {
        [self _didInsertRepository:(QRepository *)record];
    } else if ([record isKindOfClass:QUserQuery.class]) {
        [self _didInsertUserQuery:(QUserQuery *)record];
    } else if ([record isKindOfClass:QMilestone.class]) {
        [self _didInsertMilestone:(QMilestone *)record];
    }
    
    if ([self _isShowingFilteredSections]) {
        [self filterNodesUsingText:self.filterText onCompletion:^(NSError *error) {
            [self.delegate reloadTableUsingSourceListDataSource:self];
        }];
    }
}

- (void)store:(Class)store didUpdateRecord:(id<NSObject>)record;
{
    // DDLogDebug(@"SOURCE_LIST: updating record %@", record);
    if ([record isKindOfClass:QRepository.class]) {
        [self _didUpdateRepository:(QRepository *)record];
    } else if ([record isKindOfClass:QUserQuery.class]) {
        [self _didUpdateUserQuery:(QUserQuery *)record];
    } else if ([record isKindOfClass:QMilestone.class]) {
        
        // check if milestone is already in source list
        QSourceListNode *repoSectionNode = [self _repositoriesSectionNode];
        
        if (!repoSectionNode) {
            return;
        }
        
        QMilestone *milestone = (QMilestone *)record;
        __block QSourceListNode *foundNode = nil;
        dispatch_barrier_sync(self.accessQueue, ^{
            [repoSectionNode.children enumerateObjectsUsingBlock:^(QSourceListNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([milestone.repository isEqual:node.representedObject]) {
                    
                    [node.children enumerateObjectsUsingBlock:^(QSourceListNode * _Nonnull milestoneNode, NSUInteger idx2, BOOL * _Nonnull stop2) {
                        if ([milestone isEqual:milestoneNode.representedObject]) {
                            foundNode = milestoneNode;
                            node.children[idx2] = foundNode;
                            *stop2 = true;
                        }
                    }];
                    
                    *stop = true;
                }
            }];
        });
        
        if (foundNode) {
            // if milestone is in the list, then check if it's currently open
            NSArray<QMilestone *> *milestones = [QMilestoneStore openMilestonesForAccountId:milestone.repository.account.identifier repositoryId:milestone.repository.identifier];
            if (![milestones containsObject:milestone]) {
                [self _didRemoveMilestone:milestone];
            }
            
            // otherwise, just update
            else {
                [self _didUpdateMilestone:milestone];
            }
            return;
        }
        
        
        // at this point, this means milestone is actually an insert
        [self _didInsertMilestone:milestone];
        
    }
    
    if ([self _isShowingFilteredSections]) {
        [self filterNodesUsingText:self.filterText onCompletion:^(NSError *error) {
            [self.delegate reloadTableUsingSourceListDataSource:self];
        }];
    }
}

- (void)store:(Class)store didRemoveRecord:(id<NSObject>)record;
{
    DDLogDebug(@"SOURCE_LIST: removing record %@", record);
    if ([record isKindOfClass:QRepository.class]) {
        [self _didRemoveRepository:(QRepository *)record];
    } else if ([record isKindOfClass:QUserQuery.class]) {
        [self _didRemoveUserQuery:(QUserQuery *)record];
    } else if ([record isKindOfClass:QMilestone.class]) {
        [self _didRemoveMilestone:(QMilestone *)record];
    }
    
    if ([self _isShowingFilteredSections]) {
        [self filterNodesUsingText:self.filterText onCompletion:^(NSError *error) {
            [self.delegate reloadTableUsingSourceListDataSource:self];
        }];
    }
}

@end
