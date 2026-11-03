//
//  VisionHandTrackingApp.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 26/10/26.
//

import SwiftUI

@main
struct VisionHandTrackingApp: App {

    @State private var appModel = AppModel()
    
    init() {
        SpatialRuntime.handPoseProvider = ILSpatialHandPoseProvider()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }

        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
        .upperLimbVisibility( .hidden)
     }
}
