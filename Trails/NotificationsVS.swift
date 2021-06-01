//
//  NotificationsVS.swift
//  Trails-411
//
//  Created by Michael Chartier on 3/14/21.
//

import UIKit

class NotificationsVS: UITableViewController
{
    @IBOutlet weak var O_favorite: UIBarButtonItem!
    
    var filteredTrails = [TrailData]()

    override func viewDidLoad()
    {
        super.viewDidLoad()
        getFilteredTrails()
        setFavoriteImage()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        refresh()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return filteredTrails.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotifyCell", for: indexPath)
        cell.textLabel?.text = filteredTrails[indexPath.row].name

        // We don't want the cell color to change when it is selected.
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = cell.backgroundColor

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let id = filteredTrails[indexPath.row].id
        if let index = allTrails.firstIndex(where: { $0.id == id }) {
            allTrails[index].subscriptionRequested = true
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let id = filteredTrails[indexPath.row].id
        if let index = allTrails.firstIndex(where: { $0.id == id }) {
            allTrails[index].subscriptionRequested = false
        }
    }
    
    @IBAction func A_favorite(_ sender: Any) {
        showFavoriteOnly = !showFavoriteOnly
        setFavoriteImage()
        refresh()
    }
    
    private func setFavoriteImage()
    {
        if showFavoriteOnly {
            O_favorite.image = UIImage(systemName: "heart.fill")
        } else {
            O_favorite.image = UIImage(systemName: "heart")
        }
    }
    
    private func refresh()
    {
        self.getFilteredTrails()
        let section0: IndexSet = [0]
        tableView.reloadSections(section0, with: .automatic)

        super.setEditing(true, animated: true)
        
        for (i,item) in filteredTrails.enumerated() {
            if item.isSubscribed {
                let path = IndexPath(row: i, section: 0)
                tableView.selectRow(at: path, animated: false, scrollPosition: .none)
            }
        }
    }
    
    private func getFilteredTrails()
    {
        if showFavoriteOnly {
            filteredTrails = allTrails.filter { $0.isFavorite }
        } else {
            filteredTrails = allTrails
        }
    }

    @IBAction func A_back(_ sender: Any) {
        ckManager.updateSubscriptions()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func A_all(_ sender: Any) {
        for i in 0 ..< allTrails.count {
            allTrails[i].subscriptionRequested = true
            let path = IndexPath(row: i, section: 0)
            tableView.selectRow(at: path, animated: false, scrollPosition: .none)
        }
    }

    @IBAction func A_none(_ sender: Any) {
        for i in 0 ..< allTrails.count {
            allTrails[i].subscriptionRequested = false
            let path = IndexPath(row: i, section: 0)
            tableView.deselectRow(at: path, animated: false)
        }
    }
    
}
