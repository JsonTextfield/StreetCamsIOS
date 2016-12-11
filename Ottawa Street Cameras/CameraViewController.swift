//
//  CameraViewController.swift
//  Ottawa Street Cameras
//
//  Created by Peckford on 2016-12-10.
//  Copyright © 2016 JsonTextfield. All rights reserved.
//

import UIKit

class CameraViewController: UIViewController {
    var cam: Camera = Camera.init(name: "", id: "")
    @IBOutlet var cameraImage: UIImageView!
    
    var url = ""
    var timer:Timer = Timer.init()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = cam.name
        url = "https://traffic.ottawa.ca/map/camera?id=\(cam.id)"
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(CameraViewController.downloadImage), userInfo: nil, repeats: true)
        
    }
    func getDataFromUrl(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            completion(data, response, error)
            }.resume()
    }
    func downloadImage() {
        let url = URL(string: self.url)!
        getDataFromUrl(url: url) { (data, response, error)  in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async() { () -> Void in
                print("image")
                self.cameraImage.image = UIImage(data: data)
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
