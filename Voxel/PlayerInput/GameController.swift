//
//  GameController.swift
//  Voxel
//
//  Created by Andy Qua on 05/11/2022.
//  Copyright © 2022 Andy Qua. All rights reserved.
//

import Foundation
import UIKit
import CoreMotion
import GameController

enum ControllerType {
    case accelerometer
    case external
    case virtual
}

class GameController {
        
    var buttonPressed : ((String, Bool)->())?
    var pausePressed : (()->())?
    var returnToMenu : (()->())?
    var leftStickMoved : ((Float, Float)->())?
    var rightStickMoved : ((Float, Float)->())?
        
    var inputSource : GameControllerInputSource?
    
    
#if os( iOS )
    private var _virtualController: Any?
    
    public var virtualController: GCVirtualController? {
        get { return self._virtualController as? GCVirtualController }
        set { self._virtualController = newValue }
    }
#endif
    
    func hideVirtualController() {
        virtualController?.disconnect()
    }
    
    func showVirtualController() {
        virtualController?.connect()
    }
    
    func setup( controllerType : ControllerType ) {
        observeForGameControllers()
    }

    func observeForGameControllers() {
#if os( iOS )
        let virtualConfiguration = GCVirtualController.Configuration()
        
        virtualConfiguration.elements = [GCInputLeftThumbstick, GCInputRightThumbstick, GCInputButtonA, GCInputButtonB, GCInputButtonX, GCInputButtonY]

        virtualController = GCVirtualController(configuration: virtualConfiguration)
        
        virtualController?.controller?.extendedGamepad?.buttonX.sfSymbolsName = "arrow.up"
        virtualController?.updateConfiguration(forElement: GCInputButtonA, configuration: { _ in
            let c = GCVirtualController.ElementConfiguration()
            c.isHidden = true
            return c
        })
        
        virtualController?.updateConfiguration(forElement: GCInputButtonX, configuration: { _ in
            let c = GCVirtualController.ElementConfiguration()
            c.isHidden = true
            return c
        })
        
        virtualController?.updateConfiguration(forElement: GCInputButtonY, configuration: { _ in
            
            let path = UIBezierPath.arrow(from: CGPoint( x:0, y:-1), to: CGPoint( x:0, y:1), tailWidth: 0.1, headWidth: 0.25, headLength: 1)
            
            let c = GCVirtualController.ElementConfiguration()
            c.path = path
            
            return c
        })

        virtualController?.updateConfiguration(forElement: GCInputButtonB, configuration: { _ in
            
            let path = UIBezierPath.arrow(from: CGPoint( x:0, y:1), to: CGPoint( x:0, y:-1), tailWidth: 0.1, headWidth: 0.25, headLength: 1)
            
            let c = GCVirtualController.ElementConfiguration()
            c.path = path
            
            return c
        })
        virtualController?.connect()
        
        guard let gameController = virtualController?.controller as? GCController else {
            return
        }

        inputSource = GameControllerInputSource(gameController: gameController)
        inputSource?.delegate = self

#endif
    }
    
    var state : [String:Float] = [
        "leftX" : 0,
        "leftY" : 0,
        "rightX" : 0,
        "rightY" : 0,
        "buttonA" : 0,
        "buttonB" : 0,
        "buttonX" : 0,
        "buttonY" : 0,
    ]

    func getState() -> [String:Float] {
        guard let gp = virtualController?.controller?.extendedGamepad else { return [:] }
        
        state["leftX"] = gp.leftThumbstick.xAxis.value
        state["leftY"] = gp.leftThumbstick.yAxis.value
        state["rightX"] = gp.rightThumbstick.xAxis.value
        state["rightY"] = gp.rightThumbstick.yAxis.value
        state["buttonA"] = gp.buttonA.value
        state["buttonB"] = gp.buttonB.value
        state["buttonX"] = gp.buttonX.value
        state["buttonY"] = gp.buttonY.value
        
        return state
    }
    
}


extension GameController : GameControllerInputSourceDelegate {
    func leftControlInputSourceDidMove(_ controlInputSource: GameControllerInputSource, x: Float, y: Float) {
        leftStickMoved?( x, y )
    }
    
    func rightControlInputSourceDidMove(_ controlInputSource: GameControllerInputSource, x: Float, y: Float) {
        rightStickMoved?( x, y )
    }
    
    func controlInputSourceDidTogglePauseState(_ controlInputSource: GameControllerInputSource) {
        pausePressed?()
    }
    
    func controlInputSourceButtonPressed(_ controlInputSource: GameControllerInputSource, button: String, pressed: Bool) {
        buttonPressed?(button, pressed)
    }
    
    func controlInputSourceDidRotate(_ controlInputSource: GameControllerInputSource, angle: Float) {
    }
    
        
    func controlInputSourceReturnToMenu(_ controlInputSource: GameControllerInputSource) {
        returnToMenu?()

    }
}
