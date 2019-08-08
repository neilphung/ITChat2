//
//  SettingTableViewController.swift
//  ITChat
//
//  Created by NeilPhung on 8/2/19.
//  Copyright © 2019 NeilPhung. All rights reserved.
//

import UIKit

class SettingTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 3
    }

 
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
//
//
//        return cell
//    }
    
    //MARK: IBAction
    
    @IBAction func loutOutButtonPressed(_ sender: UIButton) {
        
        FirebaseUser.logOutCurrentUser { (success) in
            if success {
                self.combackWelcomeView()
            }
        }
        
    }
    
    func combackWelcomeView(){
        let welcomeView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "welcomeView")
        
        self.present(welcomeView,animated: true, completion: nil)
    }
    




}
