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
    @IBOutlet var showCamerasBtn: UIBarButtonItem!
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getCameraList()
        
        googleMap.delegate = self
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tabBar.delegate = self
        
        tabBar.selectedItem = tabBar.items?[0]
        
        searchBar.placeholder = (cameras.isEmpty) ? "Loading..." : "Search from \(cameras.count) locations"

        dispatchGroup.notify(queue: DispatchQueue.main, execute: {
            self.update()
        })
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
    
    func updateMap(){
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
        googleMap.animate(with: GMSCameraUpdate.fit(mapBounds, withPadding: 20))
        googleMap.cameraTargetBounds = mapBounds
    }
    
    func updateList(){
        setupIndex()
        tableView.reloadData()
    }
    
    func update(){
        searchBar.placeholder = (cameras.isEmpty) ? "Loading..." : "Search from \(cameras.count) locations"
        
        updateList()
        updateMap()
        
        loadingBar.stopAnimating()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        for marker in markers {
            let camera = marker.userData as! Camera
            marker.map = (camera.isVisible && camera.getName().lowercased().contains(searchText.lowercased())) ? googleMap : nil
            if(searchText.isEmpty){marker.map = googleMap}
        }
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showMultiple"{
            let dest = segue.destination as! CameraViewController
            dest.cameras = selectedCameras
        }
    }
}
