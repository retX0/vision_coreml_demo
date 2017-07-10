//
//  ViewController.swift
//  Vision+CoreMLDemo
//
//  Created by xnxin on 2017/7/10.
//  Copyright © 2017年 com.xnxin. All rights reserved.
//

import UIKit
import Vision
import AVKit

class ViewController: UIViewController {
    
    lazy var avSession: AVCaptureSession = AVCaptureSession()
    lazy var preViewLayer: AVCaptureVideoPreviewLayer = {
        return AVCaptureVideoPreviewLayer(session: self.avSession)
    }()
    
    lazy var inceptionv3ClassificationRequest: VNCoreMLRequest = {
        // Load the ML model through its generated class and create a Vision request for it.
        do {
            let model = try VNCoreMLModel(for: Inceptionv3().model)
            return VNCoreMLRequest(model: model, completionHandler: self.inceptionv3ClassificationHandler)
        } catch {
            fatalError("can't load Vision ML model: \(error)")
        }
    }()
    
    
    @IBOutlet weak var classifyLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAVSession()
        
        preViewLayer.frame = view.bounds
        self.view.layer.insertSublayer(preViewLayer, at: 0)
        
        avSession.startRunning()
    }
    
    fileprivate func setupAVSession() {
        
        guard let device = AVCaptureDevice.default(for: .video) else {
            fatalError("this application cannot be run on simulator")
        }
        
        do {
            
            let input = try AVCaptureDeviceInput(device: device)
            avSession.addInput(input)
            
            let output = AVCaptureVideoDataOutput()
            avSession.addOutput(output)
            
            let queue = DispatchQueue(label: "video queue", qos: .userInteractive)
            output.setSampleBufferDelegate(self, queue: queue)
        } catch let error {
            
            print(error)
        }
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try handler.perform([inceptionv3ClassificationRequest])
        } catch _ {
            
        }
    }
}

//MARK: -
//MARK: Request Hanlder

extension ViewController {
    
    func inceptionv3ClassificationHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNClassificationObservation]
            else { fatalError("unexpected result type from VNCoreMLRequest") }
        
        guard let best = observations.first
            else { fatalError("can't get best result") }
        
        DispatchQueue.main.async {
            print("Classification: \"\(best.identifier)\" Confidence: \(best.confidence)")
            self.classifyLabel.text = best.identifier
        }
    }
}
