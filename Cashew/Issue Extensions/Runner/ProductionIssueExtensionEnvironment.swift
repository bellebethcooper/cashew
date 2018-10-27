//
//  ProductionIssueExtensionEnvironment.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/6/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa
import JavaScriptCore

//(SRIssueExtensionLogFileManagerDefault)
class IssueExtensionLogFileManagerDefault: DDLogFileManagerDefault {
    //    let timestampFormatter: NSDateFormatter  = {
    //        let formatter = NSDateFormatter()
    //        formatter.dateFormat = "YYYY.MM.dd" //-HH.mm.ss"
    //
    //        return formatter
    //    }()
    
    override var newLogFileName: String!  {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier");
        //let timestamp = timestampFormatter.stringFromDate(NSDate())
        return "\(appName!)-CodeExtensions.log"
    }
    
    override func isLogFile(withName fileName: String!) -> Bool {
        return false
    }
    
}

@objc(SRProductionIssueExtensionEnvironment)
class ProductionIssueExtensionEnvironment: NSObject, CodeExtensionEnvironmentProtocol {
    
    fileprivate var consoleLogDateFormatter: DateFormatter = {
        let consoleLogDateFormatter = DateFormatter()
        consoleLogDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return consoleLogDateFormatter
    }()
    
    fileprivate static let codeExtensionLogContext: Int = 7654
    fileprivate let operationQueue = OperationQueue()
    
    required override init() {
        super.init()
        
        operationQueue.name = "co.cashewapp.ProductionIssueExtensionEnvironment"
        operationQueue.maxConcurrentOperationCount = 3
        
        let logFileManager = IssueExtensionLogFileManagerDefault(logsDirectory: DDLogFileManagerDefault().logsDirectory);
//        let contextFormatter = DDContextWhitelistFilterLogFormatter()
        let fileLogger: DDFileLogger = DDFileLogger(logFileManager: logFileManager)
        
//        contextFormatter.addToWhitelist(UInt(ProductionIssueExtensionEnvironment.codeExtensionLogContext))
        
        //fileLogger.rollingFrequency = 60*60*24  // 24 hours
        //fileLogger.logFileManager.maximumNumberOfLogFiles = 10
        fileLogger.rollingFrequency = 0
        fileLogger.maximumFileSize = 0
//        fileLogger.logFormatter = contextFormatter
        
        
        DDLog.add(fileLogger)
    }
    
    func consoleLog(_ arguments: [AnyObject], logLevel: LogLevel) {
        let str = arguments.map({"\($0)"}).joined(separator: " ")
        let date = consoleLogDateFormatter.string(from: Date())
        ExtensionLogInfo("\(date) [LOG] \(str)\n")
    }
    
    func exceptionLog(_ line: String, column: String, stacktrace: String, exception: String) {
        let str = "Line: \(line) Column: \(column) Method: \(stacktrace) - \(exception)"
        ExtensionLogInfo("\(Date()) [EXCEPTION] \(str)\n")
    }
    
    func writeToPasteboard(_ str: String) {
        NSPasteboard.general.declareTypes([.string], owner: nil)
        NSPasteboard.general.setString(str, forType: .string)
    }
    
    func ExtensionLogInfo(_ message: @autoclosure () -> String, level: DDLogLevel = defaultDebugLevel, context: Int = ProductionIssueExtensionEnvironment.codeExtensionLogContext, file: StaticString = #file, function: StaticString = #function, line: UInt = #line, tag: AnyObject? = nil, asynchronous async: Bool = true, ddlog: DDLog = DDLog.sharedInstance) {
        _DDLogMessage(message, level: level, flag: .info, context: context, file: file, function: function, line: line, tag: tag, asynchronous: async, ddlog: ddlog)
    }
}


extension ProductionIssueExtensionEnvironment: MilestoneServiceExtensionEnvironmentProtocol {
    
    func milestonesForRepository(_ repository: NSDictionary, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateRepository(repository) else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Repository specified" ])
            return;
        }
        
        let account = QContext.shared().currentAccount
        guard let repositoryId = repository["identifier"] as? NSNumber else {
            onCompletion.call(withArguments: [ NSNull(), "Missing repository parameter" ])
            return
        }
        let milestones = QMilestoneStore.milestones(forAccountId: account?.identifier, repositoryId: repositoryId, includeHidden: false)
        onCompletion.call(withArguments: milestones?.flatMap( { $0.toExtensionModel() }))
    }
    
}

extension ProductionIssueExtensionEnvironment: OwnerServiceExtensionEnvironmentProtocol {
    
    func usersForRepository(_ repository: NSDictionary, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateRepository(repository) else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Repository specified" ])
            return;
        }
        
        let account = QContext.shared().currentAccount
        guard let repositoryId = repository["identifier"] as? NSNumber else {
            onCompletion.call(withArguments: [ NSNull(), "Missing repository parameter" ])
            return
        }
        let owners = QOwnerStore.owners(forAccountId: account?.identifier, repositoryId: repositoryId)
        onCompletion.call(withArguments: owners?.flatMap({ $0.toExtensionModel() }))
    }
    
}

extension ProductionIssueExtensionEnvironment: LabelServiceExtensionEnvironmentProtocol {
    
    func labelsForRepository(_ repository: NSDictionary, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateRepository(repository) else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Repository specified" ])
            return;
        }
        
        let account = QContext.shared().currentAccount
        guard let repositoryId = repository["identifier"] as? NSNumber else {
            onCompletion.call(withArguments: [ NSNull(), "Missing repository parameter" ])
            return
        }
        let labels = QLabelStore.labels(forAccountId: account?.identifier, repositoryId: repositoryId, includeHidden: false)
        onCompletion.call(withArguments: labels?.flatMap({ $0.toExtensionModel() }))
    }
    
}

extension ProductionIssueExtensionEnvironment: IssueServiceExtensionEnvironmentProtocol {
    
    func closeIssue(_ issue: NSDictionary, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Issue Specified" ])
            return
        }
        
        let currentAccount = QContext.shared().currentAccount
        guard let repositoryHash = issue["repository"] as? [AnyHashable: Any], let repositoryId = repositoryHash["identifier"] as? NSNumber,
            let repository = QRepositoryStore.repository(forAccountId: currentAccount?.identifier, identifier: repositoryId),
            let issueNumber = issue["number"] as? NSNumber else {
                onCompletion.call(withArguments: [ NSNull(),  "Invalid Issue Specified" ])
                return;
        }
        
        let service = QIssuesService(for: currentAccount!)
        operationQueue.addOperation { 
            let semaphore = DispatchSemaphore(value: 0)
            service.closeIssue(for: repository, number: issueNumber) { (updateIssue, context, err) in
                if let updateIssue = updateIssue as? QIssue , err == nil {
                    QIssueStore.save(updateIssue)
                    onCompletion.call(withArguments: [ updateIssue.toExtensionModel(), NSNull() ])
                } else if let err = err {
                    onCompletion.call(withArguments: [ NSNull(), "\(err)" ])
                } else {
                    onCompletion.call(withArguments: [ NSNull(), "Unable to close issue" ])
                }
                semaphore.signal()
            }
            
            semaphore.wait(timeout: DispatchTime.distantFuture)
        }

    }
    
    func openIssue(_ issue: NSDictionary, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Issue Specified" ])
            return
        }
        
        let currentAccount = QContext.shared().currentAccount
        guard let repositoryHash = issue["repository"] as? [AnyHashable: Any], let repositoryId = repositoryHash["identifier"] as? NSNumber,
            let repository = QRepositoryStore.repository(forAccountId: currentAccount?.identifier, identifier: repositoryId),
            let issueNumber = issue["number"] as? NSNumber else {
                onCompletion.call(withArguments: [ NSNull(), "Invalid Issue Specified" ])
                return;
        }
        
        let service = QIssuesService(for: currentAccount!)
        
        operationQueue.addOperation {
            let semaphore = DispatchSemaphore(value: 0)
            service.reopenIssue(for: repository, number: issueNumber) { (updateIssue, context, err) in
                if let updateIssue = updateIssue as? QIssue , err == nil {
                    QIssueStore.save(updateIssue)
                    onCompletion.call(withArguments: [ updateIssue.toExtensionModel(), NSNull() ])
                } else if let err = err {
                    onCompletion.call(withArguments: [ NSNull(), "\(err)" ])
                } else {
                    onCompletion.call(withArguments: [ NSNull(), "Unable to reopen issue" ])
                }
                semaphore.signal()
            }
            
            semaphore.wait(timeout: DispatchTime.distantFuture)
        }
    }
    
    func assignMilestoneToIssue(_ issue: NSDictionary, milestone: NSDictionary?, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) && ( milestone == nil || CodeExtensionModelValidators.validateMilestone(milestone)) else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Parameters Specified" ])
            return
        }
        
        let currentAccount = QContext.shared().currentAccount
        
        guard let repositoryHash = issue["repository"] as? [AnyHashable: Any],
            let repositoryId = repositoryHash["identifier"] as? NSNumber,
            let repository = QRepositoryStore.repository(forAccountId: currentAccount?.identifier, identifier: repositoryId),
            let issueNumber = issue["number"] as? NSNumber else {
                onCompletion.call(withArguments: [ NSNull(), "Invalid Issue Specified" ])
                return
        }
        
        let service = QIssuesService(for: currentAccount!)
        
    
        operationQueue.addOperation {
            let semaphore = DispatchSemaphore(value: 0)
            
            service.saveMilestoneNumber(milestone?["number"] as? NSNumber, for: repository, number: issueNumber) { (updateIssue, context, err) in
                if let updateIssue = updateIssue as? QIssue , err == nil {
                    QIssueStore.save(updateIssue)
                    onCompletion.call(withArguments: [ updateIssue.toExtensionModel(), NSNull() ])
                } else if let err = err {
                    onCompletion.call(withArguments: [ NSNull(), "\(err)" ])
                } else {
                    onCompletion.call(withArguments: [ NSNull(), "Unable to assign milestone to issue"])
                }
                semaphore.signal()
            }
            
            semaphore.wait(timeout: DispatchTime.distantFuture)
        }
        
    }
    
    func assignUserToIssue(_ issue: NSDictionary, user: NSDictionary?, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) && ( user == nil || CodeExtensionModelValidators.validateOwner(user))  else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Parameters Specified" ])
            return
        }
        
        let currentAccount = QContext.shared().currentAccount
        
        guard let repositoryHash = issue["repository"] as? [AnyHashable: Any],
            let repositoryId = repositoryHash["identifier"] as? NSNumber,
            let repository = QRepositoryStore.repository(forAccountId: currentAccount?.identifier, identifier: repositoryId),
            let issueNumber = issue["number"] as? NSNumber else {
                onCompletion.call(withArguments: [ NSNull(), "Invalid Issue Specified" ])
                return
        }
        
        let service = QIssuesService(for: currentAccount!)
        
        operationQueue.addOperation {
            let semaphore = DispatchSemaphore(value: 0)
            
            service.saveAssigneeLogin(user?["login"] as? String, for: repository, number: issueNumber) { (updateIssue, context, err) in
                if let updateIssue = updateIssue as? QIssue , err == nil {
                    QIssueStore.save(updateIssue)
                    onCompletion.call(withArguments: [ updateIssue.toExtensionModel(), NSNull() ])
                } else if let err = err {
                    onCompletion.call(withArguments: [ NSNull(), "\(err)" ])
                } else {
                    onCompletion.call(withArguments: [ NSNull(), "Unable to assign user to issue"])
                }
                semaphore.signal()
            }
            
            semaphore.wait(timeout: DispatchTime.distantFuture)
        }
    }
    
    func assignLabelsToIssue(_ issue: NSDictionary, labels: NSArray?, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) && ( labels == nil || CodeExtensionModelValidators.validateLabels(labels))  else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Parameters Specified" ])
            return
        }
        
        let currentAccount = QContext.shared().currentAccount
        
        guard let repositoryHash = issue["repository"] as? [AnyHashable: Any],
            let repositoryId = repositoryHash["identifier"] as? NSNumber,
            let repository = QRepositoryStore.repository(forAccountId: currentAccount?.identifier, identifier: repositoryId),
            let issueNumber = issue["number"] as? NSNumber else {
                onCompletion.call(withArguments: [ NSNull(), "Invalid Issue Specified" ])
                return
        }
        
        let labelNames: [String] = (labels == nil) ? [String]() : labels!.flatMap({ (item) in
            if let label = item as? NSDictionary, let name = label["name"] as? String {
                return name
            }
            return nil
        })
        
        let service = QIssuesService(for: currentAccount!)
        
        operationQueue.addOperation {
            let semaphore = DispatchSemaphore(value: 0)

            service.saveLabels(labelNames, for: repository, issueNumber: issueNumber) { (updateIssue, context, err) in
                if let updateIssue = updateIssue as? QIssue , err == nil {
                    QIssueStore.save(updateIssue)
                    onCompletion.call(withArguments: [ updateIssue.toExtensionModel(), NSNull() ])
                } else if let err = err {
                    onCompletion.call(withArguments: [ NSNull(), "\(err)" ])
                } else {
                    onCompletion.call(withArguments: [ NSNull(), "Unable to assign labels to issue"])
                }
                semaphore.signal()
            }
            
            semaphore.wait(timeout: DispatchTime.distantFuture)
        }
    }
    
    func createIssueComment(_ issue: NSDictionary, comment: String, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Issue Specified" ])
            return
        }
        
        let currentAccount = QContext.shared().currentAccount
        
        guard let repositoryHash = issue["repository"] as? [AnyHashable: Any],
            let repositoryId = repositoryHash["identifier"] as? NSNumber,
            let repository = QRepositoryStore.repository(forAccountId: currentAccount?.identifier, identifier: repositoryId),
            let issueNumber = issue["number"] as? NSNumber else {
                onCompletion.call(withArguments: [ NSNull(), "Invalid Issue Specified" ])
                return
        }
        
        let service = QIssuesService(for: currentAccount!)
        operationQueue.addOperation {
            let semaphore = DispatchSemaphore(value: 0)
            
            service.createComment(for: repository, issueNumber: issueNumber, body: comment) { (issueComment, context, err) in
                if let issueComment = issueComment as? QIssueComment , err == nil {
                    QIssueCommentStore.save(issueComment)
                    onCompletion.call(withArguments: [ issueComment.toExtensionModel(), NSNull() ])
                } else if let err = err {
                    onCompletion.call(withArguments: [ NSNull(), "\(err)" ])
                } else {
                    onCompletion.call(withArguments: [ NSNull(), "Unable to create comment on issue"])
                }
                semaphore.signal()
            }
            
            semaphore.wait(timeout: DispatchTime.distantFuture)
        }
    }
    
    func saveIssueTitle(_ issue: NSDictionary, title: String, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Issue Specified" ])
            return
        }
        
        let currentAccount = QContext.shared().currentAccount
        
        guard let repositoryHash = issue["repository"] as? [AnyHashable: Any],
            let repositoryId = repositoryHash["identifier"] as? NSNumber,
            let repository = QRepositoryStore.repository(forAccountId: currentAccount?.identifier, identifier: repositoryId),
            let issueNumber = issue["number"] as? NSNumber else {
                onCompletion.call(withArguments: [ NSNull(), "Invalid Issue Specified" ])
                return
        }
        
        let service = QIssuesService(for: currentAccount!)
        operationQueue.addOperation {
            let semaphore = DispatchSemaphore(value: 0)
            
            service.saveIssueTitle(title, for: repository, number: issueNumber) { (updateIssue, context, err) in
                if let updateIssue = updateIssue as? QIssue , err == nil {
                    QIssueStore.save(updateIssue)
                    onCompletion.call(withArguments: [ updateIssue.toExtensionModel(), NSNull() ])
                } else if let err = err {
                    onCompletion.call(withArguments: [ NSNull(), "\(err)" ])
                } else {
                    onCompletion.call(withArguments: [ NSNull(), "Unable to update issue title"])
                }
                semaphore.signal()
            }
            
            semaphore.wait(timeout: DispatchTime.distantFuture)
        }
    }
    
    func saveIssueBody(_ issue: NSDictionary, body: String?, onCompletion: JSValue) {
        guard CodeExtensionModelValidators.validateIssue(issue) else {
            onCompletion.call(withArguments: [ NSNull(), "Invalid Issue Specified" ])
            return
        }
        
        let currentAccount = QContext.shared().currentAccount
        
        guard let repositoryHash = issue["repository"] as? [AnyHashable: Any],
            let repositoryId = repositoryHash["identifier"] as? NSNumber,
            let repository = QRepositoryStore.repository(forAccountId: currentAccount?.identifier, identifier: repositoryId),
            let issueNumber = issue["number"] as? NSNumber else {
                onCompletion.call(withArguments: [ NSNull(), "Invalid Issue Specified" ])
                return
        }
        
        let service = QIssuesService(for: currentAccount!)
        operationQueue.addOperation {
            let semaphore = DispatchSemaphore(value: 0)
            
            service.saveIssueBody(body ?? "", for: repository, number: issueNumber) { (updateIssue, context, err) in
                if let updateIssue = updateIssue as? QIssue , err == nil {
                    QIssueStore.save(updateIssue)
                    onCompletion.call(withArguments: [ updateIssue.toExtensionModel(), NSNull() ])
                } else if let err = err {
                    onCompletion.call(withArguments: [ NSNull(), "\(err)" ])
                } else {
                    onCompletion.call(withArguments: [ NSNull(), "Unable to update issue description"])
                }
                semaphore.signal()
            }
            
            semaphore.wait(timeout: DispatchTime.distantFuture)
        }
    }
    
}

