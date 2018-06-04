//
//  SCTabBarController.swift
//  Ottawa Street Cameras
//
//  Created by Peckford on 2018-06-02.
//  Copyright © 2018 JsonTextfield. All rights reserved.
//

import UIKit
class SCTabBarController: UITabBarController {
    private var cameras = [Camera]()
    private var neighbourhoods = [Neighbourhood]()
    private let dispatch_group = DispatchGroup()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getCameraList()
        
        dispatch_group.notify(queue: DispatchQueue.main, execute: {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.cameras = self.cameras
            appDelegate.neighbourhoods = self.neighbourhoods
            
            let listView = ((self.viewControllers![0] as! UINavigationController).childViewControllers[0] as! ListViewController)
            let mapView = ((self.viewControllers![1] as! UINavigationController).childViewControllers[0] as! MapViewController)
            
            if (listView.isViewLoaded){
                listView.update()
            }
            if (mapView.isViewLoaded) {
                mapView.update()
            }
        })
    }
    
    private func getCameraList(){
        dispatch_group.enter()
        let url = URL(string: "https://traffic.ottawa.ca/map/camera_list")
        let task = URLSession.shared.dataTask(with: url!) { data, _, _ in
            do{
                let parsedData = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! [AnyObject]
                
                self.cameras = parsedData.map({(it) in Camera(dict: it as! [String: AnyObject])})
                
                self.getNeighbourhoods()
                self.dispatch_group.leave()
            } catch let error as NSError {
                print(error)
            }
        }
        task.resume()
    }
    
    private func getNeighbourhoods(){
        dispatch_group.enter()
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
                self.dispatch_group.leave()
            } catch let error as NSError {
                print(error)
            }
        }
        task.resume()
    }
}
