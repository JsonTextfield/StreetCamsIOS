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
    var cameras = [Camera]()
    
    @IBOutlet var imageTableView: UITableView!
    @IBOutlet var backgroundImg: UIImageView!
    
    //var portrait = true
    var dispatchGroup = DispatchGroup()
    var images = [UIImage]()
    var timers = [Timer]()
    
    
    func getSessionId(){
        let request = URLRequest(url: URL(string: "https://traffic.ottawa.ca/map")!)
        let task = URLSession.shared.dataTask(with: request as URLRequest) { data , urlResponse,_ in
            
            for camera in self.cameras{
                self.dispatchGroup.enter()
                self.download(num: camera.num)
            }
            self.dispatchGroup.notify(queue: DispatchQueue.main, execute: {
                self.comp()
            })
        }
        task.resume()
    }
    
    func comp(){
        loadingBar.stopAnimating()
        imageTableView.reloadData()
        backgroundImg.image = blurImage(image: images[0])
        for i in 0..<cameras.count{
            timers[i] = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(CameraViewController.downloadImage), userInfo: ["camera": cameras[i]], repeats: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setToolbarHidden(true, animated: true)
        loadingBar.startAnimating()
        var title = ""
        for i in cameras{
            title += i.getName()+", "
            timers.append(Timer())
        }
        let label = UILabel(frame: CGRect(x:0, y:0, width:400, height:50))
        label.backgroundColor = UIColor.clear
        label.numberOfLines = 0
        label.font = UIFont.boldSystemFont(ofSize: 14.0)
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.text = title.substring(to: title.index(title.endIndex, offsetBy: -2))
        self.navigationItem.titleView = label
        
        imageTableView.dataSource = self
        imageTableView.delegate = self
        
        getSessionId()
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let image = images[indexPath.row]
        let widthRatio = self.view.frame.width / image.size.width
        let height = widthRatio * image.size.height
        return height
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return images.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = imageTableView.dequeueReusableCell(withIdentifier: "camImage", for: indexPath) as! CameraTableViewCell
        //let cell = CameraTableViewCell(style: .default, reuseIdentifier: "camImage")
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
    func download(num: Int) {
        let url = URL(string: "https://traffic.ottawa.ca/map/camera?id=\(num)")!
        getDataFromUrl(url: url) { (data, response, error)  in
            
            let image = UIImage(data: data!)
            self.images.append(image!)
            
            self.dispatchGroup.leave()
        }
    }
    @objc func downloadImage(timer: Timer) {
        let dictionary = timer.userInfo as! [String: Camera]
        let camera = dictionary["camera"]!
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
                let image = UIImage(data: data!)
                
                if let cell = (self.imageTableView.cellForRow(at: IndexPath.init(row: self.cameras.index(of: camera)!, section: 0))){
                    let c = cell as! CameraTableViewCell
                    
                    c.sourceImageView.image = image
                }
                if(camera == self.cameras[0]){
                    self.backgroundImg.image = self.blurImage(image: image!)
                    
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
