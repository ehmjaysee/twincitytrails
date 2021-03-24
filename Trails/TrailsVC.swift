//
//  TrailsVC.swift
//  Trails 411
//
//  Created by Michael Chartier on 12/31/20.
//

import UIKit

class TrailsVC: UIViewController
{

    @IBOutlet weak var O_bottomView: UIView!
    @IBOutlet weak var O_controls: UIBarButtonItem!
    @IBOutlet weak var O_bottomHeight: NSLayoutConstraint!
    @IBOutlet weak var O_table: UITableView!
    @IBOutlet weak var O_filter: UISegmentedControl!
    @IBOutlet weak var O_distance: UISegmentedControl!
    
    var filteredTrails = [TrailData]()

    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        O_table.delegate = self
        O_table.dataSource = self
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(updateStatus), for: UIControl.Event.valueChanged)
        O_table.refreshControl = refreshControl

        O_controls.hide()
        
        NotificationCenter.default.addObserver(self, selector: #selector(trailUpdate(notification:)), name: Notif_TrailUpdate, object: nil)
        
        MORCdata.update()       // get the latest trail status
    }
    
    @IBAction func A_notification(_ sender: Any)
    {
        if ckManager.ckStatus != .available {
            let msg = "\nWould you like to be notified when your favorite trails are open oor cloosed?\n\nThis feature requires iCloud. Please log into your iCloud account and try again."
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
                    let msg = "Would you like to be notified when your favoriite trails are open or closed? "
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

    @IBAction func A_controls(_ sender: Any)
    {
        let newHeight: CGFloat = (O_bottomHeight.constant == 1.0) ? 60.0 : 1.0
                
        UIView.animate(withDuration: 0.5) {
            self.O_bottomHeight.constant = newHeight
            self.view.layoutIfNeeded()
        }

    }
    
    @IBAction func A_filter(_ sender: Any) {
        refresh()
    }
    
    @IBAction func A_distance(_ sender: Any) {
        refresh()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? TrailDetailVC, let row = O_table.indexPathForSelectedRow {
            O_table.deselectRow(at: row, animated: false)
            vc.index = row.row
        }
    }
    
    @objc private func updateStatus() { MORCdata.update() }
    
    @objc func trailUpdate( notification: NSNotification ) {
        if let id = notification.object as? String {
            // a specific trail was updated
        } else {
            // the list of trails was updated
            DispatchQueue.main.async { self.refresh() }
        }
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

