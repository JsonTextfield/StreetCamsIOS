//
//  Neighbourhood.swift
//  Ottawa Street Cameras
//
//  Created by Peckford on 2018-05-28.
//  Copyright © 2018 JsonTextfield. All rights reserved.
//

import Foundation
import MapKit
class Neighbourhood: NSObject{
    private var name = ""
    private var nameFr = ""
    private(set) var id = 0
    private(set) var boundaries = [[CLLocationCoordinate2D]]()
    
    func getName() -> String {
        return (Locale.preferredLanguages[0].contains("fr")) ? nameFr : name
    }
    
    init(dict:[String: AnyObject]){
        let props = dict["properties"] as! [String: AnyObject]
        name = props["Name"] as! String
        nameFr = (props["Name_FR"] is NSNull) ? name : props["Name_FR"] as! String
        id = props["ONS_ID"] as! Int
        
        let geo = dict["geometry"] as! [String: AnyObject]
        var neighbourhoodZones = [[[[Double]]]]()
        
        if (geo["type"] as! String == "Polygon") {
            neighbourhoodZones.append(geo["coordinates"] as! [[[Double]]])
        } else {
            neighbourhoodZones = geo["coordinates"] as! [[[[Double]]]]
        }
        for index in 0..<neighbourhoodZones.count {
            let neighbourhoodPoints = neighbourhoodZones[index][0]
            let list = (0..<neighbourhoodPoints.count).map { (it) in
                return CLLocationCoordinate2D(latitude: neighbourhoodPoints[it][1], longitude: neighbourhoodPoints[it][0])
            }
            boundaries.append(list)
        }
    }
    
    //http://en.wikipedia.org/wiki/Point_in_polygon
    //https://stackoverflow.com/questions/26014312/identify-if-point-is-in-the-polygon
    func containsCamera(camera: Camera) -> Bool {
        var intersectCount = 0
        let cameraLocation = CLLocationCoordinate2D(latitude: camera.lat, longitude: camera.lng)
        
        for vertices in boundaries {
            for j in 0..<vertices.count-1 {
                if rayCastIntersect(location: cameraLocation, vertA: vertices[j], vertB: vertices[j + 1]) {
                    intersectCount += 1
                }
            }
        }
        return (intersectCount % 2) == 1 // odd = inside, even = outside
    }
    
    private func rayCastIntersect(location: CLLocationCoordinate2D, vertA: CLLocationCoordinate2D, vertB: CLLocationCoordinate2D) -> Bool {
    
        let aY = vertA.latitude
        let bY = vertB.latitude
        let aX = vertA.longitude
        let bX = vertB.longitude
        let pY = location.latitude
        let pX = location.longitude
        
        if ((aY > pY && bY > pY) || (aY < pY && bY < pY) || (aX < pX && bX < pX)) {
            return false // a and b can't both be above or below pt.y, and a or b must be east of pt.x
        }
        
        let m = (aY - bY) / (aX - bX) // Rise over run
        let bee = (-aX) * m + aY // y = mx + b
        let x = (pY - bee) / m // algebra is neat!
        
        return x > pX
    }

}
