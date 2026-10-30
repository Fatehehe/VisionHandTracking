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
            // App Header
            VStack(spacing: 6) {
                Text("Vision Hand Tracking")
                    .font(.largeTitle.weight(.bold))
                
                Text("Spatial Hand Visualization & Magnetic Fingertip Snapping")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 12)
            
            // Hand Visualization Control Panel
            HandControlPanel()
            
            // Space Toggle Button
            ToggleImmersiveSpaceButton()
                .padding(.top, 8)
        }
        .padding(32)
        .frame(minWidth: 460)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
