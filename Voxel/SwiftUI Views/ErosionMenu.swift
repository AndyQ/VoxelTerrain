//
//  ErosionMenu.swift
//  Voxel
//
//  Created by Andy Qua on 16/01/2023.
//  Copyright © 2023 Andy Qua. All rights reserved.
//

import SwiftUI

struct ErosionMenu: View {
    @Binding var selectedErosionType : ErosionType
    
    var body: some View {
        HStack {
            Menu("Erosion type:") {
                Button("Water erosion", action: {
                    selectedErosionType = .water
                })
                Button("Thermal erosion", action: {
                    selectedErosionType = .thermal
                })
                Button("Hydraulic erosion", action: {
                    selectedErosionType = .hydraulic
                })
            }
            Text( selectedErosionType.rawValue )
            Spacer()
        }
        
    }
}


struct ErosionMenu_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewWrapper(ErosionType.water) { ErosionMenu(selectedErosionType: $0) }
    }
}

