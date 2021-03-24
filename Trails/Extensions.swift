//
//  Extensions.swift
//  Trails
//
//  Created by Michael Chartier on 3/24/21.
//

import Foundation
import MapKit


extension MKMapView {
    func centerMap(_ locations: [CLLocation])
    {
        var topLeftCoord = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoord = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        
        for annotation in locations {
            topLeftCoord.latitude = max(topLeftCoord.latitude, annotation.coordinate.latitude)
            topLeftCoord.longitude = min(topLeftCoord.longitude, annotation.coordinate.longitude)
            bottomRightCoord.latitude = min(bottomRightCoord.latitude, annotation.coordinate.latitude)
            bottomRightCoord.longitude = max(bottomRightCoord.longitude, annotation.coordinate.longitude)
        }
        let newCenter = CLLocationCoordinate2D(
            latitude: topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) / 2,
            longitude: topLeftCoord.longitude - (topLeftCoord.longitude - bottomRightCoord.longitude) / 2)
        let extraSpace = 1.4
        let span = MKCoordinateSpan(
            latitudeDelta: abs(topLeftCoord.latitude - bottomRightCoord.latitude) * extraSpace,
            longitudeDelta: abs(topLeftCoord.longitude - bottomRightCoord.longitude) * extraSpace)
        
        let newRegion = MKCoordinateRegion(center: newCenter, span: span)
        
        self.setCenter(newCenter, animated: false)
        self.setRegion(newRegion, animated: false)
    }

}

import CoreLocation

extension CLLocationCoordinate2D {
    var displayString: String {
        return String(latitude) + "," + String(longitude)
    }
}


extension UIBarButtonItem
{
    func hide() {
        tintColor = UIColor.clear
    }
    func unhide() {
        if let color = UIApplication.shared.delegate?.window??.tintColor {
            tintColor = color
        }
    }
}
