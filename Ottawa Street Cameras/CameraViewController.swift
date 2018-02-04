//
//  CameraViewController.swift
//  Ottawa Street Cameras
//
//  Created by Peckford on 2016-12-10.
//  Copyright © 2016 JsonTextfield. All rights reserved.
//

import UIKit

class CameraViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var cameras = [Camera]()
    
    @IBOutlet var imageTableView: UITableView!
    @IBOutlet var backgroundImg: UIImageView!
    @IBOutlet var errorLbl: UILabel!
    var timer:Timer = Timer.init()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cameras.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = imageTableView.dequeueReusableCell(withIdentifier: "camImage", for: indexPath) as! CameraTableViewCell
        return cell
    }
    
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
        
        imageTableView.delegate = self
        imageTableView.dataSource = self
        
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(CameraViewController.downloadImage), userInfo: nil, repeats: true)
        
        
        
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
                

                DispatchQueue.main.async() { () -> Void in
                    //self.cameraImage.isHidden = false
                    
                    if let cell = (self.imageTableView.cellForRow(at: IndexPath.init(row: i, section: 0))){
                        let c = cell as! CameraTableViewCell
                        c.sourceImageView.image = UIImage(data: data!)
                        
                    }
                    if(i == 0){
                        let currentFilter = CIFilter(name: "CIGaussianBlur")
                        let beginImage = CIImage(image: UIImage(data: data!)!)
                        currentFilter!.setValue(beginImage, forKey: kCIInputImageKey)
                        currentFilter!.setValue(10, forKey: kCIInputRadiusKey)
                        
                        let cropFilter = CIFilter(name: "CICrop")
                        cropFilter!.setValue(currentFilter!.outputImage, forKey: kCIInputImageKey)
                        cropFilter!.setValue(CIVector(cgRect: beginImage!.extent), forKey: "inputRectangle")
                        
                        let output = cropFilter!.outputImage
                        let processedImage = UIImage(ciImage: output!)
                        
                        self.backgroundImg.image = processedImage
                        
                    }
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
