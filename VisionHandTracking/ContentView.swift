//
//  ContentView.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 26/10/26.
//  Refactored by Senior Spatial Engineer on 28/10/26.
//

import SwiftUI
import RealityKit

public struct ContentView: View {
    @Environment(AppModel.self) private var appModel

    public init() {}

    public var body: some View {
        VStack(spacing: 24) {
            Text("Vision Hand Tracking")
                .font(.largeTitle.weight(.bold))
                .padding(.bottom, 12)
            
            ToggleImmersiveSpaceButton()
        }
        .padding(40)
        .frame(minWidth: 400)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
