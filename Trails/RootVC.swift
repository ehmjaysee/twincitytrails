//
//  RootVC.swift
//  Trails 411
//
//  Created by Michael Chartier on 12/31/20.
//

import UIKit
//import Reachability


class RootVC: UIViewController
{

    @IBOutlet weak var O_spinner: UIActivityIndicatorView!
    
//    let reachability = try? Reachability()

    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        locationManager.startup()
        ckManager.start()        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "TrailsNav") as? UINavigationController {
            self.present( vc, animated: true, completion: nil )
        }
    }
    
}
