//
//  Analytics.swift
//  Cashew
//
//  Created by Hicham Bouabdallah on 7/14/16.
//  Copyright © 2016 SimpleRocket LLC. All rights reserved.
//

import Cocoa
import Crashlytics

@objc(SRAnalytics)
class Analytics: NSObject {
    
    
    class func logContentViewWithName(contentNameOrNil: String?, contentType contentTypeOrNil: String?, contentId contentIdOrNil: String?, customAttributes customAttributesOrNil: [String : AnyObject]?) {
        #if DEBUG
            DDLogDebug("logContentViewWithName \(contentNameOrNil) \(contentTypeOrNil) \(contentIdOrNil) \(customAttributesOrNil)")
        #else
            Answers.logContentViewWithName(contentNameOrNil, contentType: contentTypeOrNil, contentId: contentIdOrNil, customAttributes: customAttributesOrNil)
        #endif
        
    }
    
    class func logCustomEventWithName(eventName: String, customAttributes customAttributesOrNil: [String : AnyObject]? = nil) {
        #if DEBUG
            DDLogDebug("logCustomEventWithName \(eventName) \(customAttributesOrNil)")
        #else
            Answers.logCustomEventWithName(eventName, customAttributes: customAttributesOrNil)
        #endif
    }
    
    class func logLoginWithMethod(loginMethodOrNil: String?, success loginSucceededOrNil: NSNumber?, customAttributes customAttributesOrNil: [String : AnyObject]?) {
        #if DEBUG
            DDLogDebug("logLoginWithMethod \(loginMethodOrNil) \(loginSucceededOrNil) \(customAttributesOrNil)")
        #else
            Answers.logLoginWithMethod(loginMethodOrNil, success: loginSucceededOrNil, customAttributes: customAttributesOrNil)
        #endif
    }


}

