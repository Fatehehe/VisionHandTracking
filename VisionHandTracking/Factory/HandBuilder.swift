//
//  HandBuilder.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 30/10/26.
//

import RealityKit
import ILSHandTracking
import Foundation
import ARKit
import UIKit

public struct HandBuilder {
    public static func createHand(
        chirality: HandAnchor.Chirality,
        gloveScene: Entity? = nil
    ) -> Entity {
        let handAnchor = Entity()
        handAnchor.name = (chirality == .left) ? "LeftHandAnchor" : "RightHandAnchor"
        
        handAnchor.components.set(ILHandTrackingComponent())
        
        let jointSpheres = HandSpawner.spawnJointSpheres(chirality: chirality)
        handAnchor.addChild(jointSpheres)
        
        var gloveRoot: Entity?
        var skinnedModel: ModelEntity?
        
        if let scene = gloveScene,
           let extracted = HandSpawner.spawnGlove(from: scene, chirality: chirality) {
            gloveRoot = extracted.root
            skinnedModel = extracted.skinnedModel
            handAnchor.addChild(extracted.root)
        }
        
        let currentMode = HandMode.jointSpheres
        let isVisible = true
        
        jointSpheres.isEnabled = (currentMode == .jointSpheres)
        gloveRoot?.isEnabled = (currentMode == .gloves)
        handAnchor.isEnabled = isVisible
        
        handAnchor.components.set(HandVisualizationComponent(
            chirality: chirality,
            mode: currentMode,
            isVisible: isVisible,
            jointSpheresRoot: jointSpheres,
            gloveRoot: gloveRoot,
            skinnedModel: skinnedModel
        ))
        
        return handAnchor
    }
    
    public static func createPull(position: SIMD3<Float> = [0.0, 1.0, -0.4]) -> Entity {
            let root = Entity()
            root.name = "TestPullKnob"
            root.position = position
            
            // Buat visual kubus
            let mesh = MeshResource.generateBox(width: 0.06, height: 0.06, depth: 0.06, cornerRadius: 0.01)
            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(tint: UIColor.systemOrange)
            material.roughness = 0.2
            let model = ModelEntity(mesh: mesh, materials: [material])
            
            root.addChild(model)
            
            // Pasang PullComponent
            root.components.set(PullComponent(
                pullAxis: [0, 0, 1], // Ditarik ke arah Z positif (ke arah user)
                interactionRadius: 0.06 // Jarak deteksi jari 6cm
            ))
            
            return root
        }
    
    public static func createSwitch(position: SIMD3<Float> = [0.0, 1.0, -0.4]) -> Entity {
            let root = Entity()
            root.name = "TestSwitch"
            root.position = position
            
            // Buat visual kubus
            let mesh = MeshResource.generateBox(width: 0.06, height: 0.06, depth: 0.06, cornerRadius: 0.01)
            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(tint: UIColor.systemBlue)
            material.roughness = 0.2
            let model = ModelEntity(mesh: mesh, materials: [material])
            
            root.addChild(model)
            
            // Pasang PullComponent
            root.components.set(SwitchComponent())
            
            return root
        }
}
