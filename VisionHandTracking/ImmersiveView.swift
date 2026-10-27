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
            
            if let scene = await GloveSpawner.loadScene() {
                let hands = GloveSpawner.spawnHandGloves(from: scene)

                let worldRoot = Entity()
                worldRoot.addChild(scene)
                content.add(worldRoot)
                
                for hand in hands {
                    content.add(hand)
                }
            } else {
                print("Scene 'world' gagal dimuat.")
            }
        }
        .task {
            do {
                try await HandTrackingService.shared.start()
            } catch {
                print("Ada error hand tracking: \(error.localizedDescription)")
            }
        }
        .onDisappear {
            HandTrackingService.shared.stop()
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
