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
    case log;
    case debug;
    case error;
}

@objc(SRMilestoneServiceExtensionEnvironmentProtocol)
protocol MilestoneServiceExtensionEnvironmentProtocol: NSObjectProtocol {
    func milestonesForRepository(_ repository: NSDictionary, onCompletion: JSValue);
}

@objc(SROwnerServiceExtensionEnvironmentProtocol)
protocol OwnerServiceExtensionEnvironmentProtocol: NSObjectProtocol {
    func usersForRepository(_ repository: NSDictionary, onCompletion: JSValue);
}

@objc(SRLabelServiceExtensionEnvironmentProtocol)
protocol LabelServiceExtensionEnvironmentProtocol: NSObjectProtocol {
    func labelsForRepository(_ repository: NSDictionary, onCompletion: JSValue);
}

@objc(SRIssueServiceExtensionEnvironmentProtocol)
protocol IssueServiceExtensionEnvironmentProtocol: NSObjectProtocol {
    
    func closeIssue(_ issue: NSDictionary, onCompletion: JSValue);
    func openIssue(_ issue: NSDictionary, onCompletion: JSValue);
    func assignMilestoneToIssue(_ issue: NSDictionary, milestone: NSDictionary?, onCompletion: JSValue);
    func assignUserToIssue(_ issue: NSDictionary, user: NSDictionary?, onCompletion: JSValue);
    func assignLabelsToIssue(_ issue: NSDictionary, labels: NSArray?, onCompletion: JSValue);
    func createIssueComment(_ issue: NSDictionary, comment: String, onCompletion: JSValue);
    func saveIssueTitle(_ issue: NSDictionary, title: String, onCompletion: JSValue);
    func saveIssueBody(_ issue: NSDictionary, body: String?, onCompletion: JSValue);
    
}

@objc(SRCodeExtensionEnvironmentProtocol)
protocol CodeExtensionEnvironmentProtocol: IssueServiceExtensionEnvironmentProtocol, MilestoneServiceExtensionEnvironmentProtocol, OwnerServiceExtensionEnvironmentProtocol, LabelServiceExtensionEnvironmentProtocol {
    
    func consoleLog(_ arguments: [AnyObject], logLevel: LogLevel);
    func exceptionLog(_ line: String, column: String, stacktrace: String, exception: String);
    
    func writeToPasteboard(_ str: String)

}
