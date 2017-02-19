//
//  ViewController.swift
//  CustomCamera
//
//  Created by Reece Kenney on 15/02/2017.
//  Copyright © 2017 Reece Kenney. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let captureSession = AVCaptureSession()
    var previewLayer:CALayer!
    
    var captureDevice: AVCaptureDevice!
    var takePhoto:Bool = false
    var imageView:UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Make navigation bar transparent
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.tintColor = .white
        
        prepareCamera()
        addButtons()
        
        imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        imageView.contentMode = .scaleAspectFill        
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "cross"), style: .plain, target: self, action: #selector(clearImage))
        
        view.addSubview(imageView)
    }
    
    //Adds buttons to camera screen
    func addButtons() {
        
        let photoButtonWidth:CGFloat = 65.0
        let photoButton = UIImageView(frame: CGRect(x: view.frame.midX - photoButtonWidth / 2, y: view.frame.height - photoButtonWidth - 20, width: photoButtonWidth, height: photoButtonWidth))
        photoButton.image = UIImage(named: "take-photo")
        let photoRecognizer = UITapGestureRecognizer(target: self, action: #selector(clearImage))
        photoButton.addGestureRecognizer(photoRecognizer)
        photoButton.isUserInteractionEnabled = true
        view.addSubview(photoButton)
    }
    
    func prepareCamera() {
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        
        if let availableDevices = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: .back).devices {
            captureDevice = availableDevices.first
            beginSession()
        }
    }
    
    func beginSession() {
        
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            
            captureSession.addInput(captureDeviceInput)
        }catch {
            print(error.localizedDescription)
        }
        
        if let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession) {
            
            let bounds = view.layer.bounds
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            previewLayer.bounds = bounds
            previewLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
            
            self.previewLayer = previewLayer
            self.view.layer.addSublayer(self.previewLayer)
            self.previewLayer.frame = self.view.layer.frame
            captureSession.startRunning()
            
            let dataOutput = AVCaptureVideoDataOutput()
            dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String):NSNumber(value: kCVPixelFormatType_32BGRA)]
            dataOutput.alwaysDiscardsLateVideoFrames = true
            
            if captureSession.canAddOutput(dataOutput) {
                captureSession.addOutput(dataOutput)
            }
            
            captureSession.commitConfiguration()
            
            let queue = DispatchQueue(label: "captureQueue")
            dataOutput.setSampleBufferDelegate(self, queue: queue)
            
            
        }
    }
    
    func clearImage() {
        
        if imageView.image != nil {
            imageView.image = nil
        }
        else {
            takePhoto = true
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        
        if takePhoto {
            takePhoto = false
            
            if let image = getImageFromSampleBuffer(buffer: sampleBuffer) {
                
                DispatchQueue.main.async {
                    self.imageView.image = image
                }
                
            }
            
        }
    }
    
    func getImageFromSampleBuffer(buffer: CMSampleBuffer) -> UIImage? {
        
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            let cIImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            
            if let image = context.createCGImage(cIImage, from: imageRect) {
                return UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .right)
            }
        }
        
        return nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

