//
//  MORCdata.swift
//  Trails 411
//
//  Created by Michael Chartier on 1/2/21.
//

import Foundation
import CoreLocation
import SwiftyJSON


let MORCdata = MORCdataProvider.shared

class MORCdataProvider
{
    static let shared = MORCdataProvider()
    private init() { }  // private ensures this class will be a singleton
    var busy = false
    
    func update()
    {
        guard busy == false else { return }
        busy = true
        
        let url = URL(string: "https://api.morcmtb.org/v1/trails")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("MORC DATA \(error)")
                self.busy = false
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                self.busy = false
                return
            }
            if let data = data {
                let json = JSON(data)
                self.parse(response: json)
            }
        }
        task.resume()
    }
    
    private func parse( response: JSON )
    {
        for trail in response.arrayValue {
//            print("\n")
//            print(trail)
            
            guard let name = trail["trailName"].string, let id = trail["trailId"].string, let status = trail["trailStatus"].string, let date = trail["updatedAt"].int64 else { continue }

            let list = allTrails.filter { $0.id == id }
            print(name + " \(list.count)")
            
            
            // Check if we already have an entry for this trail. This is the normal case.
            if let index = allTrails.firstIndex(where: { $0.id == id }) {
                let seconds = (date / 1000)
                let lastUpdate = Date(timeIntervalSince1970: TimeInterval(seconds))
                allTrails[index].status = status
                allTrails[index].lastUpdate = lastUpdate
                allTrails[index].description = trail["description"].string
            } else if let name = trail["trailName"].string, let date = trail["updatedAt"].int64,
                      let lat_ = trail["latitude"].string, let lon_ = trail["longitude"].string,
                      let lat = Double(lat_), let lon = Double(lon_) {
                let seconds = (date / 1000)
                let lastUpdate = Date(timeIntervalSince1970: TimeInterval(seconds))
                let data = TrailData(name: name, id: id, lat: lat, lon: lon)
                data.status = status
                data.lastUpdate = lastUpdate
                data.description = trail["description"].string
                allTrails.append(data)
            }
        }
        NotificationCenter.default.post(name: Notif_TrailUpdate, object: nil)
        busy = false
    }
    
    
} // MORCdataProvider





