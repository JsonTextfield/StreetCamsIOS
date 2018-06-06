//
//  GenericViewController.swift
//  Ottawa Street Cameras
//
//  Created by Peckford on 2018-06-03.
//  Copyright © 2018 JsonTextfield. All rights reserved.
//

import UIKit
import GoogleMaps
class GenericViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, GMSMapViewDelegate, UITabBarDelegate {
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var googleMap: GMSMapView!
    @IBOutlet var loadingBar: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var cancelBtn: UIBarButtonItem!
    @IBOutlet var hideBtn: UIBarButtonItem!
    @IBOutlet var favouriteBtn: UIBarButtonItem!
    @IBOutlet var unfavouriteBtn: UIBarButtonItem!
    @IBOutlet var showCamerasBtn: UIBarButtonItem!
    @IBOutlet var unhideBtn: UIBarButtonItem!
    @IBOutlet var tabBar: UITabBar!
    
    private var selectModeOn = false
    private var cameras = [Camera]()
    private var selectedCameras = [Camera]()
    private var markers = [GMSMarker]()
    private var maxNum = 4
    private var allSections = [Character: [Camera]]()
    private var sections = [Character: [Camera]]()
    private var neighbourhoods = [Neighbourhood]()
    let dispatchGroup = DispatchGroup()
    
    let favString = "favourites"
    let hideString = "hidden"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getCameraList()
        
        googleMap.delegate = self
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tabBar.delegate = self
        
        tabBar.selectedItem = tabBar.items?[0]

        dispatchGroup.notify(queue: DispatchQueue.main, execute: {
            self.update()
        })
    }
    
    private func setupPrefs(){
        let preferences = UserDefaults.standard
        
        let favs = preferences.object(forKey: favString)
        let hidden = preferences.object(forKey: hideString)
        
        for camera in cameras {
            if(favs != nil){
                let list = favs as! [Int]
                camera.isFavourite = list.contains(camera.num)
            }
            if(hidden != nil){
                let list = hidden as! [Int]
                camera.isVisible = !list.contains(camera.num)
            }
        }
    }
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        tableView.isHidden = (tabBar.items?.index(of: item) == 1)
        googleMap.isHidden = (tabBar.items?.index(of: item) == 0)
    }
    
    private func getCameraList(){
        dispatchGroup.enter()
        let url = URL(string: "https://traffic.ottawa.ca/map/camera_list")
        let task = URLSession.shared.dataTask(with: url!) { data, _, _ in
            do{
                let parsedData = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! [AnyObject]
                
                self.cameras = parsedData.map({(it) in Camera(dict: it as! [String: AnyObject])})
                
                self.getNeighbourhoods()
                self.dispatchGroup.leave()
            } catch let error as NSError {
                print(error)
            }
        }
        task.resume()
    }
    
    private func getNeighbourhoods(){
        dispatchGroup.enter()
        let url = URL(string: "http://data.ottawa.ca/dataset/302ade92-51ec-4b26-a715-627802aa62a8/resource/f1163794-de80-4682-bda5-b13034984087/download/onsboundariesgen1.shp.json")
        let task = URLSession.shared.dataTask(with: url!) { data, response, error in
            do{
                let parsedData = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! [String: AnyObject]
                
                let items = parsedData["features"] as! [[String: AnyObject]]
                
                self.neighbourhoods = items.map({(it) in Neighbourhood(dict: it)})
                
                //takes too long for ui thread execution
                for camera in self.cameras {
                    for neighbourhood in self.neighbourhoods{
                        if(neighbourhood.containsCamera(camera: camera)){
                            camera.neighbourhood = neighbourhood.getName()
                            break
                        }
                    }
                }
                self.dispatchGroup.leave()
            } catch let error as NSError {
                print(error)
            }
        }
        task.resume()
    }
    
    func update(){
        searchBar.placeholder = "Search from \(cameras.count) locations"
        
        setupPrefs()
        
        setupIndex()
        filterList(searchText: "")
        
        var mapBounds = GMSCoordinateBounds()
        
        for camera in cameras {
            let cameraLocation = CLLocationCoordinate2DMake(camera.lat, camera.lng)
            
            mapBounds = mapBounds.includingCoordinate(cameraLocation)
            
            let marker = GMSMarker(position: cameraLocation)
            marker.title = camera.getName()
            marker.userData = camera
            marker.map = googleMap
            
            markers.append(marker)
        }
        
        googleMap.cameraTargetBounds = mapBounds
        googleMap.moveCamera(GMSCameraUpdate.fit(mapBounds, withPadding: 20))
        
        loadingBar.stopAnimating()
    }
    
    func filterList(searchText: String){
        sections = allSections
        for (i, data) in sections {
            sections[i] = { () -> [Camera] in
                if(searchText.lowercased().starts(with: "f: ")){
                    return data.filter({( camera : Camera) -> Bool in
                        return camera.getName().containsIgnoringCase(find: searchText.dropFirst(3)) && camera.isFavourite
                    })
                }
                else if (searchText.lowercased().starts(with: "h: ")){
                    return data.filter({( camera : Camera) -> Bool in
                        return camera.getName().containsIgnoringCase(find: searchText.dropFirst(3)) && !camera.isVisible
                    })
                }
                else if (searchText.lowercased().starts(with: "n: ")){
                    return data.filter({( camera : Camera) -> Bool in
                        return camera.neighbourhood.containsIgnoringCase(find: searchText.dropFirst(3))
                    })
                }
                else{
                    return data.filter({( camera : Camera) -> Bool in
                        return camera.getName().containsIgnoringCase(find: searchText.dropFirst(0)) && camera.isVisible
                    })
                }
            }()
        }
        
        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        endSelecting()
        
        for marker in markers {
            let camera = marker.userData as! Camera
            
            if((marker.userData as! Camera).isVisible){
                marker.map = googleMap
            }
            
            if(searchText.lowercased().starts(with: "f: ")){
                marker.map = (camera.isFavourite && camera.getName().containsIgnoringCase(find: searchText.dropFirst(3))) ? googleMap : nil
            }
            else if (searchText.lowercased().starts(with: "h: ")){
                marker.map = (!camera.isVisible && camera.getName().containsIgnoringCase(find: searchText.dropFirst(3))) ? googleMap : nil
            }
            else if (searchText.lowercased().starts(with: "n: ")){
                marker.map = (camera.isVisible && camera.neighbourhood.containsIgnoringCase(find: searchText.dropFirst(3))) ? googleMap : nil
            }
            else {
                marker.map = (camera.isVisible && camera.getName().containsIgnoringCase(find: searchText.dropFirst(0))) ? googleMap : nil
            }
        }
        
        filterList(searchText: searchText)
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
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let destination: CameraViewController = storyboard.instantiateViewController(withIdentifier: "camera") as! CameraViewController
        
        if(!selectModeOn){
            destination.cameras = [marker.userData as! Camera]
            navigationController?.pushViewController(destination, animated: true)
        } else {
            selectCamera(camera: marker.userData as! Camera)
        }
    }
    
    func mapView(_ mapView: GMSMapView, didLongPressInfoWindowOf marker: GMSMarker) {
        if(!selectModeOn){
            selectModeOn = true
            toolbar.isHidden = false
        }
        selectCamera(camera: marker.userData as! Camera)
        marker.iconView?.tintColor = UIColor.blue
    }
    @IBAction func showCameras(_ sender: Any) {
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let destination: CameraViewController = storyboard.instantiateViewController(withIdentifier: "camera") as! CameraViewController
        
        destination.cameras = selectedCameras
        
        navigationController?.pushViewController(destination, animated: true)
    }
    @IBAction func cancelSelection(_ sender: Any) {
        endSelecting()
    }
    @IBAction func unhideClicked(_ sender: Any) {
        modifyPrefs(prefName: hideString, willAdd: false)
    }
    @IBAction func unfavouriteClicked(_ sender: Any) {
        modifyPrefs(prefName: favString, willAdd: true)
    }
    @IBAction func hideClicked(_ sender: Any) {
        modifyPrefs(prefName: hideString, willAdd: true)
    }
    @IBAction func favouriteClicked(_ sender: Any) {
        modifyPrefs(prefName: favString, willAdd: true)
    }
    
    func endSelecting(){
        title = "StreetCams"
        selectModeOn = false
        selectedCameras.removeAll()
        toolbar.isHidden = true
        
        //need to unhighlight markers
        
        
        for (key, value) in sections {
            for i in 0..<value.count {
                tableView.deselectRow(at: IndexPath(row: i, section: sections.keys.sorted().index(of: key)!), animated: false)
            }
        }
    }
    
    private func selectCamera(camera: Camera) -> Bool {
        toolbar.items = [showCamerasBtn,cancelBtn]
        if(selectedCameras.contains(camera)){
            selectedCameras.remove(at: selectedCameras.index(of: camera)!)
        } else {
            selectedCameras.append(camera)
        }
        
        if(selectedCameras.isEmpty) {
            return false
        }
        showCamerasBtn.isEnabled = (selectedCameras.count <= maxNum)
        
        let allFavs = selectedCameras.reduce(selectedCameras[0].isFavourite, {(result: Bool, camera: Camera) -> Bool in
            return result && camera.isFavourite
        })
        
        if (allFavs) { //if everything selected is a favourite
            //show unfavourite and hide favourite
            toolbar.items?.insert(unfavouriteBtn, at: 1)
            /*if (toolbar.items?.contains(favouriteBtn))!{
                toolbar.items?.remove(at: (toolbar.items?.index(of: favouriteBtn))!)
            }*/
            
        } else {
            toolbar.items?.insert(favouriteBtn, at: 1)
            /*if (toolbar.items?.contains(unfavouriteBtn))!{
                toolbar.items?.remove(at: (toolbar.items?.index(of: unfavouriteBtn))!)
            }*/
        }
        
        let allInvis = selectedCameras.reduce(!selectedCameras[0].isVisible, {(result: Bool, camera: Camera) -> Bool in
            return result && !camera.isVisible
        })
        
        if (allInvis) {
            toolbar.items?.insert(unhideBtn, at: 2)
            /*if (toolbar.items?.contains(hideBtn))!{
                toolbar.items?.remove(at: (toolbar.items?.index(of: hideBtn))!)
            }*/
        } else {
            toolbar.items?.insert(hideBtn, at: 2)
            /*if (toolbar.items?.contains(unhideBtn))!{
                toolbar.items?.remove(at: (toolbar.items?.index(of: unhideBtn))!)
            }*/
        }
        
        if(selectedCameras.count > 1){
            title = "\(selectedCameras.count) cameras selected"
        }else if(selectedCameras.count == 1){
            title = "1 camera selected"
        }
        
        return selectedCameras.contains(camera)
    }
    
    private func getCamera(indexPath: IndexPath) -> Camera{
        return (sections[sections.keys.sorted()[indexPath.section]]?[indexPath.row])!
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
    
    @IBAction func longPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            if(!selectModeOn){
                selectModeOn = true
                toolbar.isHidden = false
            }
            
            let touchPoint = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.none)
                tableView(tableView, didSelectRowAt: indexPath)
            }
        }
    }
    
    func modifyPrefs(prefName: String, willAdd: Bool){
        let preferences = UserDefaults.standard
        
        if preferences.object(forKey: prefName) == nil {
            preferences.set(selectedCameras.map({ (camera) -> Int in return camera.num }), forKey: prefName)
        } else {
            var list = preferences.object(forKey: prefName) as! [Int]
            if(willAdd){
                list += selectedCameras.map({ (camera) -> Int in return camera.num })
            } else {
                for camera in selectedCameras {
                    if(list.contains(camera.num)){
                        list.remove(at: list.index(of: camera.num)!)
                    }
                }
            }
            preferences.set(list, forKey: prefName)
        }
        preferences.synchronize()
        
        for camera in cameras {
            if(selectedCameras.contains(camera)){
                if(prefName == favString){
                    camera.isFavourite = willAdd
                } else {
                    camera.isVisible = !willAdd
                }
            }
        }
        
        filterList(searchText: "")
        endSelecting()
    }
}
extension String {
    func contains(find: Substring) -> Bool{
        if (find.isEmpty){
            return true
        }
        return self.range(of: find) != nil
    }
    func containsIgnoringCase(find: Substring) -> Bool{
        if (find.isEmpty){
            return true
        }
        return self.range(of: find, options: .caseInsensitive) != nil
    }
}
