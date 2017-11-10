//
//  QCommonConstants.h
//  Issues
//
//  Created by Hicham Bouabdallah on 2/3/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

#import <Foundation/Foundation.h>

//extern NSString * const kQSourceListInsertedMilestoneNotification;
//extern NSString * const kQSourceListInsertedRepositoryNotification;
extern NSString * const kQWindowWillStartLiveNotificationNotification;
extern NSString * const kQWindowDidEndLiveNotificationNotification;

extern NSString * const kQCreateIssueNotification;

extern NSString * const kQForceLoginNotification;

extern NSString * const kOpenNewIssueDetailsWindowNotification;

extern NSString * const kQShowLabelPickerNotification;
extern NSString * const kQShowMilestonePickerNotification;
extern NSString * const kQShowAssigneePickerNotification;

extern NSString * const kWillStartSynchingRepositoryNotification;
extern NSString * const kDidFinishSynchingRepositoryNotification;

extern NSString * const kShowSaveSearchDisplayNamePopoverNotification;

extern NSString * const kSRShowAddAccountNotification;

extern NSString * const kSRShowImageViewerNotification;


extern NSString * const kWillStartDeltaIssueSynchingNotification;
extern NSString * const kDidFinishDeltaIssueSynchingNotification;
extern NSString * const kWillStartFullIssueSynchingNotification;
extern NSString * const kDidFinishFullIssueSynchingNotification;

extern NSString * const kDidBecomeFirstResponderNotification;

@interface QCommonConstants : NSObject

@end
