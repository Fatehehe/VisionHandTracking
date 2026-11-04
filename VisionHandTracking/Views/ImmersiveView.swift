//
//  ImmersiveView.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 26/10/26.
//

import SwiftUI
import RealityKit
import ARKit
import ILSHandTracking

public struct ImmersiveView: View {
    @Environment(AppModel.self) private var appModel
    
    @State private var leftHandEntity: Entity?
    @State private var rightHandEntity: Entity?
    
    public init() {}
    
    public var body: some View {
        RealityView { content, attachments in
            SystemRegistry.registerAllSystems()
            
            let gloveScene = await HandSpawner.loadScene()
            
            let leftHand = HandBuilder.createHand(chirality: .left, gloveScene: gloveScene)
            let rightHand = HandBuilder.createHand(chirality: .right, gloveScene: gloveScene)
            
            self.leftHandEntity = leftHand
            self.rightHandEntity = rightHand
            
            updateHandVisibility(for: leftHand, mode: appModel.handRepresentationMode)
            updateHandVisibility(for: rightHand, mode: appModel.handRepresentationMode)
            
            content.add(leftHand)
            content.add(rightHand)
            
            // Mengatur posisi objek berjejeran secara horizontal
            // X negatif = Kiri, X tengah = 0.0, X positif = Kanan
            let testPullKnob = HandBuilder.createPull(position: [-0.18, 1.0, -0.4]) // Standalone Pull Knob
            content.add(testPullKnob)
            
            // Standalone Switch: Snap Mode (1 or 2 fingers)
            let snapSwitch = HandBuilder.createSwitch(
                position: [0.0, 1.0, -0.4],
                fingerMode: .oneFinger,
                behaviorMode: .snap
            )
            content.add(snapSwitch)
            
            // Standalone Switch: Lever-like Mode (1 or 2 fingers)
            let leverSwitch = HandBuilder.createSwitch(
                position: [0.18, 1.0, -0.4],
                fingerMode: .twoFingers,
                behaviorMode: .leverLike
            )
            content.add(leverSwitch)
            
            if let scene = gloveScene {
                let worldRoot = Entity()
                worldRoot.name = "WorldSceneRoot"
                worldRoot.addChild(scene)
                content.add(worldRoot)
            }

            if let controlPanelEntity = attachments.entity(for: "SpatialControlPanel") {
                controlPanelEntity.position = [0.0, 1.25, -0.65]
                content.add(controlPanelEntity)
            }
        } attachments: {
            Attachment(id: "SpatialControlPanel") {
                HandControlPanel()
                    .environment(appModel)
            }
        }
        .onChange(of: appModel.handRepresentationMode) { _, newMode in
            if let left = leftHandEntity {
                print("value berubah untuk left hand")
                updateHandVisibility(for: left, mode: newMode)
            }
            if let right = rightHandEntity {
                print("value berubah untuk right hand")
                updateHandVisibility(for: right, mode: newMode)
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
        }
    }
    
    private func updateHandVisibility(for hand: Entity, mode: HandMode) {
        guard var component = hand.components[HandVisualizationComponent.self] else { return }
        component.mode = mode
        hand.components.set(component)
        
        component.jointSpheresRoot?.isEnabled = (mode == .jointSpheres)
        component.gloveRoot?.isEnabled = (mode == .gloves)
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
