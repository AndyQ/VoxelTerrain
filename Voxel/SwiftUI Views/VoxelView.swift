//
//  VoxelView.swift
//  Voxel
//
//  Created by Andy Qua on 15/01/2023.
//  Copyright © 2023 Andy Qua. All rights reserved.
//

import SwiftUI
import Engine

struct VoxelView : View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var controller = GameController()
    
    @Binding var mapImage : UIImage
    @Binding var depthImage : UIImage
    
    @State private var overheadMapImage = Image(uiImage:UIImage())
    
    @State private var displayLink = DisplayLink()
    @State private var frameImage = Image(uiImage:UIImage())
    @State private var engine : VoxelEngine!
    @State private var lastFrameTime = CACurrentMediaTime()
    @State private var playerPos: CGPoint = .zero
    @State private var angle: Double = 0
    
    var btnBack : some View {
        Button(action: {
            self.controller.hideVirtualController()
            displayLink.stop()
            
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Text("Back")
                .foregroundColor(.white)
        }
    }
    
    var body : some View {
        GeometryReader { geometry in
            ZStack {
                frameImage
                    .resizable()
                    .ignoresSafeArea()
                
                VStack {
                    HStack {
                        Spacer()
                        OverheadMapView(mapImage: $mapImage, playerPos: $playerPos, angle: $angle)
                    }
                    Spacer()
                }
            }
            .onAppear {
                setup(geometry)
                self.controller.setup(controllerType: .virtual)
                self.controller.showVirtualController()
                displayLink.start { frameDuration in
                    update(frameDuration)
                }
                
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: btnBack)
        }
    }
    
    func setup(_ geometry : GeometryProxy ) {
        
        let mdata = mapImage.getBitmap()
        let ddata = depthImage.getBitmap()
        
        let iw = geometry.size.width
        let ih = geometry.size.height
        let aspect = iw / ih
        let w = iw < 1024 ? iw : 1024
        let h = w / aspect
        
        print( "w - \(w), h - \(h)")
        let s = CGSize(width:w, height:h)
        engine = VoxelEngine( mapData: mdata, depthData: ddata, size:s)
        
    }
    
    func update( _ frameDuration : Double ) {
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
        
        let maximumTimeStep: Double = 1 / 60
        let timeStep = min(maximumTimeStep, displayLink.timestamp - lastFrameTime)*1000
        self.engine.update(timeStep: timeStep )
        
        updatePlayerDotPosition()
        
        let i = UIImage(bitmap:self.engine.screenImage)!
        frameImage = Image(uiImage:i)
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
        let mx = ((x / mapSize) * 128)
        let my = ((y / mapSize) * 128)
        
        playerPos = CGPoint( x: mx, y: my)
        angle = engine.camera.angle
    }
    
}


//struct VoxelView_Previews: PreviewProvider {
//    static var previews: some View {
//        VoxelView()
//    }
//}
