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

        // Update the map
        O_map.showsUserLocation = true
        refresh()
    }
    
    @IBAction func A_filter(_ sender: Any) { refresh() }
    @IBAction func A_distance(_ sender: Any) { refresh() }
    
    private func refresh()
    {
        getFilteredTrails()
        
        filteredTrails.forEach { trail in
            if let annotation = PinObject(trail: trail) {
                O_map.addAnnotation(annotation)
            }
        }

        var locations = [CLLocation]()
        if let user = locationManager.lastLockedLocation {
            locations.append(user)
        }
        locations += filteredTrails.map { $0.trailhead }
        O_map.centerMap( locations )
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
            let miles = meters / MetersPerMile
            subtitle = String(format:"%.1f miles", miles)
        }
        coordinate = trail.trailhead.coordinate
        id = trail.id
    }
}


