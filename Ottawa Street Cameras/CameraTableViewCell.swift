//
//  CameraTableViewCell.swift
//  Ottawa Street Cameras
//
//  Created by Peckford on 2018-02-03.
//  Copyright © 2018 JsonTextfield. All rights reserved.
//

import UIKit

class CameraTableViewCell: UITableViewCell {

    @IBOutlet var sourceImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
