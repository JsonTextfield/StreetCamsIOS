//
//  TableViewController.swift
//  Ottawa Street Cameras
//
//  Created by Peckford on 2016-11-27.
//  Copyright © 2016 JsonTextfield. All rights reserved.
//

import UIKit
class ListViewController: UITableViewController, UISearchControllerDelegate {
    private var selectModeOn = false
    private var allSections = [Character: [Camera]]()
    private var sections = [Character: [Camera]]()
    private var cameras = [Camera]()
    private var neighbourhoods = [Neighbourhood]()
    private var selectedCameras = [Camera]()
    private var maxNum = 0
    
    private let searchController = UISearchController(searchResultsController: nil)
    
    private func filterContentForSearchText(searchText: String, scope: String = "All") {
        sections = allSections
        
        if(!searchText.isEmpty) {
            
            for (i, data) in sections {
                sections[i] = { () -> [Camera] in
                    if(searchText.lowercased().starts(with: "f: ")){
                        return data.filter({( camera : Camera) -> Bool in
                            return camera.getName().lowercased().contains(searchText.dropFirst(3).lowercased()) && camera.isFavourite
                        })
                    }
                    else if (searchText.lowercased().starts(with: "h: ")){
                        return data.filter({( camera : Camera) -> Bool in
                            return camera.getName().lowercased().contains(searchText.dropFirst(3).lowercased()) && !camera.isVisible
                        })
                    }
                    else if (searchText.lowercased().starts(with: "n: ")){
                        return data.filter({( camera : Camera) -> Bool in
                            return camera.neighbourhood.lowercased().contains(searchText.dropFirst(3).lowercased())
                        })
                    }
                    else{
                        return data.filter({( camera : Camera) -> Bool in
                            return camera.getName().lowercased().contains(searchText.lowercased())
                        })
                    }
                }()
            }
        }
        
        tableView.reloadData()
    }
    @objc func endSelecting(){
        selectModeOn = false
        selectedCameras.removeAll()
        navigationController?.setToolbarHidden(true, animated: true)
        for key in sections.keys{
            for i in 0...(sections[key]?.count)!{
                tableView.deselectRow(at: IndexPath(row: i, section: sections.keys.sorted().index(of: key)!), animated: false)
            }
        }
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        endSelecting()
    }
    
    private func setupIndex(){
        cameras.sort { (c1, c2) -> Bool in
            return c1.getSortableName() < c2.getSortableName()
        }
        for camera in cameras {
            let firstLetter = camera.getSortableName().first!
            
            if allSections[firstLetter] == nil{
                allSections[firstLetter] = []
            }
            allSections[firstLetter]!.append(camera)
        }
        sections = allSections
    }
    
    private func selectCamera(camera: Camera) -> Bool {
        if(selectedCameras.contains(camera)){
            selectedCameras.remove(at: selectedCameras.index(of: camera)!)
        }else if(selectedCameras.count < maxNum){
            selectedCameras.append(camera)
        }
        return selectedCameras.contains(camera)
    }
    
    private func getCamera(indexPath: IndexPath) -> Camera{
        return (sections[sections.keys.sorted()[indexPath.section]]?[indexPath.row])!
    }
    
    func update(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        cameras = appDelegate.cameras
        neighbourhoods = appDelegate.neighbourhoods
        maxNum = appDelegate.maxCameras
        
        self.searchController.searchBar.placeholder = (cameras.isEmpty) ? "Loading..." : "Search from \(self.cameras.count) locations"
        
        setupIndex()
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        update()
        
        self.tableView.estimatedRowHeight = self.tableView.rowHeight
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.searchController.delegate = self
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
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(ListViewController.longPress))
        self.view.addGestureRecognizer(longPressRecognizer)
    }
    
    @objc func longPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        
        if longPressGestureRecognizer.state == UIGestureRecognizerState.began {
            if(!selectModeOn){
                selectModeOn = true
                selectedCameras.removeAll()
                navigationController?.setToolbarHidden(false, animated: true)
                let showCamsBtn = UIBarButtonItem(title: "Show locations",  style: .plain, target: self, action: #selector(ListViewController.didTapButton))
                let clearBtn = UIBarButtonItem(title: "Cancel",  style: .plain, target: self, action: #selector(ListViewController.endSelecting))
                navigationController?.toolbar.items = [showCamsBtn, clearBtn]
            }
            
            let touchPoint = longPressGestureRecognizer.location(in: self.view)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.none)
                tableView(tableView, didSelectRowAt: indexPath)
            }
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.keys.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[sections.keys.sorted()[section]]!.count
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if(searchController.isActive){
            return nil
        }
        return sections.keys.sorted().map{ String($0) }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "intersection", for: indexPath) as! ListItem
        //cell.selectionStyle = .none
        let camera = getCamera(indexPath: indexPath)
        
        cell.name.text = camera.getName()
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let camera = getCamera(indexPath: indexPath)
        selectCamera(camera: camera)
        if(selectedCameras.isEmpty){
            selectModeOn = false
            //navigationController?.setToolbarHidden(true, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let camera = getCamera(indexPath: indexPath)
        
        if (!selectModeOn) {
            tableView.deselectRow(at: indexPath, animated: true)
            
            let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            
            let destination: CameraViewController = storyboard.instantiateViewController(withIdentifier: "camera") as! CameraViewController
            
            destination.cameras = [camera]
            navigationController?.pushViewController(destination, animated: true)
        } else {
            if(!selectCamera(camera: camera)){
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
        
        
    }
    
    @objc func didTapButton(sender: AnyObject){
        performSegue(withIdentifier: "showMultiple", sender: sender)
    }
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showMultiple"{
            let dest = segue.destination as! CameraViewController
            dest.cameras = selectedCameras
        }
    }
}



extension ListViewController: UISearchBarDelegate {
    // MARK: - UISearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterContentForSearchText(searchText: searchBar.text!, scope: searchBar.scopeButtonTitles![selectedScope])
    }
}

extension ListViewController: UISearchResultsUpdating {
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
