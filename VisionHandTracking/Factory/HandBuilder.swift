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
    
    public static func createSwitch(
        position: SIMD3<Float> = [0.0, 1.0, -0.4],
        fingerMode: SwitchFingerMode = .either,
        behaviorMode: SwitchBehaviorMode = .snap
    ) -> Entity {
        let root = Entity()
        root.name = "TestSwitchRoot"
        root.position = position
        
        // Base mount
        let baseMesh = MeshResource.generateBox(width: 0.08, height: 0.02, depth: 0.08, cornerRadius: 0.005)
        var baseMat = PhysicallyBasedMaterial()
        baseMat.baseColor = .init(tint: UIColor(white: 0.22, alpha: 1.0))
        baseMat.roughness = 0.4
        baseMat.metallic = 0.5
        let base = ModelEntity(mesh: baseMesh, materials: [baseMat])
        root.addChild(base)
        
        // Switch lever arm pivoting at base
        let lever = Entity()
        lever.name = "SwitchLever"
        lever.position = [0, 0.01, 0]
        
        let armMesh = MeshResource.generateCylinder(height: 0.075, radius: 0.006)
        var armMat = PhysicallyBasedMaterial()
        armMat.baseColor = .init(tint: UIColor(white: 0.85, alpha: 1.0))
        armMat.metallic = 0.9
        armMat.roughness = 0.2
        let arm = ModelEntity(mesh: armMesh, materials: [armMat])
        arm.position = [0, 0.0375, 0]
        lever.addChild(arm)
        
        // Colored knob on top of the lever
        let knobMesh = MeshResource.generateSphere(radius: 0.013)
        var knobMat = PhysicallyBasedMaterial()
        knobMat.baseColor = .init(tint: UIColor.systemCyan)
        knobMat.roughness = 0.2
        let knob = ModelEntity(mesh: knobMesh, materials: [knobMat])
        knob.position = [0, 0.075, 0]
        lever.addChild(knob)
        
        // Initial angle: backward (-30° / -0.52 rad)
        let backwardAngle: Float = -0.52
        let forwardAngle: Float = 0.52
        lever.orientation = simd_quatf(angle: backwardAngle, axis: [1, 0, 0])
        
        // Attach SwitchComponent
        lever.components.set(SwitchComponent(
            states: [backwardAngle, forwardAngle],
            currentStateIndex: 0,
            localRotationAxis: [1, 0, 0],
            movementAxis: [0, 0, 1],
            dragSensitivity: 0.035,
            interactionRadius: 0.065,
            fingerMode: fingerMode,
            behaviorMode: behaviorMode,
            onStateChanged: { index in
                let isOn = index > 0
                print("[TestSwitch] Toggled to state: \(isOn ? "FORWARD (ON)" : "BACKWARD (OFF)") [Index: \(index)]")
                var mat = PhysicallyBasedMaterial()
                mat.baseColor = .init(tint: isOn ? UIColor.systemGreen : UIColor.systemCyan)
                knob.model?.materials = [mat]
            }
        ))
        
        root.addChild(lever)
        return root
    }
}
