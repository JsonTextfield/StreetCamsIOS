//
//  MyAnnotation.swift
//  Ottawa Street Cameras
//
//  Created by Peckford on 2018-06-03.
//  Copyright © 2018 JsonTextfield. All rights reserved.
//

import UIKit
import MapKit
class MyAnnotation: MKPointAnnotation {
    private(set) var camera: Camera!
    
    init(camera: Camera!){
        super.init()
        self.camera = camera
        coordinate = CLLocationCoordinate2DMake(camera.lat, camera.lng)
        title = camera.getName()
    }
}
