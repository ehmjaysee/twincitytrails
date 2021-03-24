//
//  Extensions.swift
//  Trails
//
//  Created by Michael Chartier on 3/24/21.
//

import Foundation
import MapKit


extension MKMapView
{
    // Center & Size the map to show all annotations
    func fitAll( userLocation: CLLocation? = nil, animated: Bool )
    {
        var zoomRect            = MKMapRect.null
        for annotation in annotations {
            let annotationPoint = MKMapPoint(annotation.coordinate)
            let pointRect       = MKMapRect(x: annotationPoint.x, y: annotationPoint.y, width: 0.01, height: 0.01);
            zoomRect            = zoomRect.union(pointRect);
        }
        if let user = userLocation {
            let annotationPoint = MKMapPoint(user.coordinate)
            let pointRect       = MKMapRect(x: annotationPoint.x, y: annotationPoint.y, width: 0.01, height: 0.01);
            zoomRect            = zoomRect.union(pointRect);
        }
        setVisibleMapRect(zoomRect, edgePadding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: animated)
    }
} // extension MKMapView


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
