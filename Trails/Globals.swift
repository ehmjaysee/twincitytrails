//
//  Globals.swift
//  Trails 411
//
//  Created by Michael Chartier on 2/15/21.
//

import Foundation


let testMode = false //debug

let MetersPerMile                   = 1609.34   // convert miles to meters


struct Defaults {
    static let notificationAuth = "notificationAuth"            // Flag set after user grants permission to use notifications
    static let ckSubVersion = "ckSubVersion"                    // verion number for cloudkit subscriptions
    static let favoriteOnly = "favoriteOnly"
    static let showDistance = "showDistance"
}

// Notifications
let Notif_TrailUpdate               = Notification.Name("TrailUpdate")        

var showFavoriteOnly: Bool {
    get { return appDefaults.bool(forKey: Defaults.favoriteOnly)}
    set { appDefaults.setValue(newValue, forKey: Defaults.favoriteOnly)}
}
var showDistance: Int {
    get { return appDefaults.integer(forKey: Defaults.showDistance)}
    set { appDefaults.setValue(newValue, forKey: Defaults.showDistance)}
}
var showDistanceMiles: Double {
    switch showDistance {
    case 0: return 10.0 * MetersPerMile
    case 1: return 20 * MetersPerMile
    case 2: return 40 * MetersPerMile
    case 3: return 80 * MetersPerMile
    default: return 9999 * MetersPerMile
    }
}

