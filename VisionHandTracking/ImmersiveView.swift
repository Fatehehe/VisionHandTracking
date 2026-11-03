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
    
    // 1. Simpan referensi ke root utama yang membungkus semua objek
    @State private var masterRootEntity: Entity?
    
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
            
            // 2. Buat Master Root untuk menampung Tangan dan World
            let masterRoot = Entity()
            masterRoot.name = "MasterRoot"
            self.masterRootEntity = masterRoot
            
            masterRoot.addChild(leftHand)
            masterRoot.addChild(rightHand)
            
            if let scene = gloveScene {
                let worldRoot = Entity()
                worldRoot.name = "WorldSceneRoot"
                // Aktifkan local axis (Visibility awalnya akan di-handle oleh Helper di bawah)
                worldRoot.enableLocalAxis(length: 0.08, category: .elements)
                worldRoot.addChild(scene)
                
                masterRoot.addChild(worldRoot)
            }

            // Tambahkan Master Root ke content RealityKit
            content.add(masterRoot)
            
            // Sinkronisasi state Axis saat pertama kali dimuat
            updateAxesVisibility(in: masterRoot)

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
                updateHandVisibility(for: left, mode: newMode)
            }
            if let right = rightHandEntity {
                updateHandVisibility(for: right, mode: newMode)
            }
        }
        .onChange(of: appModel.showLocalAxisMode) { _, _ in
            if let root = masterRootEntity {
                updateAxesVisibility(in: root)
            }
        }
        .onChange(of: appModel.localAxisMode) { _, _ in
            if let root = masterRootEntity {
                updateAxesVisibility(in: root)
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
    
    private func updateAxesVisibility(in root: Entity) {
        let isMasterEnabled = appModel.showLocalAxisMode
        let currentFilter = appModel.localAxisMode
        
        traverseAndSetAxis(entity: root, isMasterEnabled: isMasterEnabled, filter: currentFilter)
    }
    
    private func traverseAndSetAxis(entity: Entity, isMasterEnabled: Bool, filter: LocalAxisCategory) {
        if var axisComp = entity.components[LocalAxisComponent.self] {
            let matchesFilter: Bool
            
            switch filter {
            case .all:
                matchesFilter = true
            case .elements:
                matchesFilter = (axisComp.category == .elements)
            case .fingertips:
                matchesFilter = (axisComp.category == .fingertips)
            case .hands:
                matchesFilter = (axisComp.category == .hands)
            case .joints:
                matchesFilter = (axisComp.category == .joints)
            }
            
            let shouldBeVisible = isMasterEnabled && matchesFilter
            axisComp.isVisible = shouldBeVisible
            entity.components.set(axisComp)
        }
        
        for child in entity.children {
            traverseAndSetAxis(entity: child, isMasterEnabled: isMasterEnabled, filter: filter)
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
