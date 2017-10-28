//
//  NavView.swift
//  Ottawa Street Cameras
//
//  Created by Peckford on 2017-06-30.
//  Copyright © 2017 JsonTextfield. All rights reserved.
//

import UIKit

class NavView: UIView {

    @IBOutlet var searchBard: UISearchBar!
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    class func instanceFromNib() -> NavView {
        return UINib(nibName: "NavView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! NavView
    }
}
