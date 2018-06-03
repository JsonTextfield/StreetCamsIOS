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
    private var cameras = [Camera]()
    private var markers = [GMSMarker]()
    private var region: MKCoordinateRegion!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        googleMap.delegate = self
        searchBar.delegate = self
        
        dataReady()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func dataReady(){
        cameras = (UIApplication.shared.delegate as! AppDelegate).cameras
        searchBar.placeholder = (cameras.isEmpty) ? "Loading..." : "Search from \(self.cameras.count) locations"
        var latlngbounds = GMSCoordinateBounds()
        for camera in cameras {
            let cameraLocation = CLLocationCoordinate2DMake(camera.lat, camera.lng)
            latlngbounds = latlngbounds.includingCoordinate(cameraLocation)
            let marker = GMSMarker(position: cameraLocation)
            marker.title = camera.getName()
            marker.userData = camera
            marker.map = googleMap
            markers.append(marker)
        }
        googleMap.animate(with: GMSCameraUpdate.fit(latlngbounds, withPadding: 20))
        googleMap.cameraTargetBounds = latlngbounds
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        //mapView.addAnnotations(annotations)
        if(!searchText.isEmpty) {
            for marker in markers {
                let camera = marker.userData as! Camera
                marker.map = (camera.isVisible && camera.getName().lowercased().contains(searchText.lowercased())) ? googleMap : nil
            }
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
        
        destination.cameras = [marker.userData as! Camera]
        
        navigationController?.pushViewController(destination, animated: true)
    }
    
}
