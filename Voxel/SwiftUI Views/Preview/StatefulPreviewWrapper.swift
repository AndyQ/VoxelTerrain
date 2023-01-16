//
//  StatefulPreviewWrapper.swift
//  Voxel
//
//  Created by Andy Qua on 16/01/2023.
//  Copyright © 2023 Andy Qua. All rights reserved.
//

import SwiftUI


// A wrapper view for previews only to enable a binding to be passed into a view and the preview to correctly update
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content
    
    var body: some View {
        content($value)
    }
    
    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        self._value = State(wrappedValue: value)
        self.content = content
    }
}

