//
//  CameraViewController.swift
//  Ottawa Street Cameras
//
//  Created by Peckford on 2016-12-10.
//  Copyright © 2016 JsonTextfield. All rights reserved.
//

import UIKit

class CameraViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var loadingBar: UIActivityIndicatorView!
    @IBOutlet var imageTableView: UITableView!
    @IBOutlet var backgroundImg: UIImageView!
    
    var dispatchGroup = DispatchGroup()
    var images = [Int: UIImage]()
    var imageIsNew = [Int: Bool]()
    var timers = [Timer]()
    var cameras = [Camera]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timers = [Timer](repeating: Timer(), count: cameras.count)
        
        let myTitle = cameras.map { (camera) -> String in
            return camera.getName()
        }.joined(separator: ", ")
        
        /*if (cameras.count < 1){
            myTitle = "\(cameras.count) cameras"
        } else {
            
         } else {
            myTitle = cameras[0].getName()
        }*/
        
        title = myTitle
        
        let label = UILabel(frame: CGRect(x:0, y:0, width:400, height:50))
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 0
        label.font = UIFont.boldSystemFont(ofSize: 14.0)
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.text = myTitle
        self.navigationItem.titleView = label
        
        getSessionId()
        
        dispatchGroup.notify(queue: DispatchQueue.main, execute: {
            self.imageTableView.dataSource = self
            self.imageTableView.delegate = self
            self.imageTableView.reloadData()
            self.backgroundImg.image = self.blurImage(image: self.images[0]!)
            for i in 0..<self.cameras.count{
                self.timers[i] = Timer.scheduledTimer(timeInterval: 0.6, target: self, selector: #selector(CameraViewController.downloadImage), userInfo: i, repeats: true)
            }
            self.loadingBar.stopAnimating()
        })
    }
    
    func getSessionId(){
        self.dispatchGroup.enter()
        let url = URL(string: "https://traffic.ottawa.ca/map")!
        getDataFromUrl(url: url) { (data, response, error) in
            for i in 0..<self.cameras.count{
                self.dispatchGroup.enter()
                self.download(index: i)
            }
            self.dispatchGroup.leave()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let image = images[indexPath.row]!
        let widthRatio = self.view.frame.width / image.size.width
        let height = widthRatio * image.size.height
        return height
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cameras.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = imageTableView.dequeueReusableCell(withIdentifier: "camImage", for: indexPath) as! CameraTableViewCell
        cell.camName.text = cameras[indexPath.row].getName()
        cell.sourceImageView.image = images[indexPath.row]
        return cell
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            //let orientation = UIApplication.shared.statusBarOrientation
            //self.portrait = orientation == .portrait
            self.imageTableView.reloadData()
            
        }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
            
        }
    }
    func getDataFromUrl(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            completion(data, response, error)
        }.resume()
    }
    func download(index: Int) {
        
        let url = URL(string: "https://traffic.ottawa.ca/map/camera?id=\(cameras[index].num)")!
        getDataFromUrl(url: url) { (data, response, error)  in
            
            let image = UIImage(data: data!)!
            self.images[index] = image
            self.imageIsNew[index] = true
            
            self.dispatchGroup.leave()
        }
    }
    @objc func downloadImage(timer: Timer) {
        
        let i = timer.userInfo as! Int
        
        self.imageIsNew[i] = false

        
        let url = URL(string: "https://traffic.ottawa.ca/map/camera?id=\(cameras[i].num)")!
        getDataFromUrl(url: url) { (data, response, error)  in
            
            /*guard let data = data, error == nil else {
             self.errorLbl.isHidden = false
             //self.cameraImage.isHidden = true
             self.timer.invalidate()
             return
             }*/
            
            DispatchQueue.main.async() { () -> Void in
                if (!self.imageIsNew[i]!){
                    let image = UIImage(data: data!)!
                    self.images[i] = image
                    if let cell = self.imageTableView.cellForRow(at: IndexPath(row: i, section: 0)){
                        (cell as! CameraTableViewCell).sourceImageView.image = image
                    }
                    
                    if(i == 0){
                        self.backgroundImg.image = self.blurImage(image: image)
                    }
                    self.imageIsNew[i] = true
                }
            }
        }
    }
    
    func blurImage(image: UIImage) -> UIImage{
        let currentFilter = CIFilter(name: "CIGaussianBlur")
        let beginImage = CIImage(image: image)
        currentFilter!.setValue(beginImage, forKey: kCIInputImageKey)
        currentFilter!.setValue(10, forKey: kCIInputRadiusKey)
        
        let cropFilter = CIFilter(name: "CICrop")
        cropFilter!.setValue(currentFilter!.outputImage, forKey: kCIInputImageKey)
        cropFilter!.setValue(CIVector(cgRect: beginImage!.extent), forKey: "inputRectangle")
        
        let output = cropFilter!.outputImage
        let processedImage = UIImage(ciImage: output!)
        
        return processedImage
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        for timer in timers{
            timer.invalidate()
        }
    }
}
