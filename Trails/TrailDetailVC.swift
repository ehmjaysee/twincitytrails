//
//  TrailDetailVC.swift
//  Trails-411
//
//  Created by Michael Chartier on 3/8/21.
//

import UIKit
import MapKit
import TORoundedButton
import SafariServices


class TrailDetailVC: UIViewController
{
    @IBOutlet weak var O_status: UILabel!
    @IBOutlet weak var O_image: UIImageView!
    @IBOutlet weak var O_map: MKMapView!
    @IBOutlet weak var O_directions: RoundedButton!
    @IBOutlet weak var O_trailMap: UIImageView!
    @IBOutlet weak var O_updated: UIButton!
    @IBOutlet weak var O_trailMaps: RoundedButton!
    @IBOutlet weak var O_imagePageControl: UIPageControl!
    
    
    
    var index: Int!     // set by presetner VC
    var trail: TrailData!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(trailUpdate(notification:)), name: Notif_TrailUpdate, object: nil)

        trail = allTrails[index]

        navigationItem.title = trail.name

        O_status.text = trail.status
        O_updated.setTitle("Updated " + trail.howOld, for: .normal)

        // show default image for the trail
        let picname = "pic-" + (trail.filename ?? "default")
        O_image.image = UIImage(named: picname)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(photoTapped(tapGestureRecognizer:)))
        O_image.addGestureRecognizer(tapGestureRecognizer)

//        O_description.text = trail.description
//        let size = O_description.sizeThatFits(CGSize(width:O_description.bounds.width, height: CGFloat.greatestFiniteMagnitude))
//        O_descriptionHeight.constant = size.height
        
        // Update the map
        if let user = locationManager.lastLockedLocation {
            O_map.showsUserLocation = true
            if let annotation = PinObject(trail: trail) {
                O_map.addAnnotation(annotation)
                O_map.selectAnnotation(annotation, animated: true)
            }
            let locations = [user, trail.trailhead]
            centerMap(locations)
            O_map.isUserInteractionEnabled = false
        }

        // Update the directions button
        O_directions.text = ""
        O_directions.tappedHandler = { self.showDirections() }
        if let travelTime = trail.travelTime {
            let minutes = Int(travelTime / 60.0)
            let text = "Directions\n" + String(minutes) + " min"
            O_directions.attributedText = NSAttributedString(string: text)
        } else {
            O_directions.attributedText = NSAttributedString(string: "Directions")
        }
        
        // Trail Map Button & image
        O_trailMaps.tappedHandler = { self.showMaps() }
        if let filename = trail.filename {
            let file = "map-" + filename
            O_trailMap.image = UIImage(named: file)
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
            O_trailMap.addGestureRecognizer(tapGestureRecognizer)
        }
    }

    @IBAction func A_updated(_ sender: Any) {
        let message = "\n" + (trail.description ?? "There are no notes for this trail")
        doAlert(vc: self, title: "Latest Update", message: message, fontSize: 17.0)
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        showMaps()
    }

    @objc func photoTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PhotoBrowser")
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showMaps()
    {
        var flag = false
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if let page = trail.TrailForksPage, let url = URL(string: "https://m.trailforks.com/" + page) {
            flag = true
            actionSheet.addAction(UIAlertAction(title: "Trail Forks", style: .default, handler: {
                (alert:UIAlertAction!) -> Void in
                let config = SFSafariViewController.Configuration()
                let vc = SFSafariViewController(url: url, configuration: config)
                self.present(vc, animated: true)
            }))
        }
        if let page = trail.MORCpage, let url = URL(string: "https://www.mtbproject.com/" + page) {
            flag = true
            actionSheet.addAction(UIAlertAction(title: "MTB Project", style: .default, handler: {
                (alert:UIAlertAction!) -> Void in
                let config = SFSafariViewController.Configuration()
                let vc = SFSafariViewController(url: url, configuration: config)
                self.present(vc, animated: true)
            }))
        }
        
        if flag {
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(actionSheet, animated: true, completion: nil)
        }
    }
    
    private func showDirections()
    {
        // first try google maps
        if UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!) {
            //        "comgooglemaps://?daddr=48.8566,2.3522)&directionsmode=driving&zoom=14&views=traffic"
            let urlString = "comgooglemaps://dir/?api=1&daddr=" + trail.trailhead.coordinate.displayString + ")&directionsmode=driving&zoom=14&views=traffic&dir_action=navigate"
            print(urlString)
            let url = URL(string: urlString)!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: trail.trailhead.coordinate, addressDictionary: nil))
            mapItem.name = trail.name
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        }
    }
    
    
    @objc func trailUpdate( notification: NSNotification ) {
        if let id = notification.object as? String, id == trail.id, let newData = allTrails.first(where: { $0.id == id }) {
            // There was an update to the trail data that we are currently displaying
            self.trail = newData

            // Check if the travelTime was updated
            if let travelTime = trail.travelTime {
                let minutes = Int(travelTime / 60.0)
                let text = "Directions\n" + String(minutes) + " min"
                O_directions.attributedText = NSAttributedString(string: text)
            }
        }
    }

    private func centerMap(_ locations: [CLLocation])
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
        
        O_map.setCenter(newCenter, animated: false)
        O_map.setRegion(newRegion, animated: false)
        
    }
}


class PinObject: NSObject, MKAnnotation
{
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var title: String?
    @objc dynamic var subtitle: String?

    init?( trail: TrailData )
    {
        coordinate = trail.trailhead.coordinate
        title = trail.name
        subtitle = "Trailhead"
    }
}


extension TrailDetailVC: MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "PinObject"

        if annotation is PinObject {
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                annotationView.annotation = annotation
                return annotationView
            } else {
                let annotationView = MKPinAnnotationView(annotation:annotation, reuseIdentifier:identifier)

//                let btn = UIButton(type: .detailDisclosure)
//                btn.setTitle("Directions", for: .normal)
//                annotationView.rightCalloutAccessoryView = btn
                annotationView.canShowCallout = true
                annotationView.isEnabled = true
                return annotationView
            }
        }

        return nil
    }
/*
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let capital = view.annotation as! PinObject
        let placeName = capital.title
        let placeInfo = "testing"   //capital.info

        let ac = UIAlertController(title: placeName, message: placeInfo, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
*/
}
