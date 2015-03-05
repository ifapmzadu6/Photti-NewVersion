//
//  PAAnalytics.swift
//  Photti
//
//  Created by Keisuke Karijuku on 2014/11/13.
//  Copyright (c) 2014年 Keisuke Karijuku. All rights reserved.
//

import UIKit

let gooeleAnalyticsId = "*"

class PAAnalytics: NSObject {
    
    class func sendEventWithClass(selfClass: AnyClass!, action: String!) {
        sendEvent(NSStringFromClass(selfClass), action: action);
    }
    
    class func sendEvent(category: String!, action: String!) {
        sendEvent(category, action: action, optionalLabel: nil, optionalValue: nil)
    }
    
    class func sendEvent(category: String!, action: String!, optionalLabel: String?, optionalValue: NSNumber?) {
        let label = (optionalLabel != nil) ? optionalLabel : "default"
        let value = (optionalValue != nil) ? optionalValue : 0
        
        let tracker = GAI.sharedInstance().trackerWithTrackingId(gooeleAnalyticsId)
        let sendObject = GAIDictionaryBuilder.createEventWithCategory(category, action: action, label: label, value: value).build();
        tracker.send(sendObject);
    }
}
