//
//  Camera.swift
//  Ottawa Street Cameras
//
//  Created by Peckford on 2016-12-01.
//  Copyright © 2016 JsonTextfield. All rights reserved.
//

import Foundation
class Camera{
    var name = ""
    var owner = ""
    var nameFr = ""
    var id = 0
    var num = 0
    var lat = 0.0
    var lng = 0.0
    
    init(dict:[String: AnyObject]){
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
    init(){
    
    }
}
