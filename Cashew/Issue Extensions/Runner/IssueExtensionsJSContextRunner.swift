//
//  UserActionJSContextRunner.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/24/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa
import JavaScriptCore

@objc(SRIssueExtensionsJSContextRunner)
class IssueExtensionsJSContextRunner: NSObject {
    
   // static let sharedInstance = IssueExtensionsJSContextRunner()
    
    fileprivate let context = JSContext(virtualMachine: JSVirtualMachine())
    
    @objc required init(environment: CodeExtensionEnvironmentProtocol) {
        super.init()
        
        context?.exceptionHandler = { (context, exception) in
            // type of String
            let stacktrace = exception?.objectForKeyedSubscript("stack").toString()
            // type of Number
            let lineNumber = exception?.objectForKeyedSubscript("line")
            // type of Number
            let column = exception?.objectForKeyedSubscript("column")
            
            environment.exceptionLog("\(lineNumber)", column: "\(column)", stacktrace: "\(stacktrace)", exception: "\(exception)")
        }
        
        do {
            if let foundation = Bundle.main.path(forResource: "issue_extension_context", ofType: "js") {
                let foundationCode = try NSString(contentsOfFile: foundation, encoding: String.Encoding.utf8.rawValue)
                context?.evaluateScript(foundationCode as String)
            }
        } catch {
        
        }

        let consoleLog: @convention(block) ([AnyObject]) -> Void = { (objects) in
            //DDLogDebug("[LOG] \(message)")
            //guard let strongContext = context else { return }
            // JSContext.currentArguments()
            environment.consoleLog(objects, logLevel: .log)
        }
        
        let writeToPasteboard: @convention(block) (String) -> Void = { (str) in
            environment.writeToPasteboard(str)
        }
        
        let closeIssue: @convention(block) (NSDictionary, JSValue) -> Void = { (issue, completion) in
            environment.closeIssue(issue, onCompletion: completion)
        }
        
        let openIssue: @convention(block) (NSDictionary, JSValue) -> Void = { (issue, completion) in
            environment.openIssue(issue, onCompletion: completion)
        }
        
        let assignMilestoneToIssue: @convention(block) (NSDictionary, NSDictionary?, JSValue) -> Void = { (issue, milestone, completion) in
            environment.assignMilestoneToIssue(issue, milestone: milestone, onCompletion: completion)
        }
        
        let assignUserToIssue: @convention(block) (NSDictionary, NSDictionary?, JSValue) -> Void = { (issue, user, completion) in
            environment.assignUserToIssue(issue, user: user, onCompletion: completion)
        }
        
        let assignLabelsToIssue: @convention(block) (NSDictionary, NSArray?, JSValue) -> Void = { (issue, labels, completion) in
            environment.assignLabelsToIssue(issue, labels: labels, onCompletion: completion)
        }
        
        let createIssueComment: @convention(block) (NSDictionary, String, JSValue) -> Void = { (issue, comment, completion) in
            environment.createIssueComment(issue, comment: comment, onCompletion: completion)
        }

        let saveIssueTitle: @convention(block) (NSDictionary, String, JSValue) -> Void = { (issue, title, completion) in
            environment.saveIssueTitle(issue, title: title, onCompletion: completion)
        }
        
        let saveIssueBody: @convention(block) (NSDictionary, JSValue, JSValue) -> Void = { (issue, body, completion) in
            environment.saveIssueBody(issue, body: body.isNull ? nil : body.toString(), onCompletion: completion)
        }
        
        let milestonesForRepository: @convention(block) (NSDictionary, JSValue) -> Void = { (repository, completion) in
            environment.milestonesForRepository(repository, onCompletion: completion)
        }
        
        let usersForRepository: @convention(block) (NSDictionary, JSValue) -> Void = { (repository, completion) in
            environment.usersForRepository(repository, onCompletion: completion)
        }
        
        let labelsForRepository: @convention(block) (NSDictionary, JSValue) -> Void = { (repository, completion) in
            environment.labelsForRepository(repository, onCompletion: completion)
        }
        
        context?.setObject(unsafeBitCast(consoleLog, to: AnyObject.self), forKeyedSubscript: "_consoleLog" as (NSCopying & NSObjectProtocol)!)
        context?.setObject(unsafeBitCast(writeToPasteboard, to: AnyObject.self), forKeyedSubscript: "_writeToPasteboard" as (NSCopying & NSObjectProtocol)!)
        
        context?.setObject(unsafeBitCast(closeIssue, to: AnyObject.self), forKeyedSubscript: "_Cashew_JSIssueServiceCloseIssue" as (NSCopying & NSObjectProtocol)!)
        context?.setObject(unsafeBitCast(openIssue, to: AnyObject.self), forKeyedSubscript: "_Cashew_JSIssueServiceOpenIssue" as (NSCopying & NSObjectProtocol)!)
        context?.setObject(unsafeBitCast(assignMilestoneToIssue, to: AnyObject.self), forKeyedSubscript: "_Cashew_JSIssueServiceAssignMilestoneToIssue" as (NSCopying & NSObjectProtocol)!)
        context?.setObject(unsafeBitCast(assignUserToIssue, to: AnyObject.self), forKeyedSubscript: "_Cashew_JSIssueServiceAssignUserToIssue" as (NSCopying & NSObjectProtocol)!)
        context?.setObject(unsafeBitCast(assignLabelsToIssue, to: AnyObject.self), forKeyedSubscript: "_Cashew_JSIssueServiceAssignLabelsToIssue" as (NSCopying & NSObjectProtocol)!)
        context?.setObject(unsafeBitCast(createIssueComment, to: AnyObject.self), forKeyedSubscript: "_Cashew_JSIssueServiceCreateIssueComment" as (NSCopying & NSObjectProtocol)!)
        context?.setObject(unsafeBitCast(saveIssueTitle, to: AnyObject.self), forKeyedSubscript: "_Cashew_JSIssueServiceSaveIssueTitle" as (NSCopying & NSObjectProtocol)!)
        context?.setObject(unsafeBitCast(saveIssueBody, to: AnyObject.self), forKeyedSubscript: "_Cashew_JSIssueServiceSaveIssueBody" as (NSCopying & NSObjectProtocol)!)
        
        context?.setObject(unsafeBitCast(milestonesForRepository, to: AnyObject.self), forKeyedSubscript: "_Cashew_JSMilestoneServiceMilestonesForRepository" as (NSCopying & NSObjectProtocol)!)
        
        context?.setObject(unsafeBitCast(usersForRepository, to: AnyObject.self), forKeyedSubscript: "_Cashew_JSOwnerServiceUsersForRepository" as (NSCopying & NSObjectProtocol)!);
        
        context?.setObject(unsafeBitCast(labelsForRepository, to: AnyObject.self), forKeyedSubscript: "_Cashew_JSLabelServiceLabelsForRepository" as (NSCopying & NSObjectProtocol)!);
        
    }
    
    func runWithIssues(_ issues: [NSDictionary], sourceCode: String) {
        context?.evaluateScript(sourceCode)
        let execute = context?.objectForKeyedSubscript("_Cashew_execute")
        //let execute = context.objectForKeyedSubscript("execute")
        execute?.call(withArguments: [issues])
        //        let executeFunction = context.objectForKeyedSubscript("execute")
        //        let result = executeFunction.callWithArguments([ ["title": "Hicham is testing javascript"] ])
        //        print("Execute method: \(result.toString)")
        //        let doActionFunction = context.objectForKeyedSubscript("doAction")
        //        let result = doActionFunction.callWithArguments([ ["title": "Hicham is testing javascript"] ])
        //        print("doAction: \(result.toString())")
    }
}

//
////
////@objc protocol JSIssueServiceExport: JSExport {
////    func closeIssue(issue: NSDictionary, onCompletion: JSValue)
////    func openIssue(issue: NSDictionary, onCompletion: JSValue)
////}
//
////@objc
//class JSIssueService: NSObject { //, JSIssueServiceExport {
//    
//    func closeIssue(issue: NSDictionary, onCompletion: JSValue) {
//        let currentAccount = QContext.shared().currentAccount
//        guard let repositoryHash = issue["repository"] as? [NSObject: AnyObject], repositoryId = repositoryHash["identifier"] as? NSNumber,
//            repository = QRepositoryStore.repositoryForAccountId(currentAccount.identifier, identifier: repositoryId),
//            issueNumber = issue["number"] as? NSNumber else {
//                onCompletion.callWithArguments([ NSNull(),  "Invalid Issue Specified" ])
//                return;
//        }
//        
//        let service = QIssuesService(forAccount: currentAccount)
//        service.closeIssueForRepository(repository, number: issueNumber) { (updateIssue, context, err) in
//            if let updateIssue = updateIssue as? QIssue where err == nil {
//                QIssueStore.saveIssue(updateIssue)
//                onCompletion.callWithArguments([ updateIssue.toExtensionModel(), NSNull() ])
//            } else if let err = err {
//                onCompletion.callWithArguments([ NSNull(), "\(err)" ])
//            } else {
//                onCompletion.callWithArguments([ NSNull(), "Unable to close issue" ])
//            }
//            
//        }
//    }
//    
//    func openIssue(issue: NSDictionary, onCompletion: JSValue) {
//        let currentAccount = QContext.shared().currentAccount
//        guard let repositoryHash = issue["repository"] as? [NSObject: AnyObject], repositoryId = repositoryHash["identifier"] as? NSNumber,
//            repository = QRepositoryStore.repositoryForAccountId(currentAccount.identifier, identifier: repositoryId),
//            issueNumber = issue["number"] as? NSNumber else {
//                onCompletion.callWithArguments([ NSNull(), "Invalid Issue Specified" ])
//                return;
//        }
//        
//        let service = QIssuesService(forAccount: currentAccount)
//        service.reopenIssueForRepository(repository, number: issueNumber) { (updateIssue, context, err) in
//            if let updateIssue = updateIssue as? QIssue where err == nil {
//                QIssueStore.saveIssue(updateIssue)
//                onCompletion.callWithArguments([ updateIssue.toExtensionModel(), NSNull() ])
//            } else if let err = err {
//                onCompletion.callWithArguments([ NSNull(), "\(err)" ])
//            } else {
//                onCompletion.callWithArguments([ NSNull(), "Unable to close issue"])
//            }
//            
//        }
//    }
//    
//    //func closeIssue:(NSDictionary *)issue onCompletion
//}
