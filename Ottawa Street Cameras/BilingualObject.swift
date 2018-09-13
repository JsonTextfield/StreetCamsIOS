//
//  BilingualObject.swift
//  Ottawa Street Cameras
//
//  Created by Peckford on 2018-08-17.
//  Copyright © 2018 JsonTextfield. All rights reserved.
//

import Foundation
class BilingualObject : NSObject {
    public var name = ""
    public var nameFr = ""
    public var id = 0
    
    func getName() -> String {
        return (Locale.preferredLanguages[0].contains("fr")) ? nameFr : name
    }
    func getSortableName() -> String {
        return getName().replacingOccurrences( of:"^\\W", with: "", options: .regularExpression)
    }
}
