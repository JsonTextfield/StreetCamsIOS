//
//  TableViewController.swift
//  Ottawa Street Cameras
//
//  Created by Peckford on 2016-11-27.
//  Copyright © 2016 JsonTextfield. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
    var selectModeOn = false
    var sections = [String: [Camera]]()
    var cameras = [Camera]()
    var filteredSections = [String: [Camera]]()
    var selectedCameras = [Camera]()
    let dispatch_group = DispatchGroup()
    let maxNum = 4
    
    var showCamsBtn = UIBarButtonItem(title: "Show (1)",  style: .plain, target: self, action: #selector(TableViewController.didTapButton))
    let searchController = UISearchController(searchResultsController: nil)
    
    @IBOutlet var listView: UITableView!
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredSections = sections
        let regex = try! NSRegularExpression(pattern: "\\W", options: [])
        let firstLetter = regex.stringByReplacingMatches(in: searchText, options: [], range: NSRange(location: 0, length:searchText.count), withTemplate: "")
        
        if(firstLetter.count < 1){
            filteredSections = sections
        }
        else{
            for i in 0 ... sections.keys.count-1{
                let sectionTitle = sections.keys.sorted()[i]
                filteredSections[sectionTitle] = filteredSections[sectionTitle]?.filter({( candy : Camera) -> Bool in
                    return candy.name.lowercased().contains(searchText.lowercased())
                })
                if(filteredSections[sectionTitle]!.count == 0){
                    filteredSections.removeValue(forKey: sectionTitle)
                }
            }}
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dispatch_group.enter()
        getCameraList()
        
        dispatch_group.notify(queue: DispatchQueue.main, work: DispatchWorkItem(){
            // Won't get here until everything has finished
            
            self.searchController.searchBar.placeholder = "Search from \(self.cameras.count) locations"
            
            for camera in self.cameras{
                let regex = try! NSRegularExpression(pattern: "\\W", options: [])
                let firstLetter = regex.stringByReplacingMatches(in: camera.name, options: [], range: NSRange(location: 0, length:camera.name.count), withTemplate: "").first!.description
                
                if self.sections[firstLetter] == nil{
                    self.sections[firstLetter] = []
                }
                self.sections[firstLetter]!.append(camera)
                
            }
            self.filteredSections = self.sections
            
            self.tableView.reloadData()
            
            self.tableView.estimatedRowHeight = self.tableView.rowHeight
            self.tableView.rowHeight = UITableViewAutomaticDimension
            
            self.searchController.searchResultsUpdater = self
            self.searchController.searchBar.delegate = self
            self.definesPresentationContext = true
            self.searchController.dimsBackgroundDuringPresentation = false
            self.searchController.searchBar.barTintColor = UIColor.clear
            self.searchController.searchBar.backgroundColor = UIColor.clear
            
            self.tableView.sectionIndexBackgroundColor = UIColor.clear
            self.tableView.tableHeaderView = self.searchController.searchBar
            
            let v = UIView()
            v.backgroundColor = UIColor.black
            self.tableView.backgroundView = v
          
            
            let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(TableViewController.longPress))
            self.view.addGestureRecognizer(longPressRecognizer)
            self.showCamsBtn = UIBarButtonItem(title: "Show (1)",  style: .plain, target: self, action: #selector(TableViewController.didTapButton))
        })
        
    }
    
    func longPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        
        if longPressGestureRecognizer.state == UIGestureRecognizerState.began {
            if(selectModeOn){
                return
            }
            selectModeOn = true
            
            
            navigationItem.rightBarButtonItem = showCamsBtn
            let touchPoint = longPressGestureRecognizer.location(in: self.view)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                selectedCameras = [filteredSections[filteredSections.keys.sorted()[(indexPath.section)]]![(indexPath.row)]]
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.none)
            }
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return filteredSections.keys.count
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return filteredSections[filteredSections.keys.sorted()[section]]!.count
        
    }
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        
        return filteredSections.keys.sorted()
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "intersection", for: indexPath) as! ListItem
        //cell.selectionStyle = .none
        let camera = (filteredSections[filteredSections.keys.sorted()[indexPath.section]]?[indexPath.row])!
        
        cell.name.text = camera.name
        return cell
    }
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.backgroundColor = UIColor.darkGray
    }
    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.backgroundColor = UIColor.black
    }
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let camera = (filteredSections[filteredSections.keys.sorted()[indexPath.section]]?[indexPath.row])!
        if (selectModeOn){
            if let i = selectedCameras.index(of: camera){
                selectedCameras.remove(at: i)
                showCamsBtn.title = "Show (\(selectedCameras.count))"
                if(selectedCameras.count == 0){
                    showCamsBtn.title = "Show (1)"
                    selectModeOn = false
                    navigationItem.rightBarButtonItems?.removeFirst()
                }
            }
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let camera = (filteredSections[filteredSections.keys.sorted()[indexPath.section]]?[indexPath.row])!
        if (selectModeOn) {
            if(selectedCameras.count < maxNum){
                selectedCameras.append(camera)
            }else{
                tableView.deselectRow(at: indexPath, animated: true)
            }
            showCamsBtn.title = "Show (\(selectedCameras.count))"
        }else{
            tableView.deselectRow(at: indexPath, animated: true)
            
            let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            
            let destination: CameraViewController = storyboard.instantiateViewController(withIdentifier: "camera") as! CameraViewController
            
            destination.cameras = [camera]
            navigationController?.pushViewController(destination, animated: true)
            
        }
    }
    func getCameraList(){
        
        let request = URLRequest(url: URL(string: "https://traffic.ottawa.ca/map/camera_list")!)
        let task = URLSession.shared.dataTask(with: request) { data, _, _ in
            do{
                let parsedData = try JSONSerialization.jsonObject(with: data! as Data, options: JSONSerialization.ReadingOptions.allowFragments) as! NSArray
                
                for item in parsedData{
                    let camera = Camera(dict: item as! [String:AnyObject])
                    self.cameras.append(camera)
                }
                self.dispatch_group.leave()
            } catch let error as NSError {
                print(error)
            }
        }
        task.resume()
    }
    func didTapButton(sender: AnyObject){
        performSegue(withIdentifier: "showMultiple", sender: sender)
    }

    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showMap"{
            let dest = segue.destination as! MapViewController
            dest.cameras = cameras
        }
        
        if segue.identifier == "showMultiple"{
            let dest = segue.destination as! CameraViewController
            dest.cameras = selectedCameras
        }
        
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
