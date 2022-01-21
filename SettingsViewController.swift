//
//  SettingsViewController.swift
//  S2S Demo App
//
//  Created by Alimov, Dilyorbek (GfK) on 30.11.21.
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var optinSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let defaults = UserDefaults.standard
        
        optinSwitch.isOn = defaults.bool(forKey: "optin")
        title = "Settings"
    }
    
    @IBAction func optinSwitchChanged(_ sender: Any) {
        let defaults = UserDefaults.standard
        defaults.set(optinSwitch.isOn, forKey: "optin")
    }
}
