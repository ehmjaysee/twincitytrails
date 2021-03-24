//
//  LocationManager.swift
//  MotionIQ-Logger
//
//  Created by Michael Chartier on 10/29/19.
//  Copyright © 2019 Motion Instruments. All rights reserved.
//

import Foundation
import CoreLocation


let locationManager = LocationManager.shared
let Notif_LocationState         = Notification.Name("LocationState")
let Notif_LocationUpdate        = Notification.Name("LocationUpdate")

class LocationManager: NSObject, CLLocationManagerDelegate
{
    enum LocationState { case unknown; case notAvailable; case denied; case authorized; case locked }
 
    var locationState = LocationState.unknown {
        didSet {
            if (locationState != oldValue) {
                NotificationCenter.default.post(name: Notif_LocationState, object: locationState)
                print("LOCATION: \(locationState)")
            }}}
        
    let locationMgr = CLLocationManager()
    var hAccuracy = 0.0
    var vAccuracy = 0.0
    var timer: Timer?
    var lastLockedLocation: CLLocation? {
        didSet {
            NotificationCenter.default.post(name: Notif_LocationUpdate, object: nil)
            print("LOCATION UPDATE")
        }
    }
    
    // Singleton
    static let shared = LocationManager()

    private override init() { super.init() }
    
    func startup()
    {
        // Only do this once
        guard locationMgr.delegate == nil else { return }
        
        if (CLLocationManager.locationServicesEnabled() == true)
        {
            // Initialize locationManager instance
            locationMgr.delegate = self
            locationMgr.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationMgr.activityType = .fitness
            locationMgr.pausesLocationUpdatesAutomatically = true
//            locationMgr.allowsBackgroundLocationUpdates = true
            locationMgr.requestWhenInUseAuthorization()
        } else {
            locationState = .denied
        }
    }
    
    // This delegate gets called as soon as the delegate property is assigned.
    // It is also called when the user changes the location privacy settings.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        // Theoretically the authorization status could change to any possible value at any time.
        // Nominally when we initialize locationMgr object we get immediate authorization change to .notDetermined
        // Then user is asked for permission by the OS (only one time) and their choice is recorded
        // and we get the notification here.

        switch status {
        case .restricted:
            locationState = .notAvailable
        case .denied:
            locationState = .denied
        case .authorizedAlways, .authorizedWhenInUse:
            locationState = .authorized
            locationMgr.startUpdatingLocation()
        default: break
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        print("LocationManager:didFailWithError")
        print( error.localizedDescription )

        if let err = error as? CLError {
            print( "CLError \(err.errorCode)" )
            print( err.errorUserInfo )
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        // Now take just the most recent location value and update our state machine
        if let newLocation = locations.last
        {
            hAccuracy = newLocation.horizontalAccuracy
            vAccuracy = newLocation.verticalAccuracy
            let accuracy = (hAccuracy > 0.0) ? hAccuracy : 999.99

            if (accuracy < 100.0) {
                // We have good accuracy
                // Save this new location if significantly different from previous location
                if lastLockedLocation == nil {
                    lastLockedLocation = newLocation
                } else if let oldLocation = lastLockedLocation, oldLocation.distance(from: newLocation) > 1000 {
                    lastLockedLocation = newLocation
                }
                // Update our state
                if locationState == .authorized {
                    locationState = .locked
                }
            } else if (accuracy >= 20.0) && (locationState == .locked) {
                locationState = .authorized
            }
        }
    }

    func locationDisable()
    {
        locationMgr.stopUpdatingLocation()
    }

    func locationRestart()
    {
        // Called when coming out of background mode
        let status = CLLocationManager.authorizationStatus()

        if (status == .authorizedWhenInUse) || (status == .authorizedAlways) {
            locationMgr.startUpdatingLocation()
        }
    }

}


