//
//  IssueExtensionEnvironmentProtocol.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 8/2/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Foundation
import JavaScriptCore

@objc(SRLogLevel)
enum LogLevel: Int {
    case Log;
    case Debug;
    case Error;
}

@objc(SRMilestoneServiceExtensionEnvironmentProtocol)
protocol MilestoneServiceExtensionEnvironmentProtocol: NSObjectProtocol {
    func milestonesForRepository(repository: NSDictionary, onCompletion: JSValue);
}

@objc(SROwnerServiceExtensionEnvironmentProtocol)
protocol OwnerServiceExtensionEnvironmentProtocol: NSObjectProtocol {
    func usersForRepository(repository: NSDictionary, onCompletion: JSValue);
}

@objc(SRLabelServiceExtensionEnvironmentProtocol)
protocol LabelServiceExtensionEnvironmentProtocol: NSObjectProtocol {
    func labelsForRepository(repository: NSDictionary, onCompletion: JSValue);
}

@objc(SRIssueServiceExtensionEnvironmentProtocol)
protocol IssueServiceExtensionEnvironmentProtocol: NSObjectProtocol {
    
    func closeIssue(issue: NSDictionary, onCompletion: JSValue);
    func openIssue(issue: NSDictionary, onCompletion: JSValue);
    func assignMilestoneToIssue(issue: NSDictionary, milestone: NSDictionary?, onCompletion: JSValue);
    func assignUserToIssue(issue: NSDictionary, user: NSDictionary?, onCompletion: JSValue);
    func assignLabelsToIssue(issue: NSDictionary, labels: NSArray?, onCompletion: JSValue);
    func createIssueComment(issue: NSDictionary, comment: String, onCompletion: JSValue);
    func saveIssueTitle(issue: NSDictionary, title: String, onCompletion: JSValue);
    func saveIssueBody(issue: NSDictionary, body: String?, onCompletion: JSValue);
    
}

@objc(SRCodeExtensionEnvironmentProtocol)
protocol CodeExtensionEnvironmentProtocol: NSObjectProtocol, IssueServiceExtensionEnvironmentProtocol, MilestoneServiceExtensionEnvironmentProtocol, OwnerServiceExtensionEnvironmentProtocol, LabelServiceExtensionEnvironmentProtocol {
    
    func consoleLog(arguments: [AnyObject], logLevel: LogLevel);
    func exceptionLog(line: String, column: String, stacktrace: String, exception: String);
    
    func writeToPasteboard(str: String)

}