//
//  AppDelegate.swift
//  Voxel
//
//  Created by Andy Qua on 05/11/2022.
//  Copyright © 2022 Andy Qua. All rights reserved.
//

import SwiftUI
import UIKit

/*  Old UIKit version - will be removed soon
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
}
*/

class AppModel : ObservableObject {
    @Published var path = NavigationPath()
    @Published var mapImage = UIImage()
    @Published var depthImage = UIImage()
}

@main
struct VoxelApp: App {
    @State private var appModel = AppModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appModel)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appModel: AppModel
    
    var body: some View {
        NavigationStack(path: $appModel.path)  {
            MapSelectView()
                .navigationDestination(for: String.self) { mapId in
                    if mapId == "Gen" {
                        TerrainGenerationView()
                    } else {
                        VoxelView(mapImage:$appModel.mapImage, depthImage: $appModel.depthImage)
                    }
                }
        }
        .environmentObject(appModel)
    }
}
