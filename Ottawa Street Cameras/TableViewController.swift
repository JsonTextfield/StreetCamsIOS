//
//  TableViewController.swift
//  Ottawa Street Cameras
//
//  Created by Peckford on 2016-11-27.
//  Copyright © 2016 JsonTextfield. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
    var camList = [Camera]()
    var filteredCameras = [Camera]()
    
    
    let searchController = UISearchController(searchResultsController: nil)
    @IBOutlet var listView: UITableView!
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredCameras = camList.filter({( candy : Camera) -> Bool in
            return candy.name.lowercased().contains(searchText.lowercased())
        })
        listView.reloadData()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        tableView.tableHeaderView = searchController.searchBar
        
        
        let dispatch_group = DispatchGroup()
        dispatch_group.enter()
        getSessionId()
        dispatch_group.leave()
        dispatch_group.notify(queue: DispatchQueue.main,execute: {
            // Won't get here until everything has finished
            
            
            let filePath = Bundle.main.path(forResource: "ints", ofType: "json")
            //NSData(contentsOfFile: <#T##String#>, options: <#T##NSData.ReadingOptions#>)
            
            var data = NSData(contentsOfFile:filePath!)
            
            do {
                
                let parsedData = try JSONSerialization.jsonObject(with: data! as Data, options: JSONSerialization.ReadingOptions.allowFragments) as! NSArray
                //let currentConditions = parsedData["currently"] as! [String:Any]
                
                for var x in parsedData{
                    let t = x as! [String:String]
                    self.camList.append(Camera.init(name: t["name"]!, id: t["id"]!))
                }
            
            } catch let error as NSError {
                print(error)
            }
            // JSONObjectWithData returns AnyObject so the first thing to do is to downcast this to a known type

            self.listView.reloadData()
        })
        self.listView.reloadData()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredCameras.count
        }
        return camList.count
    }

    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "intersection", for: indexPath) as! ListItem
        let camera: Camera
        if searchController.isActive && searchController.searchBar.text != "" {
            camera = filteredCameras[indexPath.row]
        } else {
            camera = camList[indexPath.row]
        }
        
        cell.name.text = camera.name
        
        // Configure the cell...
        
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        
        
        let storyboard : UIStoryboard = UIStoryboard(
            name: "Main",
            bundle: nil)
        
        let destination: CameraViewController = storyboard.instantiateViewController(withIdentifier: "camera") as! CameraViewController
        
        destination.cam = camList[indexPath.row]
        if searchController.isActive && searchController.searchBar.text != "" {
            destination.cam = filteredCameras[indexPath.row]
        }
        navigationController?.pushViewController(destination, animated: true)
    }
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
    var SESSION_ID = ""
    func getSessionId(){
        let request = URLRequest(url: URL(string: "https://traffic.ottawa.ca/map")!)
        let task = URLSession.shared.dataTask(with: request as URLRequest) { data , urlResponse,_ in
            if let httpUrlResponse = urlResponse as? HTTPURLResponse
            {
                self.SESSION_ID = httpUrlResponse.allHeaderFields["Set-Cookie"]! as! String // Error
                
            }
            
        }
        task.resume()
    }
    
    
    
}


extension TableViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchText: searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}

extension TableViewController: UISearchResultsUpdating {
    @available(iOS 8.0, *)
    public func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }

    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchText: searchController.searchBar.text!, scope: scope)
    }
}
