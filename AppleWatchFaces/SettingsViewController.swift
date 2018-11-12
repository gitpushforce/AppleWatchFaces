//
//  ViewController.swift
//  AppleWatchFaces
//
//  Created by Michael Hill on 10/17/18.
//  Copyright © 2018 Michael Hill. All rights reserved.
//

import UIKit
import WatchConnectivity

class SettingsViewController: UIViewController, WCSessionDelegate {
    
    @IBOutlet var errorMessageLabel: UILabel!
    
    var session: WCSession?
    var watchPreviewViewController:WatchPreviewViewController?
    var watchSettingsTableViewController:WatchSettingsTableViewController?
    static var currentClockSetting: ClockSetting = ClockSetting.defaults()
    var currentClockIndex = 1
    
    static let settingsChangedNotificationName = Notification.Name("settingsChanged")
    
    func showError( errorMessage: String) {
        DispatchQueue.main.async {
            self.errorMessageLabel.textColor = UIColor.red
            self.errorMessageLabel.text = errorMessage
            
            self.errorMessageLabel.alpha = 1.0
            UIView.animate(withDuration: 1.0, delay: 3.0, options: UIView.AnimationOptions.curveEaseIn, animations: {
                self.errorMessageLabel.alpha = 0.0
            }) { (completed) in
                //
            }
        }
    }
    
    func showMessage( message: String) {
        DispatchQueue.main.async {
            self.errorMessageLabel.textColor = UIColor.lightGray
            self.errorMessageLabel.text = message
            
            self.errorMessageLabel.alpha = 1.0
            UIView.animate(withDuration: 1.0, delay: 3.0, options: UIView.AnimationOptions.curveEaseIn, animations: {
                self.errorMessageLabel.alpha = 0.0
            }) { (completed) in
                //
            }
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        //debugPrint("session activationDidCompleteWith")
        showMessage( message: "Watch session active.")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        //debugPrint("session sessionDidBecomeInactive")
        showError(errorMessage: "Watch session became inactive.")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        //debugPrint("session sessionDidDeactivate")
        showError(errorMessage: "Watch session deactivated.")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is WatchPreviewViewController {
            let vc = segue.destination as? WatchPreviewViewController
            watchPreviewViewController = vc
        }
        if segue.destination is WatchSettingsTableViewController {
            let vc = segue.destination as? WatchSettingsTableViewController
            watchSettingsTableViewController = vc
        }
    }
    
    @IBAction func sendSettingAction(sender: UIButton) {
        //debugPrint("sendSetting tapped")
        if let validSession = session, let jsonData = SettingsViewController.currentClockSetting.toJSONData() {
            
            validSession.sendMessageData(jsonData, replyHandler: { reply in
                //debugPrint("reply")
                self.showMessage( message: "Watch replied success.")
            }, errorHandler: { error in
                //debugPrint("error: \(error)")
                self.showError(errorMessage: error.localizedDescription)
            })
            
        } else {
            self.showError(errorMessage: "No valid watch session")
        }
    }
    
    @objc func onNotification(notification:Notification)
    {
        redrawPreviewClock()
    }
    
    func redrawPreviewClock() {
        //tell preview to reload
        if watchPreviewViewController != nil {
            watchPreviewViewController?.redraw()
            self.showMessage( message: SettingsViewController.currentClockSetting.title)
        }
    }
    
    func redrawSettingsTable() {
        //tell the settings table to reload
        if watchSettingsTableViewController != nil {
            watchSettingsTableViewController?.selectCurrentSettings(animated: true)
        }
    }
    
    @IBAction func nextClock() {
        currentClockIndex = currentClockIndex + 1
        if (UserClockSetting.sharedClockSettings.count <= currentClockIndex) {
            currentClockIndex = 0
        }
        
        let newClockSetting = UserClockSetting.sharedClockSettings[currentClockIndex]
        SettingsViewController.currentClockSetting = newClockSetting
        redrawPreviewClock()
        redrawSettingsTable()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        redrawSettingsTable()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        UserClockSetting.loadFromFile()
        
        //get current selected clock
        SettingsViewController.currentClockSetting = UserClockSetting.sharedClockSettings[0]
        redrawPreviewClock()
        
        self.errorMessageLabel.alpha = 0.0
        
        NotificationCenter.default.addObserver(self, selector: #selector(onNotification(notification:)), name: SettingsViewController.settingsChangedNotificationName, object: nil)
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
}

