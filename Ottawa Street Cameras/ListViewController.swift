//
//  CameraListViewController.swift
//  Ottawa Street Cameras
//
//  Created by Peckford on 2018-06-03.
//  Copyright © 2018 JsonTextfield. All rights reserved.
//

import UIKit

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var listView: UITableView!
    @IBOutlet var menu: UIToolbar!
    @IBOutlet var loadingBar: UIActivityIndicatorView!
    @IBOutlet var showCamerasBtn: UIBarButtonItem!
    @IBOutlet var favouriteBtn: UIBarButtonItem!
    @IBOutlet var hideBtn: UIBarButtonItem!
    @IBOutlet var cancelBtn: UIBarButtonItem!
    
    private var selectModeOn = false
    private var allSections = [Character: [Camera]]()
    private var sections = [Character: [Camera]]()
    private var cameras = [Camera]()
    private var neighbourhoods = [Neighbourhood]()
    private var selectedCameras = [Camera]()
    private var maxNum = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        listView.delegate = self
        listView.dataSource = self
        
        searchBar.placeholder = (cameras.isEmpty) ? "Loading..." : "Search from \(cameras.count) locations"

    }
    
    func update(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        cameras = appDelegate.cameras
        neighbourhoods = appDelegate.neighbourhoods
        maxNum = appDelegate.maxCameras
        
        searchBar.placeholder = (cameras.isEmpty) ? "Loading..." : "Search from \(cameras.count) locations"
        
        setupIndex()
        listView.reloadData()
        loadingBar.stopAnimating()
    }
    
    private func getCamera(indexPath: IndexPath) -> Camera{
        return (sections[sections.keys.sorted()[indexPath.section]]?[indexPath.row])!
    }
    
    private func selectCamera(camera: Camera) -> Bool {
        if(selectedCameras.contains(camera)){
            selectedCameras.remove(at: selectedCameras.index(of: camera)!)
        }else{
            selectedCameras.append(camera)
        }
        showCamerasBtn.isEnabled = (selectedCameras.count <= maxNum)
        if(selectedCameras.count > 1){
            title = "\(selectedCameras.count) cameras selected"
        }else if(selectedCameras.count == 1){
            title = "1 camera selected"
        }
        return selectedCameras.contains(camera)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let camera = getCamera(indexPath: indexPath)
        if(!selectCamera(camera: camera) && selectedCameras.isEmpty){
            endSelecting()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "intersection", for: indexPath) as! ListItem
        //cell.selectionStyle = .none
        let camera = getCamera(indexPath: indexPath)
        
        cell.name.text = camera.getName()
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.keys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[sections.keys.sorted()[section]]!.count
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if(!(searchBar.text?.isEmpty)!){
            return nil
        }
        return sections.keys.sorted().map{ String($0) }
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
    
    private func endSelecting(){
        title = "StreetCams"
        selectModeOn = false
        selectedCameras.removeAll()
        menu.isHidden = true
        
        for (key, value) in sections {
            for i in 0..<value.count {
                listView.deselectRow(at: IndexPath(row: i, section: sections.keys.sorted().index(of: key)!), animated: false)
            }
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
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
        
        listView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.endEditing(true)
    }
    @IBAction func showCameras(_ sender: Any) {
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let destination: CameraViewController = storyboard.instantiateViewController(withIdentifier: "camera") as! CameraViewController
        
        destination.cameras = selectedCameras
        
        navigationController?.pushViewController(destination, animated: true)
    }
    @IBAction func addRemoveFavs(_ sender: Any) {
    }
    @IBAction func addRemoveHidden(_ sender: Any) {
    }
    @IBAction func cancelSelection(_ sender: Any) {
        endSelecting()
    }
    
    @IBAction func longPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            if(!selectModeOn){
                selectModeOn = true
                menu.isHidden = false
            }
            
            let touchPoint = sender.location(in: listView)
            if let indexPath = listView.indexPathForRow(at: touchPoint) {
                
                listView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.none)
                tableView(listView, didSelectRowAt: indexPath)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showMultiple"{
            let dest = segue.destination as! CameraViewController
            dest.cameras = selectedCameras
        }
    }
}
