//
//  QIssue.m
//  Queues
//
//  Created by Hicham Bouabdallah on 1/8/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import "QIssue.h"
#import "QOwner.h"
#import "QLabel.h"
#import "NSDate+TimeAgo.h"

@implementation QIssue


+ (NSDateFormatter *)_githubDateFormatter
{
    static dispatch_once_t onceToken;
    static NSDateFormatter *formatter;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    });
    return formatter;
}

- (id)copyWithZone:(nullable NSZone *)zone;
{

    QIssue *copy = [QIssue new];
    
    copy.account = self.account;
    copy.repository = self.repository;
    copy.user = self.user;
    copy.assignee = self.assignee;
    copy.milestone = self.milestone;
    copy.labels = self.labels;
    copy.title = self.title;
    copy.number = self.number;
    copy.identifier = self.identifier;
    copy.createdAt = self.createdAt;
    copy.closedAt = self.closedAt;
    copy.updatedAt = self.updatedAt;
    copy.body = self.body;
    copy.state = self.state;
    copy.type = self.type;
    
    return copy;
}

- (NSDictionary *)toExtensionModel
{
    NSMutableDictionary *model = [NSMutableDictionary new];
    model[@"repository"] = [self.repository toExtensionModel];
    model[@"author"] = [self.user toExtensionModel];
    model[@"assignee"] = self.assignee == nil ? NSNull.null : [self.assignee toExtensionModel];
    model[@"milestone"] = self.milestone == nil ? NSNull.null : [self.milestone toExtensionModel];
    
    
    NSMutableArray<NSDictionary *> *labels = [NSMutableArray new];
    [self.labels enumerateObjectsUsingBlock:^(QLabel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [labels addObject:[obj toExtensionModel]];
    }];
    model[@"labels"] = labels.count == 0 ? NSNull.null : labels;
    model[@"title"] = self.title;
    model[@"number"] = self.number;
    model[@"identifier"] = self.identifier;
    model[@"createdAt"] = self.createdAt;
    model[@"updatedAt"] = self.updatedAt ?: NSNull.null;
    model[@"closedAt"] = self.closedAt ?: NSNull.null;
    model[@"body"] = self.body ?: NSNull.null;
    model[@"isOpen"] = @([self.state isEqualToString:@"open"]);
    model[@"type"] = self.type ?: NSNull.null;
    
    return model;
}

+ (instancetype)fromJSON:(NSDictionary *)dict
{
    QIssue *issue = [QIssue new];
    
    issue.title = dict[@"title"];
    issue.number = dict[@"number"];
    issue.user = [QOwner fromJSON:dict[@"user"]];
    if (dict[@"assignee"] && dict[@"assignee"] != [NSNull null]) {
        issue.assignee = [QOwner fromJSON:dict[@"assignee"]];
    }
    
    issue.closedAt = (dict[@"closed_at"] == [NSNull null]) ? nil : [[QIssue _githubDateFormatter] dateFromString:dict[@"closed_at"]];
    issue.updatedAt = (dict[@"updated_at"] == [NSNull null]) ? nil : [[QIssue _githubDateFormatter] dateFromString:dict[@"updated_at"]];
    issue.createdAt = (dict[@"created_at"] == [NSNull null]) ? nil : [[QIssue _githubDateFormatter] dateFromString:dict[@"created_at"]];
    
    if (issue.createdAt == nil || ![issue.createdAt isKindOfClass:NSDate.class]) {
        issue.createdAt = issue.updatedAt ?: issue.closedAt;
    }
    
    issue.body = dict[@"body"] == NSNull.null ? nil : dict[@"body"];
    issue.state = dict[@"state"];
    issue.identifier = dict[@"id"];
    issue.htmlURL = [NSURL URLWithString:dict[@"html_url"]];
    
    NSMutableArray<QLabel *> *labels = [NSMutableArray new];
    NSArray *labelsJSON = dict[@"labels"];
    
    [labelsJSON enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull labelJSON, NSUInteger idx, BOOL * _Nonnull stop) {
        QLabel *label = [QLabel fromJSON:labelJSON];
        [labels addObject:label];
    }];
    
    issue.labels = labels;
    if (dict[@"milestone"] && dict[@"milestone"] != [NSNull null]) {
        issue.milestone = [QMilestone fromJSON:dict[@"milestone"]];
    }
    
    NSDictionary *reactionsDict = dict[@"reactions"];
    if (reactionsDict) {
        issue.thumbsUpCount = [reactionsDict[@"+1"] integerValue];
        issue.thumbsDownCount = [reactionsDict[@"-1"] integerValue];
        issue.laughCount = [reactionsDict[@"laugh"] integerValue];
        issue.confusedCount = [reactionsDict[@"confused"] integerValue];
        issue.heartCount = [reactionsDict[@"heart"] integerValue];
        issue.hoorayCount = [reactionsDict[@"hooray"] integerValue];
    }
    
    issue.type = dict[@"pull_request"] != nil ? @"pull_request" : @"issue";
    
    return issue;
}

- (void)setAccount:(QAccount *)account
{
    if (_account != account) {
        _account = account;
    }
    _repository.account = _account;
    _user.account = _account;
    _assignee.account = _account;
    [_labels enumerateObjectsUsingBlock:^(QLabel * _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
        label.account = _account;
    }];
    
    if (_milestone) {
        _milestone.account = _account;
    }
}

- (void)setRepository:(QRepository *)repository
{
    if (_repository != repository) {
        _repository = repository;
        [_labels enumerateObjectsUsingBlock:^(QLabel * _Nonnull label, NSUInteger idx, BOOL * _Nonnull stop) {
            label.repository = _repository;
        }];
        
        if (_milestone) {
            _milestone.repository = repository;
        }
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@> id=%@ repoId=%@[%@] accountName=%@ _number=%@ title=%@, notication=[%@]",
            NSStringFromClass([self class]), _identifier, _repository.name, _repository.identifier, _account.accountName, _number, _title, _notification];
}

- (BOOL)isEqualToIssue:(QIssue *)issue;
{
    if (issue == nil) {
        return NO;
    }
    
    if (issue == self) {
        return YES;
    }
    
//    DDLogDebug(@"selfRepoId [%@] == issueRepoId [%@] && selfId [%@] = issueId [%@] && selfAccountId [%@] = issueAccountId [%@]",
//          self.repository.identifier,issue.repository.identifier, self.identifier, issue.identifier, self.account.identifier,issue.identifier);
    if ([self.repository.identifier isEqualToNumber:issue.repository.identifier] && [self.identifier isEqualToNumber:issue.identifier] && [self.account.identifier isEqualToNumber:issue.account.identifier]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)isEqual:(id)object
{
    return [self isEqualToIssue:object];
}

- (NSUInteger)hash
{
    return [self.repository.identifier hash] ^ [self.identifier hash] ^ [self.account.identifier hash];
}

#pragma mark - SRIssueDetailItem

- (NSDate *)sortDate {
    return self.createdAt;
}

#pragma mark - QIssueCommentInfo

- (NSNumber *)issueNum
{
    return self.number;
}

- (NSString *)username;
{
    return self.user.login;
}

- (NSDate *)commentedOn;
{
    return self.createdAt;
}

- (NSDate *)commentUpdatedAt {
    return self.updatedAt;
}

- (NSString *)commentBody;
{
    return self.body ?: @"";
}

- (NSURL *)usernameAvatarURL;
{
    return self.user.avatarURL;
}

- (QRepository *)repo
{
    return self.repository;
}

- (NSString *)markdownCacheKey
{
    return [NSString stringWithFormat:@"issue_%@_%@_%@_%@", self.account.identifier, self.repository.identifier, self.identifier, self.updatedAt];
}

- (QOwner *)author
{
    return self.user;
}

- (NSDate *)createdAt {
    return _createdAt ?: NSDate.new;
}

- (NSDate *)updatedAt {
    return _updatedAt ?: NSDate.new;
}

#pragma mark - Temp

- (NSString *)createdAtTimeAgo;
{
    return [([self createdAt] ?: [NSDate dateWithTimeIntervalSince1970:0]) timeAgo];
}

- (NSString *)authorUsername;
{
    return [[self user] login] ?: @"";
}

- (NSString *)repositoryName;
{
    return [[self repository] name] ?: @"";
}

- (NSString *)milestoneTitle;
{
    return [[self milestone] title] ?: @"";
}

@end
