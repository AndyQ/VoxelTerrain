//
//  ViewController.swift
//  Voxel
//
//  Created by Andy Qua on 05/11/2022.
//  Copyright © 2022 Andy Qua. All rights reserved.
//

import UIKit
import GameController
import Engine

private let maximumTimeStep: Double = 1 / 60

class VoxelViewController: UIViewController {

    private let imageView = UIImageView()
    private let fpsText = UILabel()

    private var engine : VoxelEngine!
//    private var engine : VoxelEngine_origin!
    private var lastFrameTime = CACurrentMediaTime()

    private var displayLink : CADisplayLink!
    
    var controller = GameController()

    var mapImage : UIImage!
    var depthImage : UIImage!
    
    var mapScale = 1
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = .white
        
        if mapImage == nil {
            mapImage = UIImage( named:"C1" )!
            depthImage = UIImage( named:"D1" )!
        }
                

        let mdata = mapImage.getBitmap()
        let ddata = depthImage.getBitmap()
        
        let iw = self.view.bounds.width
        let ih = self.view.bounds.height
        let aspect = iw / ih
        let w = iw < 1024 ? iw : 1024
        let h = w / aspect
        
        let s = CGSize(width:w, height:h)
        engine = VoxelEngine( mapData: mdata, depthData: ddata, size:s)

        setUpControls()
        self.view.isMultipleTouchEnabled = true

        displayLink = CADisplayLink(target: self, selector: #selector(updateView))
//        displayLink!.preferredFrameRateRange = CAFrameRateRange(minimum:120, maximum:120, preferred:120)
        displayLink.preferredFrameRateRange = .default
        displayLink.add(to: .current, forMode: .default)
        
        self.controller.setup(controllerType: .virtual)
        self.controller.showVirtualController()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.controller.hideVirtualController()
    }
    
    func setUpControls() {
        
        view.addSubview(imageView)
        view.addSubview(fpsText)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.layer.magnificationFilter = .nearest
        imageView.isUserInteractionEnabled = false
        
        fpsText.textColor = .yellow
        fpsText.translatesAutoresizingMaskIntoConstraints = false
        fpsText.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
        fpsText.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
    }

    var previousTimeInSeconds : TimeInterval = -1
    @objc func updateView(_ displayLink: CADisplayLink) {
        
        // FPS calc
//        let currentTimeInSeconds = Date().timeIntervalSince1970
//        if previousTimeInSeconds != -1 {
//            let elapsedTimeInSeconds = currentTimeInSeconds - previousTimeInSeconds
//            
//            //let actualFramesPerSecond = 1 / (displayLink.targetTimestamp - displayLink.timestamp) // is showing constant 59.xxx FPS
//            let actualFramesPerSecond = 1 / elapsedTimeInSeconds
//            
//            fpsText.text = "\(Int(actualFramesPerSecond)) fps"
//        }
//        previousTimeInSeconds = currentTimeInSeconds

        let state = controller.getState()

        self.engine.upDown = CGFloat(state["leftY"] ?? 0) * 20
        self.engine.strafeSpeed = -CGFloat(state["leftX"] ?? 0) * 2
        
        self.engine.speed = CGFloat(state["rightY"] ?? 0) * 5
        self.engine.leftRight = -CGFloat(state["rightX"] ?? 0) * 0.5
        self.engine.tilt = -CGFloat(state["rightX"] ?? 0)

        if state["buttonY"] != 0 {
            self.engine.camera.horizon += 5
        } else if state["buttonB"] != 0 {
            self.engine.camera.horizon += -5
        }
        
        let timeStep = min(maximumTimeStep, displayLink.timestamp - lastFrameTime)*1000
        self.engine.update(timeStep: timeStep )
        
        imageView.image = UIImage(bitmap:self.engine.screenImage)
        lastFrameTime = displayLink.timestamp
    }
}
