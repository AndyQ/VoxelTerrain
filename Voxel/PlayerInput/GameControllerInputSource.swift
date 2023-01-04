//
//  ControlInputSource.swift
//  Voxel
//
//  Created by Andy Qua on 05/11/2022.
//  Copyright © 2022 Andy Qua. All rights reserved.
//

import GameController

protocol GameControllerInputSourceDelegate: AnyObject {
    func controlInputSourceButtonPressed(_ controlInputSource: GameControllerInputSource, button: String, pressed:Bool)
    func leftControlInputSourceDidMove(_ controlInputSource: GameControllerInputSource, x:Float, y:Float)
    func rightControlInputSourceDidMove(_ controlInputSource: GameControllerInputSource, x:Float, y:Float)
}

class GameControllerInputSource {
    // MARK: Properties
    
    /// `ControlInputSourceType` delegates.
    weak var delegate: GameControllerInputSourceDelegate?
    
    let gameController: GCController
    
    // MARK: Initializers
    
    init(gameController: GCController) {
        self.gameController = gameController
        
        registerButtonEvents()
        registerMovementEvents()
    }
    
    deinit {
        self.delegate = nil
    }
    
    // MARK: Gamepad Registration Methods
    
    private func registerButtonEvents() {
        /// A handler for button press events that trigger an attack action.
        
        let changeHandler : GCControllerButtonValueChangedHandler = { [weak self] button, value, pressed in
            guard let self = self else { return }
            if let controller = self.gameController.extendedGamepad {
                
                var val : String = ""
                if button == controller.buttonA {
                    val = "A"
                }
                if button == controller.buttonB {
                    val = "B"
                }
                if button == controller.buttonX {
                    val = "X"
                }
                if button == controller.buttonY {
                    val = "Y"
                }
                
                self.delegate?.controlInputSourceButtonPressed(self, button:val, pressed:pressed)
            }
        }
        
        // `GCMicroGamepad` button handlers.
        if let extendedGamepad = gameController.extendedGamepad {
            extendedGamepad.buttonA.pressedChangedHandler = changeHandler
            extendedGamepad.buttonB.pressedChangedHandler = changeHandler
            extendedGamepad.buttonX.pressedChangedHandler = changeHandler
            extendedGamepad.buttonY.pressedChangedHandler = changeHandler
        }
    }

    
    fileprivate func registerMovementEvents()
    {
        let leftAnalogMovementHander : GCControllerDirectionPadValueChangedHandler = { [weak self] pad, xValue, yValue in
            guard let self = self else { return }
            
            self.delegate?.leftControlInputSourceDidMove(self, x:xValue, y:yValue)
        }
        let rightAnalogMovementHander : GCControllerDirectionPadValueChangedHandler = { [weak self] pad, xValue, yValue in
            guard let self = self else { return }
            
            self.delegate?.rightControlInputSourceDidMove(self, x:xValue, y:yValue)
        }

        if let extended = gameController.extendedGamepad {
            extended.leftThumbstick.valueChangedHandler = leftAnalogMovementHander
            extended.rightThumbstick.valueChangedHandler = rightAnalogMovementHander

        }
    }
}

