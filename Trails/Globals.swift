//
//  Globals.swift
//  Trails 411
//
//  Created by Michael Chartier on 2/15/21.
//

import Foundation


let MetersPerMile                   = 1609.34   // convert miles to meters


struct Defaults {
    static let notificationAuth = "notificationAuth"            // Flag set after user grants permission to use notifications
    static let ckSubVersion = "ckSubVersion"                    // verion number for cloudkit subscriptions
    static let favoriteOnly = "favoriteOnly"
}

// Notifications
let Notif_TrailUpdate               = Notification.Name("TrailUpdate")        

var showFavoriteOnly: Bool {
    get { return appDefaults.bool(forKey: Defaults.favoriteOnly)}
    set { appDefaults.setValue(newValue, forKey: Defaults.favoriteOnly)}
}


