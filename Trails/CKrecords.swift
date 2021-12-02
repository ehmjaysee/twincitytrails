//
//  CKrecords.swift
//  Trails 411
//
//  Created by Michael Chartier on 2/15/21.
//

import Foundation
import CloudKit
import UserNotifications
import Reachability


// Default CloudKit Container used by this app
let ckContainer = CKContainer.init(identifier: "iCloud.com.ehmjaysee.Trails-411")

// Complete list of keys we use to index into the cloud kit records
enum MyCloudKitKeys: String {
    // CustomerRecord
    case name
    case status
}

extension CKRecord
{
    subscript(key: MyCloudKitKeys) -> Any? {
        get { return self[key.rawValue] }
        set { self[key.rawValue] = newValue as? CKRecordValue }
    }
}

class CKtrail: NSObject
{
    let ckRecord: CKRecord
    var name: String { return ckRecord[.name] as? String ?? "?" }
    var status: String { return ckRecord[.status] as? String ?? "?" }
    var id: String { return ckRecord.recordID.recordName }

    // Creating objects from CloudKit records
    init( ckRecord: CKRecord )
    {
        self.ckRecord = ckRecord
        super.init()
    }


} // class CKtrail

let ckManager = CKmanager.shared

class CKmanager
{
    // Singleon
    static let shared = CKmanager()
    private init() { }  // private ensures this class will be a singleton

    
    
    // CloudKit
    let container = ckContainer
    var ckStatus = CKAccountStatus.couldNotDetermine
    var notificationAuth: UNAuthorizationStatus?
    var subCount = 0
    var subCounter = 0
    let reachability = try? Reachability()

    // Change this version number any time we change the format of any CloudKit subscription.
    // This will force the code to delete the old subscriptions and replace with new.
    let currentSubscriptionVersion = 1

    func start()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(ckAccountChanged), name: Notification.Name.CKAccountChanged, object: nil)

        ckFetchStatus()
        
        // Handle network connection status changes
        reachability?.whenReachable = { status in
            //self.databaseInit()
            //self.iCloudKVS_init()
        }
        try? reachability?.startNotifier()
    }

    func updateSubscriptions()
    {
        for item in allTrails {
            if (item.subscriptionRequested == true) && (item.isSubscribed == false) {
                createSubscription( trail: item )    // create new subscription
            } else if item.isSubscribed && (item.subscriptionRequested == false) {
                // delete subscription
                deleteSubscription( trail: item )
            }
        }
    }
    
    //-------------------------------------------------------------------------------
    // MARK: Private Functions
    //-------------------------------------------------------------------------------

    @objc private func ckAccountChanged() { ckFetchStatus() }

    private func ckFetchStatus()
    {
        ckContainer.accountStatus { status, error in
            if let error = error {
                print("CK accountStatus " + error.localizedDescription)
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self.ckFetchStatus()
                }
            } else {
                // We received valid status.
                if (status == .available) && (self.ckStatus != .available) {
                    // Status is good. Check our subscription status.
                    self.initSubscriptions()
                }
                self.ckStatus = status
            }
        }
    }

    //-------------------------------------------------------------------------------
    // MARK: CloudKit Subscription Management
    //-------------------------------------------------------------------------------

    private func initSubscriptions()
    {
        // In version 2 we changed the way we store subscription flags
        if ckSubVersion < 2 {
            for item in allTrails {
                item.subscriptionRequested = item.isSubscribed
            }
        }
        
        // When the version number changes we must delete and re-create all subscriptions in our cloudkit database
        if ckSubVersion != currentSubscriptionVersion {
            // Delete all cached subscription IDs
            for item in allTrails {
                item.subscriptionId = nil
            }
            deleteAllSubscriptions() {
                // Re-Create subscriptions desired by the user
                self.updateSubscriptions()
                // Restore is complete
                ckSubVersion = self.currentSubscriptionVersion
            }
        }
    }

    private func deleteAllSubscriptions( completion: @escaping () -> Void )
    {
        // Fetch all subscriptions for this user, then delete each one
        container.publicCloudDatabase.fetchAllSubscriptions() { subscriptions, error in
            if let error = error {
                print(#function + " " + error.localizedDescription)
            } else if let subscriptions = subscriptions {
                var count = 0
                for subscription in subscriptions {
                    self.container.publicCloudDatabase.delete(withSubscriptionID: subscription.subscriptionID) {
                        message, error in
                        if let error = error {
                            print("SUB DELETE ERROR " + error.localizedDescription)
                        } else {
                            count += 1
                            if count == subscriptions.count {
                                // All subscriptions are now deleted
                                completion()
                            }
                        }
                    }
                }
            } else {
                completion()
            }
        }
    }

    private func createSubscription( trail: TrailData )
    {
        let predicate = NSPredicate(format: "recordID = %@", CKRecord.ID(recordName: trail.id))
        let subscription = CKQuerySubscription(recordType: "Trail", predicate: predicate, options: .firesOnRecordUpdate)
        let info = CKSubscription.NotificationInfo()
        info.alertLocalizationKey = "%1$@ is now %2$@"
        info.alertLocalizationArgs = ["name", "status"]
        info.soundName = "default"
        subscription.notificationInfo = info

        container.publicCloudDatabase.save(subscription) {
            savedSubscription, error in
            if let error = error {
                print(#function + error.localizedDescription)
            } else {
                print("Created sub for \(trail.name)")
            }
            trail.subscriptionId = savedSubscription?.subscriptionID
        }
    }
    
    private func deleteSubscription( trail: TrailData )
    {
        guard let id = trail.subscriptionId else { return }
        
        self.container.publicCloudDatabase.delete(withSubscriptionID: id) {
            message, error in
            if let error = error {
                print("SUB DELETE ERROR " + error.localizedDescription)
            } else {
                // Delete was successful. The subscriptionId is no longer valid.
                trail.subscriptionId = nil
            }
            if let msg = message {
                print("SUB DELETE MSG " + msg)
            }
        }
    }
    
}
