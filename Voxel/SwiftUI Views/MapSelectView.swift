//
//  MapSelectView.swift
//  Voxel
//
//  Created by Andy Qua on 15/01/2023.
//  Copyright © 2023 Andy Qua. All rights reserved.
//

import SwiftUI

struct MapSelectView : View {
    private var gridItemLayout = [GridItem(.adaptive(minimum: 150))]
    @State var mapImage = UIImage()
    @State var depthImage = UIImage()
    @State var pushActive = false
    
    @EnvironmentObject var appModel : AppModel

    var body : some View {
        if UIImage(named:"C1" ) == nil {
            Text("No map images found!\nDid you run the getImages.sh script from the tools folder?\n\nPlease see the README.md file for more information.")
        } else {
            ScrollView {
                LazyVGrid(columns: gridItemLayout, spacing:20) {
                    ForEach((0...29), id: \.self) { mapId in
                        if mapId == 0 {
                            Text( "Generate Terrain" )
                                .onTapGesture {
                                    appModel.path.append("Gen")
                                }

                        } else {
                            
                            Image("C\(mapId)")
                                .resizable()
                                .frame(width: 150, height: 150)
                                .cornerRadius(10)
                                .onTapGesture {
                                    appModel.mapImage = UIImage(named:"C\(mapId)")!
                                    appModel.depthImage = UIImage(named:"D\(mapId)")!
                                    appModel.path.append("\(mapId)")
                                }
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Map Select")
        }
    }
}


struct MapSelectView_Previews: PreviewProvider {
    static var previews: some View {
        MapSelectView()
    }
}
