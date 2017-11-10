//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

// #import <MASShortcut/Shortcut.h>
#import <QuartzCore/QuartzCore.h>
#import "QView.h"
#import "NSDate+TimeAgo.h"
#import "QIssue.h"
#import "QView+ImageManager.h"
#import "QMilestone.h"
#import "QLabel.h"
#import "QOwner.h"
#import "QAccountStore.h"
#import "QMilestoneStore.h"
#import "QLabelStore.h"
#import "QOwnerStore.h"
#import "QRepository.h"
#import "QRepositoryStore.h"
#import "QImageManager.h"
#import "NSImage+Common.h"
#import "QRepositoriesService.h"
#import "QUserService.h"
#import "QIssuesService.h"
#import "QContext.h"
#import "QPagination.h"
#import "QIssueFilter.h"
#import "QIssueStore.h"
#import "QLabelStore.h"
#import "QIssueConstants.h"
#import "QCommonConstants.h"
#import "NSColor+Hex.h"
#import "NSMutableAttributedString+Trimmer.h"
#import "QIssueEventStore.h"
#import "QIssueCommentStore.h"
#import "NSColor+Hex.h"
#import <limits.h>
#import <hoedown/html.h>
#import <hoedown/document.h>
#import "MarkdownParser.h"
#import "AppDelegate.h"
#import "QIssueSync.h"
#ifndef DEBUG
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#endif

#import <Crashlytics/Answers.h>
#import "QIssueMarkdownWebView.h"
#import "SRTrie.h"
#import "SRIssueDetailItem.h"
#import <AFNetworking/AFNetworking.h>
#import <CommonCrypto/CommonCrypto.h>
#import "QUserQueryStore.h"
#import "SRNotificationService.h"
#import "QIssueNotificationStore.h"
#import "QIssueCommentDraftStore.h"
#import "QIssueFavoriteStore.h"
#import "SRExtension.h"
#import "SRExtensionStore.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <CocoaLumberJack/DDContextFilterLogFormatter.h>
#import "SRIssueReaction.h"
#import "SRIssueCommentReaction.h"
#import "SRIssueReactionStore.h"
#import "SRIssueCommentReactionStore.h"

#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel ddLogLevel = DDLogLevelWarning;
#endif
