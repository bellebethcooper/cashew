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
    
    private let context = JSContext(virtualMachine: JSVirtualMachine())
    
    required init(environment: CodeExtensionEnvironmentProtocol) {
        super.init()
        
        context.exceptionHandler = { (context, exception) in
            // type of String
            let stacktrace = exception.objectForKeyedSubscript("stack").toString()
            // type of Number
            let lineNumber = exception.objectForKeyedSubscript("line")
            // type of Number
            let column = exception.objectForKeyedSubscript("column")
            
            environment.exceptionLog("\(lineNumber)", column: "\(column)", stacktrace: "\(stacktrace)", exception: "\(exception)")
        }
        
        do {
            if let foundation = NSBundle.mainBundle().pathForResource("issue_extension_context", ofType: "js") {
                let foundationCode = try NSString(contentsOfFile: foundation, encoding: NSUTF8StringEncoding)
                context.evaluateScript(foundationCode as String)
            }
        } catch {
        
        }

        let consoleLog: @convention(block) [AnyObject] -> Void = { (objects) in
            //DDLogDebug("[LOG] \(message)")
            //guard let strongContext = context else { return }
            // JSContext.currentArguments()
            environment.consoleLog(objects, logLevel: .Log)
        }
        
        let writeToPasteboard: @convention(block) String -> Void = { (str) in
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
        
        context.setObject(unsafeBitCast(consoleLog, AnyObject.self), forKeyedSubscript: "_consoleLog")
        context.setObject(unsafeBitCast(writeToPasteboard, AnyObject.self), forKeyedSubscript: "_writeToPasteboard")
        
        context.setObject(unsafeBitCast(closeIssue, AnyObject.self), forKeyedSubscript: "_Cashew_JSIssueServiceCloseIssue")
        context.setObject(unsafeBitCast(openIssue, AnyObject.self), forKeyedSubscript: "_Cashew_JSIssueServiceOpenIssue")
        context.setObject(unsafeBitCast(assignMilestoneToIssue, AnyObject.self), forKeyedSubscript: "_Cashew_JSIssueServiceAssignMilestoneToIssue")
        context.setObject(unsafeBitCast(assignUserToIssue, AnyObject.self), forKeyedSubscript: "_Cashew_JSIssueServiceAssignUserToIssue")
        context.setObject(unsafeBitCast(assignLabelsToIssue, AnyObject.self), forKeyedSubscript: "_Cashew_JSIssueServiceAssignLabelsToIssue")
        context.setObject(unsafeBitCast(createIssueComment, AnyObject.self), forKeyedSubscript: "_Cashew_JSIssueServiceCreateIssueComment")
        context.setObject(unsafeBitCast(saveIssueTitle, AnyObject.self), forKeyedSubscript: "_Cashew_JSIssueServiceSaveIssueTitle")
        context.setObject(unsafeBitCast(saveIssueBody, AnyObject.self), forKeyedSubscript: "_Cashew_JSIssueServiceSaveIssueBody")
        
        context.setObject(unsafeBitCast(milestonesForRepository, AnyObject.self), forKeyedSubscript: "_Cashew_JSMilestoneServiceMilestonesForRepository")
        
        context.setObject(unsafeBitCast(usersForRepository, AnyObject.self), forKeyedSubscript: "_Cashew_JSOwnerServiceUsersForRepository");
        
        context.setObject(unsafeBitCast(labelsForRepository, AnyObject.self), forKeyedSubscript: "_Cashew_JSLabelServiceLabelsForRepository");
        
    }
    
    func runWithIssues(issues: [NSDictionary], sourceCode: String) {
        context.evaluateScript(sourceCode)
        let execute = context.objectForKeyedSubscript("_Cashew_execute")
        //let execute = context.objectForKeyedSubscript("execute")
        execute.callWithArguments([issues])
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
//        let currentAccount = QContext.sharedContext().currentAccount
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
//        let currentAccount = QContext.sharedContext().currentAccount
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