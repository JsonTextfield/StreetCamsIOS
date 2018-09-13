//
//  Camera.swift
//  Ottawa Street Cameras
//
//  Created by Peckford on 2016-12-01.
//  Copyright © 2016 JsonTextfield. All rights reserved.
//

import Foundation
class Camera: BilingualObject{
    private(set) var owner = ""
    private(set) var num = 0
    private(set) var lat = 0.0
    private(set) var lng = 0.0
    var isVisible = true
    var isFavourite = false
    var neighbourhood = ""
    

    init(dict:[String: AnyObject]){
        super.init()
        name = dict["description"] as! String
        nameFr = dict["descriptionFr"] as! String
        owner = dict["type"] as! String
        num = dict["number"] as! Int
        if owner == "MTO"{
            num += 2000
        }
        id = dict["id"] as! Int
        lat = dict["latitude"] as! Double
        lng = dict["longitude"] as! Double
    }
}
