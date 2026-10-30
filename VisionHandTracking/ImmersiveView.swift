//
//  ImmersiveView.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 26/10/26.
//  Refactored by Senior Spatial Engineer on 28/10/26.
//

import SwiftUI
import RealityKit
import ARKit
import ILSHandTracking

public struct ImmersiveView: View {
    @Environment(AppModel.self) private var appModel
    
    public init() {}
    
    public var body: some View {
        RealityView { content, attachments in
            // 1. Register all ECS components and systems
            SystemRegistry.registerAllSystems()
            
            // 2. Load the Reality Composer world scene
            let gloveScene = await GloveSpawner.loadScene()
            
            // 3. Assemble Left and Right hand entities (equipped with dual Sphere & Glove representations)
            let leftHand = HandEntityFactory.createHand(chirality: .left, gloveScene: gloveScene)
            let rightHand = HandEntityFactory.createHand(chirality: .right, gloveScene: gloveScene)
            
            content.add(leftHand)
            content.add(rightHand)
            
            // 4. Add the background world scene (cubes / props)
            if let scene = gloveScene {
                let worldRoot = Entity()
                worldRoot.name = "WorldSceneRoot"
                worldRoot.addChild(scene)
                content.add(worldRoot)
            }
            
            // 5. Add interactive snappable testing board in front of the user
            let snappableBoard = SnappableBoard.spawnInteractiveBoard(
                position: [0.0, 0.95, -0.55],
                size: [0.55, 0.03, 0.32]
            )
            content.add(snappableBoard)
            
            // 6. Attach floating spatial control panel
            if let controlPanelEntity = attachments.entity(for: "SpatialControlPanel") {
                controlPanelEntity.position = [0.0, 1.25, -0.65]
                content.add(controlPanelEntity)
            }
        } update: { content, attachments in
            // RealityView updates if needed
        } attachments: {
            Attachment(id: "SpatialControlPanel") {
                HandControlPanel()
                    .environment(appModel)
            }
        }
        .task {
            do {
                try await HandTrackingService.shared.start()
            } catch {
                print("[ImmersiveView] Error starting hand tracking: \(error.localizedDescription)")
            }
        }
        .onDisappear {
            HandTrackingService.shared.stop()
            FingertipSnappingService.shared.reset()
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
