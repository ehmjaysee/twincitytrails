//
//  MapVC.swift
//  Trails
//
//  Created by Michael Chartier on 3/24/21.
//

import UIKit
import MapKit


class MapVC: UIViewController
{

    @IBOutlet weak var O_filter: UISegmentedControl!
    @IBOutlet weak var O_map: MKMapView!
    @IBOutlet weak var O_bottomView: UIView!
    @IBOutlet weak var O_distance: UISegmentedControl!
    
    
    var filteredTrails = [TrailData]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(trailUpdate(notification:)), name: Notif_TrailUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(locationUpdate(notification:)), name: Notif_LocationUpdate, object: nil)

        // Update the map
        O_map.showsUserLocation = true
        
        // Create annotations for all trails
        allTrails.forEach { trail in
            if let annotation = PinObject(trail: trail) {
                O_map.addAnnotation(annotation)
            }
        }
        if let user = locationManager.lastLockedLocation {
            O_map.fitAll(userLocation: user, animated: false)
        }
    }
    
    @IBAction func A_filter(_ sender: Any) { refresh() }
    @IBAction func A_distance(_ sender: Any) { refresh() }
    
    private func refresh()
    {
        getFilteredTrails()
        
        // Remove stale annotations
        O_map.annotations.forEach { annotation in
            if let pin = annotation as? PinObject, filteredTrails.contains(where: { $0.id == pin.id }) == false {
                O_map.removeAnnotation(annotation)
            }
        }
        
        // Add the missing annotations
        filteredTrails.forEach { trail in
            var matching: MKAnnotation?
            for item in O_map.annotations {
                if let pin = item as? PinObject, pin.id == trail.id {
                    matching = item
                    break
                }
            }
            if matching == nil, let annotation = PinObject(trail: trail) {
                O_map.addAnnotation(annotation)
            }
        }

        if let user = locationManager.lastLockedLocation, filteredTrails.count > 0 {
            O_map.fitAll(userLocation: user, animated: true)
        }
    }
    
    private func getFilteredTrails()
    {
        filteredTrails.removeAll()
        
        let onlyOpen = (O_filter.selectedSegmentIndex == 1)
        let distance: Double

        switch O_distance.selectedSegmentIndex {
        case 0: distance = 10.0 * MetersPerMile
        case 1: distance = 20 * MetersPerMile
        case 2: distance = 40 * MetersPerMile
        case 3: distance = 80 * MetersPerMile
        default: distance = 9999 * MetersPerMile
        }
        
        for trail in allTrails {
            if onlyOpen && (trail.isOpen == false) { continue }
            if let trailDist = trail.distance, trailDist > distance { continue }
            filteredTrails.append(trail)
        }
        
        filteredTrails.sort { $0.name < $1.name }
    }
    
    @objc private func trailUpdate( notification: NSNotification )
    {
        if let id = notification.object as? String, let trail = allTrails.first(where: { $0.id == id }), let meters = trail.distance {
            // One specific trail was updated. Update the annotation details
            for item in O_map.annotations {
                if let pin = item as? PinObject, pin.id == id {
                    pin.subtitle = PinObject.getSubtitle(meters: meters)
                }
            }
        } else {
            // the list of trails was updated
            DispatchQueue.main.async { self.refresh() }
        }
    }
    
    @objc private func locationUpdate( notification: NSNotification ) {
        if let user = locationManager.lastLockedLocation {
            O_map.fitAll(userLocation: user, animated: true)
        }
    }

}

extension MapVC: MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        let identifier = "Trailhead"

        if annotation is PinObject {
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                annotationView.annotation = annotation
                return annotationView
            } else {
                let annotationView = MKPinAnnotationView(annotation:annotation, reuseIdentifier:identifier)
                annotationView.isEnabled = true
                annotationView.canShowCallout = true

                let btn = UIButton(type: .detailDisclosure)
                annotationView.rightCalloutAccessoryView = btn
                return annotationView
            }
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl)
    {
        if let pin = view.annotation as? PinObject, let index = allTrails.firstIndex(where: { $0.id == pin.id }),
           let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TrailDetailVC") as? TrailDetailVC {
            vc.trail = allTrails[index]
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

class PinObject: NSObject, MKAnnotation
{
    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D
    var id: String

    init?( trail: TrailData )
    {
        title = trail.name
        if let meters = trail.distance {
            subtitle = PinObject.getSubtitle(meters: meters)
        }
        coordinate = trail.trailhead.coordinate
        id = trail.id
    }
    
    class func getSubtitle( meters: Double ) -> String
    {
        let miles = meters / MetersPerMile
        return String(format:"%.1f miles", miles)
    }
}


