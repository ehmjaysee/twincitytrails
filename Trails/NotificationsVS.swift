//
//  NotificationsVS.swift
//  Trails-411
//
//  Created by Michael Chartier on 3/14/21.
//

import UIKit

class NotificationsVS: UITableViewController {

    override func viewDidLoad()
    {
        super.viewDidLoad()
        allTrails.forEach { $0.editSubscription = $0.isSubscribed }  // default value before editing
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        super.setEditing(true, animated: true)
        
        for (i,item) in allTrails.enumerated() {
            if item.isSubscribed {
                let path = IndexPath(row: i, section: 0)
                tableView.selectRow(at: path, animated: false, scrollPosition: .none)
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return allTrails.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotifyCell", for: indexPath)
        cell.textLabel?.text = allTrails[indexPath.row].name

        // We don't want the cell color to change when it is selected.
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = cell.backgroundColor

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        allTrails[indexPath.row].editSubscription = true
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        allTrails[indexPath.row].editSubscription = false
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */


    @IBAction func A_back(_ sender: Any) {
        ckManager.updateSubscriptions()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func A_all(_ sender: Any) {
        for i in 0 ..< allTrails.count {
            allTrails[i].editSubscription = true
            let path = IndexPath(row: i, section: 0)
            tableView.selectRow(at: path, animated: false, scrollPosition: .none)
        }
    }

    @IBAction func A_none(_ sender: Any) {
        for i in 0 ..< allTrails.count {
            allTrails[i].editSubscription = false
            let path = IndexPath(row: i, section: 0)
            tableView.deselectRow(at: path, animated: false)
        }
    }
    
}
