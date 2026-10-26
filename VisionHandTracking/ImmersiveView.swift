//
//  ImmersiveView.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 26/10/26.
//

import SwiftUI
import RealityKit
import ILSHandTracking

struct ImmersiveView: View {

    var body: some View {
        RealityView { content in
            SystemRegistry.registerAllSystems()
            
            let hands = await GloveSpawner.spawnHandGlovesAsync()
            for hand in hands {
                content.add(hand)
            }
            
        }
        .task {
            do{
                try await HandTrackingService.shared.start()
            }catch{
                print("ada error \(error.localizedDescription)")
            }
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
