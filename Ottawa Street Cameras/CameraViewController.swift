//
//  CameraViewController.swift
//  Ottawa Street Cameras
//
//  Created by Peckford on 2016-12-10.
//  Copyright © 2016 JsonTextfield. All rights reserved.
//

import UIKit

class CameraViewController: UIViewController {
    
    var cameras = [Camera]()
    var imageViews = [UIImageView]()
    
    @IBOutlet var backgroundImg: UIImageView!
    @IBOutlet var errorLbl: UILabel!
    var timer:Timer = Timer.init()
    
    
    
    func getSessionId(){
        let request = URLRequest(url: URL(string: "https://traffic.ottawa.ca/map")!)
        let task = URLSession.shared.dataTask(with: request as URLRequest) { data , urlResponse,_ in
        }
        task.resume()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var title = ""
        for i in cameras{
            title += i.name+", "
        }
        let label = UILabel(frame: CGRect(x:0, y:0, width:400, height:50))
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 0
        label.font = UIFont.boldSystemFont(ofSize: 14.0)
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.text = title.substring(to: title.index(title.endIndex, offsetBy: -2))
        self.navigationItem.titleView = label
        
        getSessionId()
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(CameraViewController.downloadImage), userInfo: nil, repeats: true)
        
        
        
    }
    func getDataFromUrl(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            completion(data, response, error)
            }.resume()
    }
    func downloadImage() {
        for i in 0...cameras.count-1{
            let camera = cameras[i]
            
            let url = URL(string: "https://traffic.ottawa.ca/map/camera?id=\(camera.num)")!
            getDataFromUrl(url: url) { (data, response, error)  in
                
                /*guard let data = data, error == nil else {
                 self.errorLbl.isHidden = false
                 //self.cameraImage.isHidden = true
                 self.timer.invalidate()
                 return
                 }*/
                
                /*let currentFilter = CIFilter(name: "CIGaussianBlur")
                let beginImage = CIImage(image: UIImage(data: data!)!)
                currentFilter!.setValue(beginImage, forKey: kCIInputImageKey)
                currentFilter!.setValue(10, forKey: kCIInputRadiusKey)
                
                let cropFilter = CIFilter(name: "CICrop")
                cropFilter!.setValue(currentFilter!.outputImage, forKey: kCIInputImageKey)
                cropFilter!.setValue(CIVector(cgRect: beginImage!.extent), forKey: "inputRectangle")
                
                let output = cropFilter!.outputImage
                let processedImage = UIImage(ciImage: output!)
                */
                
                DispatchQueue.main.async() { () -> Void in
                    //self.cameraImage.isHidden = false
                
                    self.imageViews[i].image = UIImage(data: data!)
                    //self.backgroundImg.image = processedImage
                    
                }
            }
            
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillDisappear(_ animated: Bool) {
        timer.invalidate()
    }
}
