//
//  TrailsVC.swift
//  Trails 411
//
//  Created by Michael Chartier on 12/31/20.
//

import UIKit
import TORoundedButton


class TrailsVC: UIViewController
{

    @IBOutlet weak var O_bottomView: UIView!
    @IBOutlet weak var O_map: UIBarButtonItem!
    @IBOutlet weak var O_table: UITableView!
    @IBOutlet weak var O_filter: UISegmentedControl!
    @IBOutlet weak var O_distance: UISegmentedControl!
    @IBOutlet weak var O_favorite: UIBarButtonItem!
    @IBOutlet weak var O_share: RoundedButton!
    
    var filteredTrails = [TrailData]()

    override func viewDidLoad()
    {
        super.viewDidLoad()

        O_table.delegate = self
        O_table.dataSource = self
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(updateStatus), for: UIControl.Event.valueChanged)
        O_table.refreshControl = refreshControl

        if locationManager.lastLockedLocation == nil {
            O_map.hide()
        }
        
        // Update the directions button
        O_share.tappedHandler = { self.shareApp() }
        
        NotificationCenter.default.addObserver(self, selector: #selector(trailUpdate(notification:)), name: Notif_TrailUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(locationUpdate(notification:)), name: Notif_LocationUpdate, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showUserSettings()
        refresh()
    }
    
    @IBAction func A_notification(_ sender: Any)
    {
        if ckManager.ckStatus != .available {
            let msg = "\nWould you like to be notified when your favorite trails are open or cloosed?\n\nThis feature requires iCloud. Please log into your iCloud account and try again."
            doAlert(vc: self, title: "Alert", message: msg, fontSize: 17.0)
            return
        }
        
        // Determine the current authorization status for this user (allow, deny, not determined)
        UNUserNotificationCenter.current().getNotificationSettings() {
            settings in
            if (settings.authorizationStatus == .authorized) {
                DispatchQueue.main.async {
                    if let vc = self.storyboard?.instantiateViewController(withIdentifier: "NotificationsNav") {
                        self.present(vc, animated: true, completion: nil)
                    }
                }
            } else if (settings.authorizationStatus == .notDetermined) {
                // We never requested permission from the user.
                // Ask the user if they want notifications or not.
                DispatchQueue.main.async {
                    let msg = "Would you like to be notified when your favorite trails are open or closed? "
                    let alert = UIAlertController(title: msg, message: "", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                    alert.addAction(UIAlertAction(title: "Yes", style: .default) {_ in
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
                            authorized, error in
                            if let error = error {
                                print("REQUEST AUTHORIZATION \(error)")
                            }
                            if authorized == true {
                                appDefaults.set(true, forKey: Defaults.notificationAuth)
                                DispatchQueue.main.async {
                                    UIApplication.shared.registerForRemoteNotifications()
                                    if let vc = self.storyboard?.instantiateViewController(withIdentifier: "NotificationsNav") {
                                        self.present(vc, animated: true, completion: nil)
                                    }
                                }
                            }
                        }
                    })
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                appDefaults.removeObject(forKey: Defaults.notificationAuth)
            }
        }
    }

    @IBAction func A_filter(_ sender: Any) {
        refresh()
    }
    
    @IBAction func A_distance(_ sender: Any) {
        showDistance = O_distance.selectedSegmentIndex
        refresh()
    }
    
    @IBAction func A_favorite(_ sender: Any) {
        showFavoriteOnly = !showFavoriteOnly
        showUserSettings()
        refresh()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? TrailDetailVC, let row = O_table.indexPathForSelectedRow {
            O_table.deselectRow(at: row, animated: false)
            vc.trail = filteredTrails[row.row]
        }
    }
    
    @objc private func updateStatus() { MORCdata.update() }
    
    @objc private func trailUpdate( notification: NSNotification ) {
        if let _ = notification.object as? String {
            // a specific trail was updated
        } else {
            // the list of trails was updated
            DispatchQueue.main.async { self.refresh() }
        }
    }
    
    @objc private func locationUpdate( notification: NSNotification ) {
        O_map.unhide()
    }
    
    private func showUserSettings()
    {
        if showFavoriteOnly {
            O_favorite.image = UIImage(systemName: "heart.fill")
        } else {
            O_favorite.image = UIImage(systemName: "heart")
        }
        O_distance.selectedSegmentIndex = showDistance
    }
    
    private func refresh()
    {
        self.getFilteredTrails()
        let section0: IndexSet = [0]
        self.O_table.reloadSections(section0, with: .automatic)
        self.O_table.refreshControl?.endRefreshing()
    }
    
    private func getFilteredTrails()
    {
        filteredTrails.removeAll()
        
        let onlyOpen = (O_filter.selectedSegmentIndex == 1)
        let distance = showDistanceMiles

        for trail in allTrails {
            if onlyOpen && (trail.isOpen == false) { continue }
            if let trailDist = trail.distance, trailDist > distance { continue }
            if showFavoriteOnly == false || trail.isFavorite {
                filteredTrails.append(trail)
            }
        }

        filteredTrails.sort { $0.name < $1.name }
    }
    
    private func shareApp()
    {
        let title = "Please share this app with your friends."
        let msg = "\nThe app will always be completely free. Unfortunately Apple will not allow this app on the regular app store because it only serves the Twin Cities area. Word-of-mouth is the only way to grow the user base."
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let share = UIAlertAction(title: "Share", style: .default) { _ in
            if let name = URL(string: "https://testflight.apple.com/join/SkYTQvAc") {
                let objectsToShare = [name]
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                self.present(activityVC, animated: true, completion: nil)
            }
        }
        alert.addAction(share)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    /////////////////////////////////////////////////////////////////////
    /// MARK: CloudKit Subscription Management
    /////////////////////////////////////////////////////////////////////

    // Change this version number any time we change the format of any CloudKit subscription.
    // This will force the code to delete the old subscriptions and replace with new.
    let currentSubscriptionVersion = 12
    var subCount = 0
    var subCounter = 0

} // class TrailsVC


extension TrailsVC: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTrails.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let trail = filteredTrails[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrailCell", for: indexPath)
        if let trailCell = cell as? TrailCell {
            trailCell.O_title.text = trail.name
            if trail.isOpen {
                trailCell.O_icon.image = #imageLiteral(resourceName: "green-light-small")
            } else {
                trailCell.O_icon.image = #imageLiteral(resourceName: "red-light-small")
            }
        }
        return cell
    }
    

//    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) { showSelected() }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }

}

