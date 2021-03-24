//
//  AppDelegate.swift
//  Trails 411
//
//  Created by Michael Chartier on 12/31/20.
//

import UIKit
import CoreData
import UserNotifications


@main
class AppDelegate: UIResponder, UIApplicationDelegate
{
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        // Assign this class as the delegate for User Notifications
        UNUserNotificationCenter.current().delegate = self

        // This app receives notifications from CloudKit when the DataLogger app updates records in the public database.
        // Register early to receive these notifications becuase the app may have been launched due to a notification
        // so we must be ready for it.
        // NOTE: during testing it seemed that remote notifications would not be received unless we call
        // requestAuthorization() prior to calling registerForRemoteNotifications() even if the user already
        // gave permission to use notificaitons.
        if (appDefaults.bool(forKey: Defaults.notificationAuth) == true) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
                authorized, error in
                if let error = error {
                    print(error)
                }
                if authorized == true {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        }
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Trails_411")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

} // class AppDelegate


extension AppDelegate
{
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Function: \(#function), line: \(#line)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Function: \(#function), line: \(#line)")
        print(error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        NSLog(#function + " \(userInfo)")
        
        // Parse the userInfo dictionary and extract all the data fields we expect to receive for a CloudKit subscription notification
        if let ckNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)! as? CKQueryNotification,
           let args = ckNotification.alertLocalizationArgs, args.count >= 2 {
            let message = args[0] + " is now " + args[1]
            scheduleNotification(message: message)
        }

        MORCdata.update()

        // Wait a second for the processing to finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completionHandler(UIBackgroundFetchResult.noData)
        }
    }
        
    private func scheduleNotification(message: String)
    {
        print(#function + message)
        
        let content = UNMutableNotificationContent()
        content.title = message
//        content.subtitle = message
//        content.body = "body of messager"
        content.sound = UNNotificationSound.default
        // content.badge = 1
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print("Error \(error.localizedDescription)")
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate
{
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // User tapped on a notification
        print(#function)
        DispatchQueue.main.async {
            // navigate to the main UI
            //debug
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        // Notification arrived while the app was in the foreground mode
        print(#function)
        completionHandler([.alert, .badge, .sound])
    }
    
}

