//
//  DisplayLine.swift
//  Voxel
//
//  Created by Andy Qua on 15/01/2023.
//  Copyright © 2023 Andy Qua. All rights reserved.
//

import SwiftUI

class DisplayLink: NSObject, ObservableObject {
    
    private var displaylink: CADisplayLink?
    private var update: ((TimeInterval) -> Void)?
    
    var timestamp : TimeInterval {
        return displaylink?.timestamp ?? 0
    }
    
    func start(update: @escaping (TimeInterval) -> Void) {
        self.update = update
        displaylink = CADisplayLink(target: self, selector: #selector(frame))
        displaylink?.add(to: .current, forMode: .default)
    }
    
    func stop() {
        displaylink?.remove(from: .current, forMode: .default)
        update = nil
    }
    
    @objc func frame(displaylink: CADisplayLink) {
        let frameDuration = displaylink.targetTimestamp - displaylink.timestamp
        update?(frameDuration)
    }
}
