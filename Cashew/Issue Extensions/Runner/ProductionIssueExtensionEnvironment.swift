//
//  ProductionIssueExtensionEnvironment.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/6/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa
import JavaScriptCore

@objc(SRIssueExtensionLogFileManagerDefault)
class IssueExtensionLogFileManagerDefault: DDLogFileManagerDefault {
    //    let timestampFormatter: NSDateFormatter  = {
    //        let formatter = NSDateFormatter()
    //        formatter.dateFormat = "YYYY.MM.dd" //-HH.mm.ss"
    //
    //        return formatter
    //    }()
    
    override var newLogFileName: String!  {
        let appName = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleIdentifier");
        //let timestamp = timestampFormatter.stringFromDate(NSDate())
        return "\(appName!)-CodeExtensions.log"
    }
    
    override func isLogFile(fileName: String!) -> Bool {
        return false
    }
    
}

@objc(SRProductionIssueExtensionEnvironment)
class ProductionIssueExtensionEnvironment: NSObject, CodeExtensionEnvironmentProtocol {
    
    private var consoleLogDateFormatter: NSDateFormatter = {
        let consoleLogDateFormatter = NSDateFormatter()
        consoleLogDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return consoleLogDateFormatter
    }()
    
    private static let codeExtensionLogContext: Int = 7654
    private let operationQueue = NSOperationQueue()
    
    required override init() {
        super.init()
        
        operationQueue.name = "co.cashewapp.ProductionIssueExtensionEnvironment"
        operationQueue.maxConcurrentOperationCount = 3
        
        let logFileManager = IssueExtensionLogFileManagerDefault(logsDirectory: DDLogFileManagerDefault().logsDirectory());
        let contextFormatter = DDContextWhitelistFilterLogFormatter()
        let fileLogger: DDFileLogger = DDFileLogger(logFileManager: logFileManager)
        
        contextFormatter.addToWhitelist(UInt(ProductionIssueExtensionEnvironment.codeExtensionLogContext))
        
        //fileLogger.rollingFrequency = 60*60*24  // 24 hours
        //fileLogger.logFileManager.maximumNumberOfLogFiles = 10
        fileLogger.rollingFrequency = 0
        fileLogger.maximumFileSize = 0
        fileLogger.logFormatter = contextFormatter
        
        
        DDLog.addLogger(fileLogger)
    }
    
    func consoleLog(arguments: [AnyObject], logLevel: LogLevel) {
        let str = arguments.map({"\($0)"}).joinWithSeparator(" ")
        let date = consoleLogDateFormatter.stringFromDate(NSDate())
        ExtensionLogInfo("\(date) [LOG] \(str)\n")
    }
    
    func exceptionLog(line: String, column: String, stacktrace: String, exception: String) {
        let str = "Line: \(line) Column: \(column) Method: \(stacktrace) - \(exception)"
        ExtensionLogInfo("\(NSDate()) [EXCEPTION] \(str)\n")
    }
    
    func writeToPasteboard(str: String) {
        NSPasteboard.generalPasteboard().declareTypes([NSStringPboardType], owner: nil)
        NSPasteboard.generalPasteboard().setString(str, forType: NSStringPboardType)
    }
    
    func ExtensionLogInfo(@autoclosure message: () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = ProductionIssueExtensionEnvironment.codeExtensionLogContext, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = true, ddlog: DDLog = DDLog.sharedInstance()) {
        _DDLogMessage(message, level: level, flag: .Info, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
    }
}


extension ProductionIssueExtensionEnvironment: MilestoneServiceExtensionEnvironmentProtocol {
    
    func milestonesForRepository(repository: NSDictionary, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateRepository(repository) else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Repository specified" ])
            return;
        }
        
        let account = QContext.sharedContext().currentAccount
        guard let repositoryId = repository["identifier"] as? NSNumber else {
            onCompletion.callWithArguments([ NSNull(), "Missing repository parameter" ])
            return
        }
        let milestones = QMilestoneStore.milestonesForAccountId(account.identifier, repositoryId: repositoryId, includeHidden: false)
        onCompletion.callWithArguments([ milestones.flatMap({ $0.toExtensionModel() }), NSNull() ])
    }
    
}

extension ProductionIssueExtensionEnvironment: OwnerServiceExtensionEnvironmentProtocol {
    
    func usersForRepository(repository: NSDictionary, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateRepository(repository) else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Repository specified" ])
            return;
        }
        
        let account = QContext.sharedContext().currentAccount
        guard let repositoryId = repository["identifier"] as? NSNumber else {
            onCompletion.callWithArguments([ NSNull(), "Missing repository parameter" ])
            return
        }
        let owners = QOwnerStore.ownersForAccountId(account.identifier, repositoryId: repositoryId)
        onCompletion.callWithArguments([ owners.flatMap({ $0.toExtensionModel() }), NSNull() ])
    }
    
}

extension ProductionIssueExtensionEnvironment: LabelServiceExtensionEnvironmentProtocol {
    
    func labelsForRepository(repository: NSDictionary, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateRepository(repository) else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Repository specified" ])
            return;
        }
        
        let account = QContext.sharedContext().currentAccount
        guard let repositoryId = repository["identifier"] as? NSNumber else {
            onCompletion.callWithArguments([ NSNull(), "Missing repository parameter" ])
            return
        }
        let labels = QLabelStore.labelsForAccountId(account.identifier, repositoryId: repositoryId, includeHidden: false)
        onCompletion.callWithArguments([ labels.flatMap({ $0.toExtensionModel() }), NSNull() ])
    }
    
}

extension ProductionIssueExtensionEnvironment: IssueServiceExtensionEnvironmentProtocol {
    
    func closeIssue(issue: NSDictionary, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Issue Specified" ])
            return
        }
        
        let currentAccount = QContext.sharedContext().currentAccount
        guard let repositoryHash = issue["repository"] as? [NSObject: AnyObject], repositoryId = repositoryHash["identifier"] as? NSNumber,
            repository = QRepositoryStore.repositoryForAccountId(currentAccount.identifier, identifier: repositoryId),
            issueNumber = issue["number"] as? NSNumber else {
                onCompletion.callWithArguments([ NSNull(),  "Invalid Issue Specified" ])
                return;
        }
        
        let service = QIssuesService(forAccount: currentAccount)
        operationQueue.addOperationWithBlock { 
            let semaphore = dispatch_semaphore_create(0)
            service.closeIssueForRepository(repository, number: issueNumber) { (updateIssue, context, err) in
                if let updateIssue = updateIssue as? QIssue where err == nil {
                    QIssueStore.saveIssue(updateIssue)
                    onCompletion.callWithArguments([ updateIssue.toExtensionModel(), NSNull() ])
                } else if let err = err {
                    onCompletion.callWithArguments([ NSNull(), "\(err)" ])
                } else {
                    onCompletion.callWithArguments([ NSNull(), "Unable to close issue" ])
                }
                dispatch_semaphore_signal(semaphore)
            }
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        }

    }
    
    func openIssue(issue: NSDictionary, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Issue Specified" ])
            return
        }
        
        let currentAccount = QContext.sharedContext().currentAccount
        guard let repositoryHash = issue["repository"] as? [NSObject: AnyObject], repositoryId = repositoryHash["identifier"] as? NSNumber,
            repository = QRepositoryStore.repositoryForAccountId(currentAccount.identifier, identifier: repositoryId),
            issueNumber = issue["number"] as? NSNumber else {
                onCompletion.callWithArguments([ NSNull(), "Invalid Issue Specified" ])
                return;
        }
        
        let service = QIssuesService(forAccount: currentAccount)
        
        operationQueue.addOperationWithBlock {
            let semaphore = dispatch_semaphore_create(0)
            service.reopenIssueForRepository(repository, number: issueNumber) { (updateIssue, context, err) in
                if let updateIssue = updateIssue as? QIssue where err == nil {
                    QIssueStore.saveIssue(updateIssue)
                    onCompletion.callWithArguments([ updateIssue.toExtensionModel(), NSNull() ])
                } else if let err = err {
                    onCompletion.callWithArguments([ NSNull(), "\(err)" ])
                } else {
                    onCompletion.callWithArguments([ NSNull(), "Unable to reopen issue" ])
                }
                dispatch_semaphore_signal(semaphore)
            }
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        }
    }
    
    func assignMilestoneToIssue(issue: NSDictionary, milestone: NSDictionary?, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) && ( milestone == nil || CodeExtensionModelValidators.validateMilestone(milestone)) else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Parameters Specified" ])
            return
        }
        
        let currentAccount = QContext.sharedContext().currentAccount
        
        guard let repositoryHash = issue["repository"] as? [NSObject: AnyObject],
            repositoryId = repositoryHash["identifier"] as? NSNumber,
            repository = QRepositoryStore.repositoryForAccountId(currentAccount.identifier, identifier: repositoryId),
            issueNumber = issue["number"] as? NSNumber else {
                onCompletion.callWithArguments([ NSNull(), "Invalid Issue Specified" ])
                return
        }
        
        let service = QIssuesService(forAccount: currentAccount)
        
    
        operationQueue.addOperationWithBlock {
            let semaphore = dispatch_semaphore_create(0)
            
            service.saveMilestoneNumber(milestone?["number"] as? NSNumber, forRepository: repository, number: issueNumber) { (updateIssue, context, err) in
                if let updateIssue = updateIssue as? QIssue where err == nil {
                    QIssueStore.saveIssue(updateIssue)
                    onCompletion.callWithArguments([ updateIssue.toExtensionModel(), NSNull() ])
                } else if let err = err {
                    onCompletion.callWithArguments([ NSNull(), "\(err)" ])
                } else {
                    onCompletion.callWithArguments([ NSNull(), "Unable to assign milestone to issue"])
                }
                dispatch_semaphore_signal(semaphore)
            }
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        }
        
    }
    
    func assignUserToIssue(issue: NSDictionary, user: NSDictionary?, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) && ( user == nil || CodeExtensionModelValidators.validateOwner(user))  else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Parameters Specified" ])
            return
        }
        
        let currentAccount = QContext.sharedContext().currentAccount
        
        guard let repositoryHash = issue["repository"] as? [NSObject: AnyObject],
            repositoryId = repositoryHash["identifier"] as? NSNumber,
            repository = QRepositoryStore.repositoryForAccountId(currentAccount.identifier, identifier: repositoryId),
            issueNumber = issue["number"] as? NSNumber else {
                onCompletion.callWithArguments([ NSNull(), "Invalid Issue Specified" ])
                return
        }
        
        let service = QIssuesService(forAccount: currentAccount)
        
        operationQueue.addOperationWithBlock {
            let semaphore = dispatch_semaphore_create(0)
            
            service.saveAssigneeLogin(user?["login"] as? String, forRepository: repository, number: issueNumber) { (updateIssue, context, err) in
                if let updateIssue = updateIssue as? QIssue where err == nil {
                    QIssueStore.saveIssue(updateIssue)
                    onCompletion.callWithArguments([ updateIssue.toExtensionModel(), NSNull() ])
                } else if let err = err {
                    onCompletion.callWithArguments([ NSNull(), "\(err)" ])
                } else {
                    onCompletion.callWithArguments([ NSNull(), "Unable to assign user to issue"])
                }
                dispatch_semaphore_signal(semaphore)
            }
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        }
    }
    
    func assignLabelsToIssue(issue: NSDictionary, labels: NSArray?, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) && ( labels == nil || CodeExtensionModelValidators.validateLabels(labels))  else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Parameters Specified" ])
            return
        }
        
        let currentAccount = QContext.sharedContext().currentAccount
        
        guard let repositoryHash = issue["repository"] as? [NSObject: AnyObject],
            repositoryId = repositoryHash["identifier"] as? NSNumber,
            repository = QRepositoryStore.repositoryForAccountId(currentAccount.identifier, identifier: repositoryId),
            issueNumber = issue["number"] as? NSNumber else {
                onCompletion.callWithArguments([ NSNull(), "Invalid Issue Specified" ])
                return
        }
        
        let labelNames: [String] = (labels == nil) ? [String]() : labels!.flatMap({ (item) in
            if let label = item as? NSDictionary, name = label["name"] as? String {
                return name
            }
            return nil
        })
        
        let service = QIssuesService(forAccount: currentAccount)
        
        operationQueue.addOperationWithBlock {
            let semaphore = dispatch_semaphore_create(0)

            service.saveLabels(labelNames, forRepository: repository, issueNumber: issueNumber) { (updateIssue, context, err) in
                if let updateIssue = updateIssue as? QIssue where err == nil {
                    QIssueStore.saveIssue(updateIssue)
                    onCompletion.callWithArguments([ updateIssue.toExtensionModel(), NSNull() ])
                } else if let err = err {
                    onCompletion.callWithArguments([ NSNull(), "\(err)" ])
                } else {
                    onCompletion.callWithArguments([ NSNull(), "Unable to assign labels to issue"])
                }
                dispatch_semaphore_signal(semaphore)
            }
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        }
    }
    
    func createIssueComment(issue: NSDictionary, comment: String, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Issue Specified" ])
            return
        }
        
        let currentAccount = QContext.sharedContext().currentAccount
        
        guard let repositoryHash = issue["repository"] as? [NSObject: AnyObject],
            repositoryId = repositoryHash["identifier"] as? NSNumber,
            repository = QRepositoryStore.repositoryForAccountId(currentAccount.identifier, identifier: repositoryId),
            issueNumber = issue["number"] as? NSNumber else {
                onCompletion.callWithArguments([ NSNull(), "Invalid Issue Specified" ])
                return
        }
        
        let service = QIssuesService(forAccount: currentAccount)
        operationQueue.addOperationWithBlock {
            let semaphore = dispatch_semaphore_create(0)
            
            service.createCommentForRepository(repository, issueNumber: issueNumber, body: comment) { (issueComment, context, err) in
                if let issueComment = issueComment as? QIssueComment where err == nil {
                    QIssueCommentStore.saveIssueComment(issueComment)
                    onCompletion.callWithArguments([ issueComment.toExtensionModel(), NSNull() ])
                } else if let err = err {
                    onCompletion.callWithArguments([ NSNull(), "\(err)" ])
                } else {
                    onCompletion.callWithArguments([ NSNull(), "Unable to create comment on issue"])
                }
                dispatch_semaphore_signal(semaphore)
            }
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        }
    }
    
    func saveIssueTitle(issue: NSDictionary, title: String, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Issue Specified" ])
            return
        }
        
        let currentAccount = QContext.sharedContext().currentAccount
        
        guard let repositoryHash = issue["repository"] as? [NSObject: AnyObject],
            repositoryId = repositoryHash["identifier"] as? NSNumber,
            repository = QRepositoryStore.repositoryForAccountId(currentAccount.identifier, identifier: repositoryId),
            issueNumber = issue["number"] as? NSNumber else {
                onCompletion.callWithArguments([ NSNull(), "Invalid Issue Specified" ])
                return
        }
        
        let service = QIssuesService(forAccount: currentAccount)
        operationQueue.addOperationWithBlock {
            let semaphore = dispatch_semaphore_create(0)
            
            service.saveIssueTitle(title, forRepository: repository, number: issueNumber) { (updateIssue, context, err) in
                if let updateIssue = updateIssue as? QIssue where err == nil {
                    QIssueStore.saveIssue(updateIssue)
                    onCompletion.callWithArguments([ updateIssue.toExtensionModel(), NSNull() ])
                } else if let err = err {
                    onCompletion.callWithArguments([ NSNull(), "\(err)" ])
                } else {
                    onCompletion.callWithArguments([ NSNull(), "Unable to update issue title"])
                }
                dispatch_semaphore_signal(semaphore)
            }
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        }
    }
    
    func saveIssueBody(issue: NSDictionary, body: String?, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) else {
            onCompletion.callWithArguments([ NSNull(), "Invalid Issue Specified" ])
            return
        }
        
        let currentAccount = QContext.sharedContext().currentAccount
        
        guard let repositoryHash = issue["repository"] as? [NSObject: AnyObject],
            repositoryId = repositoryHash["identifier"] as? NSNumber,
            repository = QRepositoryStore.repositoryForAccountId(currentAccount.identifier, identifier: repositoryId),
            issueNumber = issue["number"] as? NSNumber else {
                onCompletion.callWithArguments([ NSNull(), "Invalid Issue Specified" ])
                return
        }
        
        let service = QIssuesService(forAccount: currentAccount)
        operationQueue.addOperationWithBlock {
            let semaphore = dispatch_semaphore_create(0)
            
            service.saveIssueBody(body ?? "", forRepository: repository, number: issueNumber) { (updateIssue, context, err) in
                if let updateIssue = updateIssue as? QIssue where err == nil {
                    QIssueStore.saveIssue(updateIssue)
                    onCompletion.callWithArguments([ updateIssue.toExtensionModel(), NSNull() ])
                } else if let err = err {
                    onCompletion.callWithArguments([ NSNull(), "\(err)" ])
                } else {
                    onCompletion.callWithArguments([ NSNull(), "Unable to update issue description"])
                }
                dispatch_semaphore_signal(semaphore)
            }
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        }
    }
    
}

