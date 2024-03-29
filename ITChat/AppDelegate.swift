//
//  AppDelegate.swift
//  ITChat
//
//  Created by NeilPhung on 8/2/19.
//  Copyright © 2019 NeilPhung. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    
    var authListener: AuthStateDidChangeListenerHandle?
    
    
    var locationManager: CLLocationManager?
    var coordinates: CLLocationCoordinate2D?
    


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        //Auto Login
        authListener = Auth.auth().addStateDidChangeListener({ (auth, user) in
            Auth.auth().removeStateDidChangeListener(self.authListener!)
            
            if user != nil {
                if UserDefaults.standard.object(forKey: kCURRENTUSER) != nil {
                    DispatchQueue.main.async {
                        self.goToMainApplication()
                    }
                }
            }
        })
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        locationMangerStop()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        locationManagerStart()
        
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    //MARK: Auto Login helper method
    func goToMainApplication(){
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FirebaseUser.currentId()])
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        window?.rootViewController = mainView
    }
    

    //MARK: Location manger
    
    func locationManagerStart() {
        
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager!.delegate = self
            locationManager!.desiredAccuracy = kCLLocationAccuracyBest
            locationManager!.requestWhenInUseAuthorization()
        }
        
        locationManager!.startUpdatingLocation()
    }
    
    func locationMangerStop() {
        
        if locationManager != nil {
            locationManager!.stopUpdatingLocation()
        }
    }
    
    //MARK: Location Manager delegate
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        print("faild to get location")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .authorizedAlways:
            manager.startUpdatingLocation()
        case .restricted:
            print("restricted")
        case .denied:
            locationManager = nil
            print("denied location access")
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        coordinates = locations.last!.coordinate
    }
    
    

}

