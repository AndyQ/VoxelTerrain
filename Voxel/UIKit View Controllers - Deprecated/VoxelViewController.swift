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

class PlayerDot : UIView {
    var pos : CGPoint = .zero
    var angle: Double = 0
    
    func update(pos: CGPoint, angle: Double ) {
        self.angle = angle
        
        self.frame.origin.x = pos.x - (self.bounds.width/2)
        self.frame.origin.y = pos.y - (self.bounds.height/2)
        self.setNeedsDisplay()

    }
    
    override func draw(_ rect: CGRect) {
        let cx = self.bounds.size.width/2
        let cy = self.bounds.size.height/2
        
        let deg = Int(rad2deg(angle))
        let nx = cx + 10 * cos(deg2rad(deg))
        let ny = cy + 10 * sin(deg2rad(deg))
        
        UIColor.red.set()
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.addRect(CGRect(x: cx-1.5, y: cy-1.5, width: 3, height: 3))
        context.fillPath()

        context.setLineWidth(1)
        context.move(to: CGPoint(x: cx, y: cy))
        context.addLine(to: CGPoint(x: nx, y: ny))
        context.strokePath()

    }
}



class VoxelViewController: UIViewController {

    private let mapView: UIImageView = UIImageView()
    private let playerDot: PlayerDot = PlayerDot()

    private let imageView = UIImageView()
    private let fpsText = UILabel()

    private var engine : VoxelEngine!
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
        displayLink.preferredFrameRateRange = .default
        displayLink.add(to: .current, forMode: .default)
        
        self.controller.setup(controllerType: .virtual)
        self.controller.showVirtualController()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        displayLink.invalidate()
        self.controller.hideVirtualController()
    }
    
    deinit {
        print( "GONE")
    }
    
    func setUpControls() {
        
        view.addSubview(imageView)
        view.addSubview(mapView)
        mapView.addSubview(playerDot)
        view.addSubview(fpsText)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        mapView.translatesAutoresizingMaskIntoConstraints = false
        fpsText.translatesAutoresizingMaskIntoConstraints = false

        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.layer.magnificationFilter = .nearest
        imageView.isUserInteractionEnabled = false
        
        playerDot.frame = CGRect(x: 50,y: 50,width: 20, height: 20)
        playerDot.backgroundColor = .clear
        
        mapView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
        mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        mapView.widthAnchor.constraint(equalToConstant: 128).isActive = true
        mapView.heightAnchor.constraint(equalToConstant: 128).isActive = true
        mapView.contentMode = .scaleAspectFit
        mapView.isUserInteractionEnabled = true
        mapView.image = mapImage

        fpsText.textColor = .yellow
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
        
        updatePlayerDotPosition()

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
        
        let i =  UIImage(bitmap:self.engine.screenImage)
        imageView.image = i
        lastFrameTime = displayLink.timestamp
    }
    
    func updatePlayerDotPosition() {
        
        let mapSize = mapImage.size.width * Double(engine.mapScale)
        var x = self.engine.camera.x.truncatingRemainder(dividingBy: mapSize)
        var y = self.engine.camera.y.truncatingRemainder(dividingBy: mapSize)
        if x < 0 {
            x += mapSize
        }
        if y < 0 {
            y += mapSize
        }
        let mx = ((x / mapSize) * mapView.frame.size.width)
        let my = ((y / mapSize) * mapView.frame.size.height)

        playerDot.update( pos: CGPoint(x:mx, y:my), angle: engine.camera.angle)
    }

}
