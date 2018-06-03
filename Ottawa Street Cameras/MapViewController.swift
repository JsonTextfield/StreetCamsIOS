//
//  MapViewController.swift
//  Ottawa Street Cameras
//
//  Created by Peckford on 2017-06-27.
//  Copyright © 2017 JsonTextfield. All rights reserved.
//

import UIKit
import MapKit
class MapViewController: UIViewController, MKMapViewDelegate, UISearchBarDelegate {
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var searchBar: UISearchBar!
    private var cameras = [Camera]()
    private var annotations = [MyAnnotation]()
    private var region: MKCoordinateRegion!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
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
        for camera in cameras {
            let annotation = MyAnnotation(camera: camera)
            annotations.append(annotation)
            mapView.addAnnotation(annotation)
            mapView.view(for: annotation)?.isHidden = !camera.isVisible
        }
        mapView.showAnnotations(mapView.annotations, animated: false)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let destination: CameraViewController = storyboard.instantiateViewController(withIdentifier: "camera") as! CameraViewController
        
        destination.cameras = [(view.annotation as! MyAnnotation).camera]
        
        navigationController?.pushViewController(destination, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "") {
            annotationView.annotation = annotation
            return annotationView
        } else {
            let annotationView = MKPinAnnotationView(annotation:annotation, reuseIdentifier:"")
            annotationView.isEnabled = true
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return annotationView
        }
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
            for item in mapView.annotations {
                let marker = item as! MyAnnotation
                mapView.view(for: item)?.isHidden = !marker.camera.isVisible && !(marker.camera.getName().lowercased().contains(searchText.lowercased()))
            }
        }
    }
}
