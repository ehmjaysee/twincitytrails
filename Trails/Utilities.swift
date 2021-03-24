//
//  Utilities.swift
//  SensorTag-1
//
//  Created by Michael Chartier on 4/9/17.
//  Copyright © 2017 Michael Chartier. All rights reserved.
//

import Foundation
import UIKit



// Data is extracted from various sources and then kept in a generic [X:Y] structure
struct XyDataType {
    var x: Double
    var y: Double
}

// App settings are stored on the local device (UserDefaults) and the user's private
// iCloud storate (NSUbiquitousKeyValueStore)
let iCloudKVS = NSUbiquitousKeyValueStore.default
let appDefaults = UserDefaults.standard

func linearRegression( data: [XyDataType] ) -> (Double, Double)
{
    guard (data.count > 1) else { return (0.0, 0.0) }
    
    // http://www.statisticshowto.com/probability-and-statistics/regression-analysis/find-a-linear-regression-equation/
    // y = a + bx
    // a = ((∑y)(∑x²) - (∑x)(∑xy)) / (n(∑x²) - (∑x)²)
    // b = (n(∑xy) - (∑x)(∑y)) / (n(∑x²) - (∑x)²)

    let n = Double(data.count)
    let xSum = data.map { $0.x }.reduce(0, +)
    let ySum = data.map { $0.y }.reduce(0, +)
    let xySum = data.map { $0.x * $0.y }.reduce(0, +)
    let xSquaresSum = data.map { $0.x * $0.x }.reduce(0, +)
    //let ySquaresSum = data.map { $0.y * $0.y }.reduce(0,+)

    let a = ((ySum * xSquaresSum) - (xSum * xySum)) / ((n * xSquaresSum) - (xSum * xSum))
    let b = ((n * xySum) - (xSum * ySum)) / ((n * xSquaresSum) - (xSum * xSum))

    return (a, b)
}

func pearsonCoefficient( data: [XyDataType] ) -> Double
{
    let count = Double(data.count)
    let sumX = data.map {$0.x}.reduce(0.0, +)
    let sumY = data.map {$0.y}.reduce(0.0, +)
    let sumXY = data.map {$0.x * $0.y}.reduce(0.0, +)
    let sumXX = data.map {$0.x * $0.x}.reduce(0.0, +)
    let sumYY = data.map {$0.y * $0.y}.reduce(0.0, +)
    
    let numerator = (count * sumXY) - (sumX * sumY)
    let denominator = sqrt(((count * sumXX) - (sumX * sumX)) * ((count * sumYY) - (sumY * sumY)))
    let r = numerator / denominator
    return r
}


// Debugging code execution speed
var debugTime: TimeInterval = 0.0
func timeDeltaReset() { debugTime = Date().timeIntervalSince1970 }
func timeDelta( _ label: String ) {
    let t2 = Date().timeIntervalSince1970
    let delta = t2 - debugTime
    print("⏱ " + label + ":\(delta)")
    debugTime = t2
}

func deleteURL( _ url: URL? )
{
    if let url = url, FileManager.default.fileExists(atPath: url.path) {
        try? FileManager.default.removeItem(at: url)
    }
}

// Return true if directory alread exists OR if we could create a new one.
// Otherwise return false.
func createDirectory( _ url: URL? ) -> Bool
{
    let fm = FileManager.default
    var retval = false

    if let url = url
    {
        var isDir : ObjCBool = false
        let doesExist = fm.fileExists(atPath: url.path, isDirectory: &isDir)
     
        if (doesExist == true) && (isDir.boolValue == true) {
            retval = true
        }

        if (doesExist == false) {
            do {
                try fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                retval = true
            } catch {
                retval = false
            }
        }
    }
    return retval
}

func deleteFilesWith( wildcard: String, path: URL )
{
    let fm = FileManager.default
    do {
        let contents = try fm.contentsOfDirectory( at: path, includingPropertiesForKeys: nil)
        for item in contents {
            if item.path.contains(wildcard) {
                try fm.removeItem(at: item)
            }
        }
    } catch {
        print("ERROR: deleteFilesWith")
    }
}

func dumpFolderContents( url: URL )
{
    let fm = FileManager.default
    do {
        let contents = try fm.contentsOfDirectory( at: url, includingPropertiesForKeys: nil)
        print(contents)
    } catch {
        print("ERROR: deleteFilesWith")
    }
}

func doAsync( vc: UIViewController, work: @escaping () -> Void, closure: (() -> Void)? = nil )
{
    var alertIsPresented = false
    let alert = busyIndicator("One moment...")
    vc.present(alert, animated: true, completion: { alertIsPresented = true })

    DispatchQueue.global(qos: .default).async {
        work()
        while (alertIsPresented == false) { sleep(1) }
        DispatchQueue.main.async { alert.dismiss(animated: true, completion: closure )}
    }
}

func busyIndicator( _ title: String ) -> UIAlertController
{
    // Display a popup alert before we start loading the file
    let alert = UIAlertController(title: title, message: "\n\n\n", preferredStyle: .alert)
    let spinner = UIActivityIndicatorView(frame: alert.view.bounds)
    // Set the spinner color to match the alert title color
    if alert.traitCollection.userInterfaceStyle == .dark {
        spinner.color = .white
    } else {
        spinner.color = .black
    }
    spinner.isUserInteractionEnabled = false
    spinner.startAnimating()
    spinner.translatesAutoresizingMaskIntoConstraints = false
    alert.view.addSubview(spinner)
    let bottom = alert.view.safeAreaLayoutGuide.bottomAnchor
    spinner.bottomAnchor.constraint(equalTo: bottom, constant: -30.0).isActive = true
    spinner.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor).isActive = true
    return alert
}

@discardableResult func doAlert(vc: UIViewController, title: String, message: String, fontSize: CGFloat? = nil, handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController
{
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default, handler: handler)
    alert.addAction(okAction)

    if let fontSize = fontSize {
        let messageFont = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize)]
        let messageAttrString = NSMutableAttributedString(string: message, attributes: messageFont)
        alert.setValue(messageAttrString, forKey: "attributedMessage")
    }
    vc.present(alert, animated: true, completion: nil)
    return alert
}

@discardableResult func doAlert(vc: UIViewController, title: String, message: String, handler: @escaping (() -> Void)) -> UIAlertController
{
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in handler() })
    alert.addAction(okAction)
    vc.present(alert, animated: true, completion: nil)
    return alert
}

@discardableResult func doAlert(title: String, message: String) -> UIAlertController?
{
    if let vc = topViewController() {
        return doAlert(vc: vc, title: title, message: message)
    }
    return nil
}

let networkErrorMessage = "There was a network problem, please check your network settings and try again later."
func presentNetworkError(vc: UIViewController) {
    doAlert(vc: vc, title: "Alert", message: networkErrorMessage)
}

// Display a series of errors one at a time
private var errorList = [String]()
private var errorTitle: String!

func displayErrors( title: String, errors: [String] )
{
    guard (errors.count > 0) else { return }

    // Make local copy of the errors
    errorList = errors
    errorTitle = title

    let action = UIAlertAction(title: "nil", style: .default, handler: nil)
    displayErrorsNext( alert: action )
}

func displayErrorsNext( alert: UIAlertAction )
{
    if errorList.count == 0 { return }

    let msg = errorList.remove(at: 0)

    if let vc = topViewController() {
        let alert = UIAlertController(title: errorTitle, message: msg, preferredStyle: .alert)
        if (errorList.count == 0) {
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        } else {
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: displayErrorCancel))
            alert.addAction(UIAlertAction(title: "Next", style: .default, handler: displayErrorsNext))
        }
        vc.present(alert, animated: true, completion: nil)
    }
}

func displayErrorCancel( alert: UIAlertAction ) {
    errorList.removeAll()
}

func doEarlyAlert( message: String )
{
    errorList.append(message)

    if errorList.count == 1 {
        // The first time we add a message to errorList we need to kick off a task that
        // will display the message in the root view controller.
        errorTitle = "Alert"
        displayEarlyAlert()
    }
}

func displayEarlyAlert()
{
    if topViewController() == nil {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            displayEarlyAlert()
        })
    } else {
        let action = UIAlertAction(title: "nil", style: .default, handler: nil)
        displayErrorsNext( alert: action )
    }
}

func topViewController(_ base: UIViewController? = nil) -> UIViewController?
{
    let rootVC: UIViewController
    
    if let base = base {
        rootVC = base
    } else if let topWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }), let vc = topWindow.rootViewController {
        rootVC = vc
    } else {
        return nil
    }
    
    if let nav = rootVC as? UINavigationController {
        return topViewController(nav.visibleViewController)
    }
    if let tab = rootVC as? UITabBarController {
        if let selected = tab.selectedViewController {
            return topViewController(selected)
        }
    }
    if let presented = rootVC.presentedViewController {
        return topViewController(presented)
    }
    return base
}

func saveValueToDefaults(_ value: Any?, forKey key: String)
{
    appDefaults.setValue(value, forKey: key)
}

// Input: Elapsed time in seconds (Int)
// Output: Formatted string: hh:mm:ss
func formatToHhMmSs( seconds: Int ) -> String
{
    let hh = seconds / (60 * 60)
    let mm = (seconds - (hh * 60 * 60)) / 60
    let ss = seconds - (hh * 60 * 60) - (mm * 60)
    let timeString = String(format: "%02d:%02d:%02d", hh, mm, ss)
    return timeString
}

func formatToMmSs( seconds: Int ) -> String
{
    let mm = seconds / 60
    let ss = seconds - (mm * 60)
    let timeString = String(format: "%02d:%02d", mm, ss)
    return timeString
}

func formatToHhMmSsPlus( time: TimeInterval ) -> String
{
    let seconds = Int(floor(time))
    let hh = seconds / (60 * 60)
    let mm = (seconds - (hh * 60 * 60)) / 60
    let ss = seconds - (hh * 60 * 60) - (mm * 60)
    let plus = Int((time - TimeInterval(seconds)) * 100.0)
    let timeString = String(format: "%02d:%02d:%02d.%02d", hh, mm, ss, plus)
    return timeString
}

// Determine the runtime environment 
enum AppConfiguration {
    case Debug
    case TestFlight
    case AppStore
}

struct Config {
    // This is private because the use of 'appConfiguration' is preferred.
    private static let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"

    // This can be used to add debug statements.
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    // AppConfiguration tells us the runtime environment: TestFlight | Debug | AppStore
    static var appConfiguration: AppConfiguration {
        if isDebug {
            return .Debug
        } else if isTestFlight {
            return .TestFlight
        } else {
            return .AppStore
        }
    }
}

// If the user is running OS older than iOS 13 then we need to 'fix' the colors
// of the segment controls.
func segmentControlColorFixRequired() -> Bool {
    let flag =  ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 13, minorVersion: 0, patchVersion: 0))
    return !flag
}

func displayWarningMessage( view: UIView, message: String ) -> UILabel
{
    let label = UILabel(frame: view.frame)
    label.text = message
    label.textColor = .white
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 0
    label.textAlignment = .center
    label.layer.borderColor = UIColor.white.cgColor
    label.layer.borderWidth = 1.0
    view.addSubview(label)
    label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    let size = label.intrinsicContentSize
    label.widthAnchor.constraint(equalToConstant: size.width + 20 ).isActive = true
    label.heightAnchor.constraint(equalToConstant: size.height + 12).isActive = true
    return label
}

extension TimeInterval
{
    var toPreciseString: String {
        let seconds = Int(floor(self))
        let hh = seconds / (60 * 60)
        let mm = (seconds - (hh * 60 * 60)) / 60
        let ss = seconds - (hh * 60 * 60) - (mm * 60)
        let plus = Int((self - TimeInterval(seconds)) * 100.0)
        if hh > 0 {
            return String(format: "%d:%02d:%02d.%02d", hh, mm, ss, plus)
        } else if mm > 0 {
            return String(format: "%d:%02d.%02d", mm, ss, plus)
        } else {
            return String(format: "%d.%02d", ss, plus)
        }
    }
}

import CoreLocation

extension CLLocationCoordinate2D {
    var displayString: String {
        return String(latitude) + "," + String(longitude)
    }
}


extension UIBarButtonItem
{
    func hide() {
        tintColor = UIColor.clear
    }
//    func unhide() {
//        tintColor = MItintColor
//    }
}
