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
    @IBOutlet weak var O_lastUpdate: UILabel!
    @IBOutlet weak var O_status: UILabel!
    @IBOutlet weak var O_description: UILabel!
    @IBOutlet weak var O_image: UIImageView!
    @IBOutlet weak var O_map: MKMapView!
    @IBOutlet weak var O_directions: RoundedButton!
    @IBOutlet weak var O_trailMap: UIImageView!
    @IBOutlet weak var O_trailMaps: RoundedButton!
    @IBOutlet weak var O_favorite: UIBarButtonItem!
    
    
    
    var trail: TrailData!  // set by presetner VC
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(trailUpdate(notification:)), name: Notif_TrailUpdate, object: nil)

        navigationItem.title = trail.name

        if let howOld = trail.howOld {
            O_lastUpdate.text = "Last Update " + howOld
            if let status = trail.status {
                O_status.text = status
                if trail.isOpen {
                    O_status.textColor = .systemGreen
                } else {
                    O_status.textColor = .systemRed
                }
            } else {
                O_status.text = "Trail status is unknown"
                O_status.textColor = .white
            }
            if let description = trail.description {
                O_description.text = description
            } else {
                O_description.text = "There are no details for this trail."
                O_description.textAlignment = .center
            }
        } else {
            O_lastUpdate.text = ""
            O_status.text = "Trail status is unknown"
            O_lastUpdate.text = (trail.description ?? " ")
        }

        // show default image for the trail
        let picname = "pic-" + (trail.filename ?? "default")
        O_image.image = UIImage(named: picname)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(photoTapped(tapGestureRecognizer:)))
        O_image.addGestureRecognizer(tapGestureRecognizer)

        
        // Update the map
        if let annotation = PinObject(trail: trail) {
            O_map.addAnnotation(annotation)
            O_map.selectAnnotation(annotation, animated: true)
            if locationManager.locationState == .locked {
                O_map.fitAll(userLocation: locationManager.lastLockedLocation, animated: false)
                O_map.isUserInteractionEnabled = false
            } else {
                O_map.setCenter(annotation.coordinate, padding: 2000)
                O_map.isUserInteractionEnabled = true
            }
        }
        O_map.showsUserLocation = true

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

        setFavoriteImage()
        
        appAnalytics.eventLog(name: "TrailView", properties: ["name":trail.name])
    }

    @IBAction func A_favorite(_ sender: Any) {
        trail.isFavorite = !trail.isFavorite
        setFavoriteImage()
    }
    
    private func setFavoriteImage()
    {
        if trail.isFavorite {
            O_favorite.image = UIImage(systemName: "heart.fill")
        } else {
            O_favorite.image = UIImage(systemName: "heart")
        }
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

} // class TrailDetailVC


extension TrailDetailVC: MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "PinObject"

        if annotation is PinObject {
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView {
                annotationView.annotation = annotation
                annotationView.pinTintColor = trail.isOpen ? .systemGreen : .systemRed
                return annotationView
            } else {
                let annotationView = MKPinAnnotationView(annotation:annotation, reuseIdentifier:identifier)
                annotationView.canShowCallout = true
                annotationView.isEnabled = true
                annotationView.pinTintColor = trail.isOpen ? .systemGreen : .systemRed
                return annotationView
            }
        }

        return nil
    }
}
