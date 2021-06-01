//
//  TrailData.swift
//  Trails 411
//
//  Created by Michael Chartier on 12/31/20.
//

import Foundation
import CoreLocation
import MapKit



class TrailData
{
    var id: String
    var name: String
    var status: String?
    var lastUpdate: Date?
    var trailhead: CLLocation
    var description: String?
    var distance: Double?
    var travelTime: TimeInterval?
    var TrailForksPage: String?
    var MORCpage: String?
    var filename: String?
    
    // COMPUTED PROPERTIES
    private var subKey: String {
        let key = id + "sub"
        return key
    }
    var subscriptionId: String? {
        get { return appDefaults.string(forKey: subKey) }
        set {
            if newValue == nil {
                appDefaults.removeObject(forKey: subKey)
            } else {
                appDefaults.setValue(newValue, forKey: subKey)
            }
        }
    }
    var isSubscribed: Bool { return (subscriptionId != nil )}
    var subscriptionRequested = false
    var isOpen: Bool {
        if let status = status, status.caseInsensitiveCompare("open") == .orderedSame {
            return true
        } else {
            return false
        }
    }
    var howOld: String {
        if let lastUpdate = lastUpdate {
            let diff = Calendar.current.dateComponents([.day, .hour], from: lastUpdate, to: Date())
            if let days = diff.day, days > 1 {
                return String(days) + " days ago"
            } else if let hours = diff.hour {
                return String(hours) + " hours ago"
            } else {
                let shortDate = DateFormatter()
                shortDate.dateStyle = .medium
                return shortDate.string(from: lastUpdate)
            }
        } else {
            return " "
        }
    }
    
    private var favoriteKey: String {
        let key = id + "favorite"
        return key
    }
    var isFavorite: Bool {
        get { return appDefaults.bool(forKey: favoriteKey) }
        set { appDefaults.setValue(newValue, forKey: favoriteKey) }
    }

    init( name: String, id: String, lat: Double, lon: Double ) {
        self.id = id
        self.name = name
        self.trailhead = CLLocation(latitude: lat, longitude: lon)
        self.estimateTravelDistanceToRider()
        self.subscriptionRequested = isSubscribed
        NotificationCenter.default.addObserver(self, selector: #selector(locationUpdate(notification:)), name: Notif_LocationUpdate, object: nil)
    }
    
    init( name: String, id: String, lat: Double, lon: Double, TrailForks: String? = nil, MORC: String? = nil, filename: String? = nil ) {
        self.id = id
        self.name = name
        self.trailhead = CLLocation(latitude: lat, longitude: lon)
        self.estimateTravelDistanceToRider()
        self.TrailForksPage = TrailForks
        self.MORCpage = MORC
        self.filename = filename
        self.subscriptionRequested = isSubscribed
        NotificationCenter.default.addObserver(self, selector: #selector(locationUpdate(notification:)), name: Notif_LocationUpdate, object: nil)
    }
    
    private func estimateTravelDistanceToRider()
    {
        guard let myLocation = locationManager.lastLockedLocation else { return }
        
        // Get the travel time estimate from Apple MapKit
        //todo: Use MapBox for better estimates
        let request         = MKDirections.Request()
        let source          = MKPlacemark(coordinate: myLocation.coordinate)
        let destination     = MKPlacemark(coordinate: trailhead.coordinate)
        request.source      = MKMapItem(placemark: source)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = MKDirectionsTransportType.automobile;
        request.requestsAlternateRoutes = false
        let directions = MKDirections(request: request)
        directions.calculateETA { (response, error) in
            if let error = error {
                print("ETA \(error)")
            } else if let response = response {
                print("ETA \(response.expectedTravelTime)s \(response.distance)m")
                self.travelTime = response.expectedTravelTime
                self.distance = response.distance
                NotificationCenter.default.post(name: Notif_TrailUpdate, object: self.id)
            }
        }
    }

    @objc func locationUpdate( notification: NSNotification )
    {
        // We get this notification when our location is determined for first time -AND- when it changes significantly
        self.estimateTravelDistanceToRider()
    }
}

var allTrails: [TrailData] = [
    TrailData(name: "Battle Creek", id: "3b716fa1-af6b-4aa8-aff1-11ff473072d1", lat: 44.935152, lon: -93.028736,
              TrailForks: "region/battle-creek-5538/",
              MORC: "trail/7053070/battle-creek-loop-from-lower-parking-lot",
              filename: "battle-creek"),
    TrailData(name: "Bertram Chain of Lakes", id: "2b741916-94ba-418e-b468-12bc0c14c2ff", lat: 45.283222, lon: -93.852944,
              TrailForks: "region/bertram-chain-of-lakes-13707/",
              MORC: "trail/3505586/bertram-chain-of-lakes",
              filename: "bertram"),
    TrailData(name: "Carver Lake Park", id: "41ecd511-9274-45a0-957f-8cab16012e9f", lat: 44.90311699999999, lon: -92.979422,
              TrailForks: "region/carver-lake-park/",
              MORC: "trail/3520161/carver-lake-park",
              filename: "carver" ),
    TrailData(name: "Cottage Grove", id: "25e0fce0-9777-4623-9897-ae57fa2dcc39", lat: 44.844915, lon: -92.967131,
              TrailForks:  "skillpark/cottage-grove-bike-park/",
              MORC: "trail/7000927/cottage-grove-bike-park",
              filename: "cottage-grove" ),
    TrailData(name: "Elm Creek", id: "d932e5fc-a4a4-4e33-820d-864556d0c0ec", lat: 45.180928, lon: -93.415879,
              TrailForks: "region/elm-creek-park/",
              MORC: "trail/4403021/elm-creek-10-mile-ride",
              filename: "elm-creek" ),
    TrailData(name: "Hillside Park", id: "ec5949d8-b11a-4b1c-a659-22fbf7577b64", lat: 45.299075, lon: -93.539913,
              MORC: "trail/3680808/hillside",
              filename: "hillside" ),
    TrailData(name: "Lake Rebecca", id: "10e3fba6-063b-46af-a1af-22184be83cd1", lat: 45.068713, lon: -93.754863,
              TrailForks: "region/lake-rebecca-12004/",
              MORC: "trail/7024093/lake-rebecca-loop",
              filename: "lake-rebecca" ),
    TrailData(name: "Lebanon Hills", id: "2cce9ec0-a0aa-41ca-9348-9849803fe7b3", lat: 44.7822821, lon: -93.1898107,
              TrailForks: "region/lebanon-hills/",
              MORC: "trail/3794768/lebanon-hills-beginner-and-intermediate",
              filename: "lebanon" ),
    TrailData(name: "Lone Lake Park", id: "31044f9c-d539-4b16-b22f-29ea0a288642", lat: 44.9, lon: -93.43,
              TrailForks: "region/lone-lake-park-42675/",
              filename: "lone-lake" ),
    TrailData(name: "Minnesota River Bottoms", id: "ef3854d5-73b6-47c1-bf31-4efe21e4fee1", lat: 44.8021249, lon: -93.2898827,
              TrailForks:  "region/minnesota-river-trail-12006/",
              MORC: "trail/7016269/minnesota-river-bottoms",
              filename: "mn-river-bottoms" ),
    TrailData(name: "Monarch Singletrack", id: "dbef1a89-e0a9-46fb-94a6-4eb68b4aec0a", lat: 44.8779294, lon: -93.7192217,
              TrailForks: "region/carver-park-reserve-41480/",
              filename: "monarch" ),
    TrailData(name: "Murphy Hanrehan", id: "071c3aba-f614-4801-b447-c9ba215c6482", lat: 44.724282, lon: -93.348202,
              TrailForks: "region/murphyhanrehan-park/",
              MORC: "trail/3522002/murphy-hanrehan",
              filename: "murphy" ),
    TrailData(name: "Salem Hills", id: "1bfd110a-bc33-4024-a62f-cad5702fac81", lat: 44.865674, lon: -93.073265,
              TrailForks: "region/salem-hills-12008/",
              MORC: "trail/7028094/salem-hills-mtn-bike-trail",
              filename: "salem" ),
    TrailData(name: "Sunfish Lake Park", id: "ff41d044-a495-4a11-a9ed-b1e6265377e4", lat: 45.002523, lon: -92.903667,
              TrailForks: "region/sunfish-lake-park-34298/",
              filename: "sunfish" ),
    TrailData(name: "Terrace Oaks", id: "07ade61a-4969-45f8-be64-fe8b135376de", lat: 44.7744386, lon: -93.2385644,
              TrailForks: "region/terrace-oaks-12011/",
              MORC: "trail/4350735/terrace-oaks-trail",
              filename: "terrace"),
    TrailData(name: "Theodore Wirth", id: "4c82f3f0-9f45-4e16-a436-f490fbea81a4", lat: 44.990429, lon: -93.326324,
              TrailForks: "region/theodore-wirth-park/",
              MORC: "trail/721506/north-loop",
              filename: "theo")
    
]


/*
 [
   {
     "trailName": "Battle Creek",
     "trailId": "3b716fa1-af6b-4aa8-aff1-11ff473072d1",
     "createdAt": 1519053269271,
     "updatedBy": "us-east-2:519ad06c-93fe-4939-930f-5f503d56d624",
     "state": "Minnesota",
     "city": "St Paul",
     "zipcode": "55119",
     "trailStatus": "Closed",
     "updatedAt": 1608739900424,
     "longitude": "-93.0216788",
     "description": null,
     "latitude": "44.936068",
     "street": "Battle Creek Rd"
   },
   {
     "trailName": "Bertram Chain of Lakes",
     "trailId": "2b741916-94ba-418e-b468-12bc0c14c2ff",
     "createdAt": 1519053311026,
     "updatedBy": "us-east-2:8ce3a4da-d463-4de1-99b1-73e57c783a97",
     "state": "Minnesota",
     "city": "Monticello",
     "zipcode": "55362",
     "trailStatus": "Open",
     "updatedAt": 1609024471157,
     "longitude": "-93.8574287",
     "description": "We were out grooming the trail today, here is a condition update:\n\nKickstart: machine groomed\nKickstart return: snowshoe groomed - use extreme caution around a huge branch that came down and is standing up in the trail\nKame: mostly ungroomed, light snowshoe grooming in parts, last 1/3 has some good snowshoe groom\nSoggy bottoms: snowshoe groomed\nEverything heading to NE creek bridge from pinched corner: machine groomed\nEverything heading to pinched corner from NE creek bridge: snowshoe groomed\nLochness section: machine groomed\nEverything north of creek bridge to YMCA area: machine groomed\nGravity Cavity Returns: not groomed\nEsker section: not groomed\nLakeside: not groomed\nHuck Harbor: lightly snowshoe groomed\n\nOverall, riding from the lot to the NE creek bridge and back on the east side is all nicely groomed except for part of the Kame trail.  The loop around the lakes from the NE creek bridge is groomed up to the YMCA area near the archery range, and mostly ungroomed after that.\n\nThe entrance to the trail from the lot has been left ungroomed to try to dissuade the army of boot hikers from taking the singletrack.\n\nHope this helps with a condition update.  Unfortunately there were a lot of boot hikers on the singletrack during and after our grooming.  We had it very nice and smooth, but it is undoubtedly already quite rough and post holed.  Getting some fatbike traffic on the trail should help smooth out all the boot holes.  The ungroomed sections of trail will be passable for the veteran riders and those that run low enough tire pressure.",
     "latitude": "45.283094",
     "street": "1744 90th Street NE"
   },
   {
     "trailName": "Carver Lake Park",
     "trailId": "41ecd511-9274-45a0-957f-8cab16012e9f",
     "createdAt": 1519053213124,
     "updatedBy": "us-east-2:2b050f4e-50f2-4272-bddb-7846393d05bc",
     "state": "Minnesota",
     "city": "Woodbury",
     "zipcode": "55125",
     "trailStatus": "Open",
     "updatedAt": 1608766330811,
     "longitude": "-92.979422",
     "description": "Trail open at 4pm.  Be careful on Christmas Eve with the cold temps.\nNo grooming will take place tonight due to the strong winds.\nWinter Trail Rules are in place now:\nAllowed:  Snowshoes, Bikes with at least 3\" tires until packed, 2\" after the trail is packed.\nNot Allowed:  Hiking/trail running without snowshoes, Bicycles with less than 2\" tires.  Narrow tires and foot traffic chew up the snow and creates poor trail conditions.",
     "latitude": "44.90311699999999",
     "street": "3175 Century Ave S"
   },
   {
     "trailName": "Cottage Grove Bike Park",
     "trailId": "25e0fce0-9777-4623-9897-ae57fa2dcc39",
     "createdAt": 1519053610443,
     "updatedBy": "us-east-2:c6c41514-ac3b-4944-b798-6feac160a5c3",
     "state": "Minnesota",
     "city": "Cottage Grove",
     "zipcode": "55016",
     "trailStatus": "Closed",
     "updatedAt": 1607190326834,
     "longitude": "-92.9699413",
     "description": "Paved pump track may be rideable at times but we are done checking the park until spring",
     "latitude": "44.8473887",
     "street": "7050 Meadow Grass Avenue South"
   },
 {
   "trailName": "Elm Creek",
   "trailId": "d932e5fc-a4a4-4e33-820d-864556d0c0ec",
   "createdAt": 1519053163567,
   "updatedBy": "us-east-2:d31df64e-ac8c-416d-a2e5-4e29b1169455",
   "state": "Minnesota",
   "city": "Champlin",
   "zipcode": "55316",
   "trailStatus": "Open",
   "updatedAt": 1609107404922,
   "longitude": "-93.4167322",
   "description": "We will be grooming at 6 PM tonight please try to be off the trail by then we would like it to set up for 12 hours with no traffic thanks",
   "latitude": "45.1807175",
   "street": "1827 W Hayden Lake Rd"
 },
 {
   "trailName": "Hillside Park",
   "trailId": "ec5949d8-b11a-4b1c-a659-22fbf7577b64",
   "createdAt": 1519053651575,
   "updatedBy": "us-east-2:312a7571-f4f7-4b48-8fc9-4ebea90a21cc",
   "state": "Minnesota",
   "city": "Elk River",
   "zipcode": "55330",
   "trailStatus": "Open",
   "updatedAt": 1608810608997,
   "longitude": "-93.539913",
   "description": "Snowshoes or Low tire  pressure fat bike will be your weapon of choice if you decide to go out in the extreme cold.",
   "latitude": "45.299075",
   "street": "10801 181st Ave NW"
 },
 {
   "trailName": "Lake Rebecca",
   "trailId": "10e3fba6-063b-46af-a1af-22184be83cd1",
   "createdAt": 1519053687203,
   "updatedBy": "us-east-2:5dd752ed-b5ca-4489-b538-2be42dc1d1cb",
   "state": "Minnesota",
   "city": "Rockford",
   "zipcode": "55373",
   "trailStatus": "Open",
   "updatedAt": 1608834073984,
   "longitude": "-93.7589576",
   "description": "Gates are OPEN. This snow is a wonderful Christmas present! Weâ€™ll probably start grooming this weekend after the holiday. The trail is available for motor boating in the meantime.",
   "latitude": "45.0717787",
   "street": "9831 Rebecca Park Trail"
 },
 {
   "trailName": "Lebanon Hills",
   "trailId": "2cce9ec0-a0aa-41ca-9348-9849803fe7b3",
   "createdAt": 1519053352023,
   "updatedBy": "us-east-2:f16c14a9-3351-43fd-8ac8-60e9ecd2ea4f",
   "state": "Minnesota",
   "city": "Eagan",
   "zipcode": "55122",
   "trailStatus": "Open",
   "updatedAt": 1609124285895,
   "longitude": "-93.1898107",
   "description": "Open. Sunday update - packed pretty will in most places. Guessing all tires sizes would be fine for having a fun ride without much struggle.\nRemember, let's try to keep parking lot salt off the trail by riding thru the skill park before entering the main trail.",
   "latitude": "44.7822821",
   "street": "4801 Johnny Cake Ridge Road"
 },
 {
   "trailName": "Lone Lake Park",
   "trailId": "31044f9c-d539-4b16-b22f-29ea0a288642",
   "createdAt": 1606857029536,
   "updatedBy": "us-east-2:f9d5d504-3bbf-496e-8614-c5092dabeb1a",
   "state": "Minnesota",
   "city": "Minnetonka",
   "zipcode": "55343",
   "trailStatus": "Open",
   "updatedAt": 1609196825567,
   "longitude": "-93.43",
   "description": "Much better fat biking today at LLP. Calling it hero snow! Go get some!",
   "latitude": "44.9",
   "street": " 5624 Shady Oak Rd"
 },
 {
   "trailName": "Minnesota River Trail",
   "trailId": "ef3854d5-73b6-47c1-bf31-4efe21e4fee1",
   "createdAt": 1519053397303,
   "updatedBy": "us-east-2:423e5f5d-91ea-4838-9043-b39dd1749d21",
   "state": "Minnesota",
   "city": "Bloomington",
   "zipcode": "55420",
   "trailStatus": "Open",
   "updatedAt": 1609170511403,
   "longitude": "-93.2898827",
   "description": "Great winter riding conditions. ",
   "latitude": "44.8021249",
   "street": "11115 Lyndale Ave S"
 },
 {
   "trailName": "Monarch Singletrack",
   "trailId": "dbef1a89-e0a9-46fb-94a6-4eb68b4aec0a",
   "createdAt": 1600964671078,
   "updatedBy": "us-east-2:592c2995-755f-4905-9653-f2d65cd2552f",
   "state": "Minnesota",
   "city": "Waconia",
   "zipcode": "55387",
   "trailStatus": "Open",
   "updatedAt": 1608838683882,
   "longitude": "-93.7192217",
   "description": null,
   "latitude": "44.8779294",
   "street": "Monarch Singletrack Trailhead"
 },
 {
   "trailName": "Murphy Hanrehan",
   "trailId": "071c3aba-f614-4801-b447-c9ba215c6482",
   "createdAt": 1519053439785,
   "updatedBy": "us-east-2:592c2995-755f-4905-9653-f2d65cd2552f",
   "state": "Minnesota",
   "city": "Savage",
   "zipcode": "55372",
   "trailStatus": "Open",
   "updatedAt": 1608779248853,
   "longitude": "-93.3434754",
   "description": "Fresh snow with plenty of drifting. Have fun! ",
   "latitude": "44.7189598",
   "street": "15501 Murphy Lake Road"
 },
 {
   "trailName": "Salem Hills",
   "trailId": "1bfd110a-bc33-4024-a62f-cad5702fac81",
   "createdAt": 1519053487375,
   "updatedBy": "us-east-2:cb172ff7-128f-4e28-b430-e15aee5eda60",
   "state": "Minnesota",
   "city": "Inver Grove Heights",
   "zipcode": "55077",
   "trailStatus": "Open",
   "updatedAt": 1607351491503,
   "longitude": "-93.0745164",
   "description": "Despite being above freezing, the trail was fully dry Sunday afternoon 12/6.  Excellent, fast conditions.",
   "latitude": "44.8676308",
   "street": "1642 Upper 55th St"
 },
 {
   "trailName": "Sunfish Lake Park",
   "trailId": "ff41d044-a495-4a11-a9ed-b1e6265377e4",
   "createdAt": 1597024341073,
   "updatedBy": "us-east-2:88ee8ddb-e883-4cab-bec3-ddbfb42d9106",
   "state": "Minnesota",
   "city": "Lake Elmo",
   "zipcode": "55042",
   "trailStatus": "Open",
   "updatedAt": 1609002927496,
   "longitude": "-92.914928",
   "description": "Trail is groomed and ready to ride! ",
   "latitude": "45.0037331",
   "street": "3554 Kelvin Ave N"
 },
 {
   "trailName": "Terrace Oaks",
   "trailId": "07ade61a-4969-45f8-be64-fe8b135376de",
   "createdAt": 1519053528171,
   "updatedBy": "us-east-2:2a9a6abf-38ce-4001-95d3-9af0af2188d5",
   "state": "Minnesota",
   "city": "Burnsville",
   "zipcode": "55337",
   "trailStatus": "Closed",
   "updatedAt": 1604252087958,
   "longitude": "-93.2385644",
   "description": "Terrace Oaks has closed for the season.  It is open starting April 1(conditions permitting) and closes 10/31.",
   "latitude": "44.7744386",
   "street": "Terrace Oaks Park"
 },
 {
   "trailName": "Theodore Wirth",
   "trailId": "4c82f3f0-9f45-4e16-a436-f490fbea81a4",
   "createdAt": 1519053568021,
   "updatedBy": "us-east-2:a315d0b2-9657-4d3f-81d2-fd7899cad453",
   "state": "Minnesota",
   "city": "Minneapolis",
   "zipcode": "55422",
   "trailStatus": "Open",
   "updatedAt": 1609117248896,
   "longitude": "-93.325502",
   "description": "All MOCA/MORC trail sections at Theo are open and in pretty significant need of packing.  \nSnow shoes do this best.  Next are fat bikes at very low pressure.\nA couple of us snowshoed all of North Loop (except for XX), Glenwood and Southwest Wirth this weekend, but it honestly needs many snowshoes to make a real impact.  With more snow forecast on Tuesday, it would be great to get what is out there now smooshed a much as possible.\n\nSteve\n\n",
   "latitude": "44.9923964",
   "street": "1301 Theodore Wirth Parkway"
 }
]

 */
