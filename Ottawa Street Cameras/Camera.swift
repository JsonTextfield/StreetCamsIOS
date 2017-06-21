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
    var id = ""
    init(name:String, id:String){
        self.name = name
        self.id = id
    }
    init(dict:[String: String]){
        self.name = dict["name"]!
        self.id = dict["id"]!
    }
}
