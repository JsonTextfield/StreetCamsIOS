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
    override func viewDidLoad() {
        super.viewDidLoad()
        cameras = (UIApplication.shared.delegate as! AppDelegate).cameras
        mapView.delegate = self
        for camera in cameras {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2DMake(camera.lat, camera.lng)
            annotation.title = camera.getName()
            mapView.addAnnotation(annotation)
        }
        mapView.showAnnotations(mapView.annotations, animated: true)
        searchBar.delegate = self
        searchBar.placeholder = "Search from \(cameras.count) locations"
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let storyboard : UIStoryboard = UIStoryboard(
            name: "Main",
            bundle: nil)
        
        let destination: CameraViewController = storyboard.instantiateViewController(withIdentifier: "camera") as! CameraViewController
        
        for c in cameras{
            if c.getName() == (view.annotation?.title)!{
                destination.cameras = [c]
            }
        }
        
        
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
            
            let btn = UIButton(type: .detailDisclosure)
            annotationView.rightCalloutAccessoryView = btn
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
        resetMap()
        if(!searchText.isEmpty) {
            for i in mapView.annotations {
                if !(i.title!!.lowercased().contains(searchText.lowercased())){
                    mapView.view(for: i)?.isHidden = true
                }
            }
        }
    }
    func resetMap(){
        for i in mapView.annotations {
            mapView.view(for: i)?.isHidden = false
        }
    }

}
