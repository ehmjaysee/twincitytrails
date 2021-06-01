//
//  CoreDataManager.swift
//  MotionIQ
//
//  Created by Michael Chartier on 6/13/19.
//  Copyright © 2019 Motion Instruments. All rights reserved.
//

import Foundation
import CoreData


let cdm = CoreDataManager.shared

class CoreDataManager
{
    // Singleton
    static let shared = CoreDataManager()
    private init() { }

    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Trails")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("CoreData Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    func addTrailData( name: String )
    {
        // Create a new data record for this bike.
        // Copy bike settings into the new record and save it.
        // Finally we retreive a new copy of the bike collection
        let managedContext = persistentContainer.viewContext
        let newEntity = NSEntityDescription.entity(forEntityName: "TrailDataStore", in: managedContext)!
        let newObject = NSManagedObject(entity: newEntity, insertInto: managedContext)
        newObject.setValue(name, forKey: "name")
        saveContext()
    }

    func saveContext ()
    {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("CoreData Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    func getTrailData() -> [TrailDataStore]
    {
        let managedContext = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<TrailDataStore> = TrailDataStore.fetchRequest()
        var fetchResults = [TrailDataStore]()

        do {
            fetchResults = try managedContext.fetch(fetchRequest)
            if fetchResults.count == 0 {
                fatalError()
            }
        } catch {
            print("CoreData retrieve failed")
        }
        return fetchResults
    }

}
