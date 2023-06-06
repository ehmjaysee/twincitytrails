//
//  Analytics.swift
//  MotionIQ
//
//  Created by Michael Chartier on 4/9/21.
//  Copyright © 2021 Motion Instruments. All rights reserved.
//

import Foundation
import Mixpanel


let appAnalytics = AppAnalytics.shared

class AppAnalytics
{
    var mixpanel: MixpanelInstance?
    
    static let shared = AppAnalytics()

    var appStartTime: Date?
    var appRecordStart: Date?
    
    // private ensures this class will be a singleton
    private init()
    {
        // Initialize the Mixpanel object. Use the flag [useAnalytics] to set the opt-out/opt-in status.
        mixpanel = Mixpanel.initialize(token: MixPanelToken, trackAutomaticEvents: true, optOutTrackingByDefault: !useAnalytics)

        // Store the app distro (debug, testflight, appstore) with every event
        mixpanel?.registerSuperProperties(["AppDistro": Config.appConfiguration.name])
        
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)

    }
    
    // The 27 member countries of the EU
    let EUCountries = ["BE": "Belgium",
                       "BG": "Bulgaria",
                       "CZ": "Czech Republic",
                       "DK": "Denmark",
                       "DE": "Germany",
                       "EE": "Estonia",
                       "IE": "Ireland",
                       "GR": "Greece",
                       "ES": "Spain",
                       "FR": "France",
                       "HR": "Croatia",
                       "IT": "Italy",
                       "CY": "Cyprus",
                       "LV": "Latvia",
                       "LT": "Lithuania",
                       "LU": "Luxembourg",
                       "HU": "Hungary",
                       "MT": "Malta",
                       "NL": "Netherlands",
                       "AT": "Austria",
                       "PL": "Poland",
                       "PT": "Portugal",
                       "RO": "Romania",
                       "SI": "Slovenia",
                       "SK": "Slovakia",
                       "FI": "Finland",
                       "SE": "Sweden" ]

    var isRegionInEU: Bool {
        if let region = Locale.current.regionCode, EUCountries[region] != nil {
            return true
        } else {
            return false
        }
    }

    /*
    func setEnabled( _ enabled: Bool )
    {
        useAnalytics = enabled
        if enabled {
            mixpanel?.optInTracking()
        } else {
            mixpanel?.optOutTracking()
        }
    }
    */
    
    func eventLog( name: String, properties: [String:MixpanelType]? = nil )
    {
        guard useAnalytics == true else { return }
        
        var combined = [String:MixpanelType]()
        if let properties = properties {
            combined = properties
        }
        mixpanel?.track(event: name, properties: combined)
    }

    func eventRecordStart()
    {
        appRecordStart = Date()
        self.eventLog(name: "Record")
    }
    
    func eventRecordOff()
    {
        guard let appRecordStart = appRecordStart else { return }
        let durationSeconds = Date().timeIntervalSince1970 - appRecordStart.timeIntervalSince1970
        self.eventLog( name: "RecordOff", properties: ["duration":durationSeconds] )
        self.appRecordStart = nil
    }
    
    @objc func didEnterBackground( notification: NSNotification )
    {
        guard let appStartTime = appStartTime else { return }
        let activeSeconds = Date().timeIntervalSince1970 - appStartTime.timeIntervalSince1970
        self.eventLog( name: "Sleep", properties: ["howlong":activeSeconds] )
    }

    @objc func willEnterForeground( notification: NSNotification )
    {
        appStartTime = Date()
        let languagePrefix = Locale.preferredLanguages[0]
        self.eventLog(name: "Wakeup", properties: ["language":languagePrefix])
    }

}
