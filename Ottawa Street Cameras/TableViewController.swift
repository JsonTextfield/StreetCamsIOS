//
//  TableViewController.swift
//  Ottawa Street Cameras
//
//  Created by Peckford on 2016-11-27.
//  Copyright © 2016 JsonTextfield. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {

    var sections = [String: [Camera]]()
    var filteredSections = [String: [Camera]]()
    
    let searchController = UISearchController(searchResultsController: nil)
    
    @IBOutlet var listView: UITableView!
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredSections = [:]
        for i in 0 ... sections.keys.count-1{
            let sectionTitle = sections.keys.sorted()[i]
            filteredSections[sectionTitle] = sections[sectionTitle]?.filter({( candy : Camera) -> Bool in
                return candy.name.lowercased().contains(searchText.lowercased())
            })
            /*if c.name.lowercased().contains(searchText.lowercased()){
                let d = c.name.characters.first!.description
                if self.filteredSections[d] != nil{
                    self.filteredSections[d]!.append(c)
                    //self.sections['0'] += 1
                }
                else{
                    self.filteredSections[d] = [c]
                }
            }*/
        }
        /*
         filteredCameras = camList.filter({( candy : Camera) -> Bool in
         return candy.name.lowercased().contains(searchText.lowercased())
         })*/
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
        searchController.searchBar.barTintColor = UIColor.black
        
        tableView.tableHeaderView = searchController.searchBar
        tableView.sectionIndexBackgroundColor = UIColor.black
        
        let v = UIView()
        v.backgroundColor = UIColor.black
        tableView.backgroundView = v
        
        // Won't get here until everything has finished
        
        
        let filePath = Bundle.main.path(forResource: "ints", ofType: "json")
        //NSData(contentsOfFile: <#T##String#>, options: <#T##NSData.ReadingOptions#>)
        
        let data = NSData(contentsOfFile:filePath!)
        
        do {
            
            let parsedData = try JSONSerialization.jsonObject(with: data! as Data, options: JSONSerialization.ReadingOptions.allowFragments) as! NSArray
            //let currentConditions = parsedData["currently"] as! [String:Any]
            
            for x in parsedData{
                let camera = Camera.init(dict: x as! [String:String])
                let d = camera.name.characters.first!.description
                if self.sections[d] != nil{
                    self.sections[d]!.append(camera)
                }
                else{
                    self.sections[d] = [camera]
                }

            }
            
        } catch let error as NSError {
            print(error)
        }
        self.listView.reloadData()
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredSections.keys.count
        }
        return sections.keys.count
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // #warning Incomplete implementation, return the number of rows
        if searchController.isActive && searchController.searchBar.text != "" {
            //return filteredCameras.count
            return filteredSections[filteredSections.keys.sorted()[section]]!.count
        }
        return sections[sections.keys.sorted()[section]]!.count
        //return camList.count
    }
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchController.isActive && searchController.searchBar.text != "" {
            //return filteredCameras.count
            return filteredSections.keys.sorted()
        }
        return sections.keys.sorted()
    }
    
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell  = tableView.cellForRow(at: indexPath)
        cell!.contentView.backgroundColor = .blue
    }
    
    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell  = tableView.cellForRow(at: indexPath)
        cell!.contentView.backgroundColor = .clear
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "intersection", for: indexPath) as! ListItem
        cell.selectionStyle = .none
        let camera: Camera
        if searchController.isActive && searchController.searchBar.text != "" {
            //camera = filteredCameras[indexPath.row]
            camera = (filteredSections[filteredSections.keys.sorted()[indexPath.section]]?[indexPath.row])!
        } else {
            
            camera = (sections[sections.keys.sorted()[indexPath.section]]?[indexPath.row])!

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
        
        destination.cam = (sections[sections.keys.sorted()[indexPath.section]]?[indexPath.row])!
        if searchController.isActive && searchController.searchBar.text != "" {
            destination.cam = (filteredSections[filteredSections.keys.sorted()[indexPath.section]]?[indexPath.row])!
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
    

    
    
    
    
}



extension TableViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchText: searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}

extension TableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchText: searchController.searchBar.text!, scope: scope)
    }
}
