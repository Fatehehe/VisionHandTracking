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
    @PhysicalMetric(from: .meters) private var pointsPerMeter = 1
    var body: some View {
        RealityView { content in
            SystemRegistry.registerAllSystems()
            
            // Load scene utamanya terlebih dahulu
            if let scene = await GloveSpawner.loadScene() {
                
                // 1. Ekstrak (pluck) sarung tangan dari dalam scene tersebut
                let hands = GloveSpawner.spawnHandGloves(from: scene)
                
                // 2. Masukkan scene yang sudah DIBERSIHKAN dari sarung tangan ke dalam content
                let worldRoot = Entity()
                worldRoot.addChild(scene)
                content.add(worldRoot)
                
                // 3. Masukkan sarung tangan (yang sekarang jadi entitas mandiri) ke dalam content
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
    }
}

//#Preview(immersionStyle: .mixed) {
//    ImmersiveView()
//        .environment(AppModel())
//}
