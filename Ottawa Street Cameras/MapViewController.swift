//
//  MapViewController.swift
//  Ottawa Street Cameras
//
//  Created by Peckford on 2017-06-27.
//  Copyright © 2017 JsonTextfield. All rights reserved.
//

import UIKit
import GoogleMaps
class MapViewController: UIViewController, UISearchBarDelegate, GMSMapViewDelegate {
    @IBOutlet var googleMap: GMSMapView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var loadingBar: UIActivityIndicatorView!
    @IBOutlet var showCamerasBtn: UIBarButtonItem!
    @IBOutlet var cancelBtn: UIBarButtonItem!
    @IBOutlet var hideBtn: UIBarButtonItem!
    @IBOutlet var favouriteBtn: UIBarButtonItem!
    
    private var selectModeOn = false
    private var cameras = [Camera]()
    private var selectedCameras = [Camera]()
    private var markers = [GMSMarker]()
    let maxNum = 4
    
    override func viewDidLoad() {
        super.viewDidLoad()
        googleMap.delegate = self
        searchBar.delegate = self
        
        searchBar.placeholder = (cameras.isEmpty) ? "Loading..." : "Search from \(cameras.count) locations"
        
        update()
    }
    
    func update(){
        cameras = (UIApplication.shared.delegate as! AppDelegate).cameras
        
        searchBar.placeholder = (cameras.isEmpty) ? "Loading..." : "Search from \(self.cameras.count) locations"
        
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
        loadingBar.stopAnimating()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        for marker in markers {
            let camera = marker.userData as! Camera
            marker.map = (camera.isVisible && camera.getName().lowercased().contains(searchText.lowercased())) ? googleMap : nil
            if(searchText.isEmpty){marker.map = googleMap}
        }
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
            
        } else {
            selectCamera(camera: marker.userData as! Camera)
        }
        
        destination.cameras = selectedCameras
        navigationController?.pushViewController(destination, animated: true)
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
    @IBAction func addRemoveFavs(_ sender: Any) {
    }
    @IBAction func addRemoveHidden(_ sender: Any) {
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
    
}
