//
//  SequentialSwitchEntity.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 03/11/26.
//

import RealityKit
import UIKit
import simd

/// A ready-to-use spatial component demonstrating the sequential interaction:
/// 1. Step 0 (Pull): Safety knob must be grabbed with thumb + index and pulled forward along its local axis (+Z).
/// 2. Step 1 (Switch): Once pulled, the switch lever unlocks and can be switched forward (ON) and backward (OFF) to toggle values!
public struct SequentialSwitchEntity {
    
    public static func create(
        position: SIMD3<Float> = [0.0, 1.0, -0.6],
        onStateChanged: ((Bool) -> Void)? = nil
    ) -> Entity {
        let root = Entity()
        root.name = "SequentialSwitchRoot"
        root.position = position
        
        // MARK: - 1. Base Housing
        let baseSize = SIMD3<Float>(0.14, 0.18, 0.025)
        let baseMesh = MeshResource.generateBox(
            width: baseSize.x,
            height: baseSize.y,
            depth: baseSize.z,
            cornerRadius: 0.01
        )
        var baseMat = PhysicallyBasedMaterial()
        baseMat.baseColor = .init(tint: UIColor(red: 0.16, green: 0.17, blue: 0.22, alpha: 1.0))
        baseMat.roughness = 0.35
        baseMat.metallic = 0.6
        let baseEntity = ModelEntity(mesh: baseMesh, materials: [baseMat])
        baseEntity.name = "ConsoleBase"
        root.addChild(baseEntity)
        
        // MARK: - 2. Status Indicator LED
        let ledMesh = MeshResource.generateSphere(radius: 0.009)
        var ledMatLocked = PhysicallyBasedMaterial()
        ledMatLocked.baseColor = .init(tint: UIColor.systemRed)
        ledMatLocked.emissiveColor = .init(color: UIColor.systemRed.withAlphaComponent(0.8))
        ledMatLocked.roughness = 0.1
        
        var ledMatUnlocked = PhysicallyBasedMaterial()
        ledMatUnlocked.baseColor = .init(tint: UIColor.systemOrange)
        ledMatUnlocked.emissiveColor = .init(color: UIColor.systemOrange.withAlphaComponent(0.8))
        
        var ledMatActive = PhysicallyBasedMaterial()
        ledMatActive.baseColor = .init(tint: UIColor.systemGreen)
        ledMatActive.emissiveColor = .init(color: UIColor.systemGreen.withAlphaComponent(0.9))
        
        let ledEntity = ModelEntity(mesh: ledMesh, materials: [ledMatLocked])
        ledEntity.name = "StatusLED"
        
        // PERBAIKAN: baseSize.z * 0.5
        ledEntity.position = [0.0, 0.065, (baseSize.z * 0.5) + 0.005]
        root.addChild(ledEntity)
        
        // MARK: - 3. Switch Lever Arm (SwitchComponent)
        let leverPivot = Entity()
        leverPivot.name = "SwitchLeverPivot"
        
        // PERBAIKAN: baseSize.z * 0.5
        leverPivot.position = [0.0, -0.015, (baseSize.z * 0.5) + 0.012]
        
        let leverArmMesh = MeshResource.generateCylinder(height: 0.075, radius: 0.006)
        var leverMat = PhysicallyBasedMaterial()
        leverMat.baseColor = .init(tint: UIColor(white: 0.85, alpha: 1.0))
        leverMat.metallic = 0.9
        leverMat.roughness = 0.2
        let leverArm = ModelEntity(mesh: leverArmMesh, materials: [leverMat])
        leverArm.position = [0.0, 0.0375, 0.0]
        leverPivot.addChild(leverArm)
        
        // Initial angle: backward (-30°)
        let backwardAngle: Float = -0.52
        let forwardAngle: Float = 0.52
        leverPivot.orientation = simd_quatf(angle: backwardAngle, axis: [1, 0, 0])
        
        // Attach SwitchComponent (initially locked!)
        leverPivot.components.set(SwitchComponent(
            switchAxis: [1, 0, 0],
            // forwardDirection, switchMode, dst diasumsikan sudah ada di definisi struct SwitchComponent Anda
            isGrabbed: false,
            isUnlocked: false,
            initialPosition: leverPivot.position,
            interactionRadius: 0.065,
            pullDistanceToUnlock: 0.035, // atau parameter sesuai definisi asli Anda
            pullAxis: [0, 0, 1]
        ))
        root.addChild(leverPivot)
        
        // MARK: - 4. Pull Safety Knob (PullComponent)
        let pullKnob = Entity()
        pullKnob.name = "PullSafetyKnob"
        pullKnob.position = [0.0, 0.075, 0.0] // Mounted at top of lever
        leverPivot.addChild(pullKnob)
        
        let knobMesh = MeshResource.generateBox(width: 0.038, height: 0.018, depth: 0.024, cornerRadius: 0.004)
        var knobMat = PhysicallyBasedMaterial()
        knobMat.baseColor = .init(tint: UIColor(red: 0.95, green: 0.55, blue: 0.1, alpha: 1.0))
        knobMat.roughness = 0.3
        knobMat.metallic = 0.4
        let knobModel = ModelEntity(mesh: knobMesh, materials: [knobMat])
        pullKnob.addChild(knobModel)
        
        // Attach PullComponent
        pullKnob.components.set(PullComponent(
            pullAxis: [0, 0, 1],
            interactionRadius: 0.05
        ))
        
        // MARK: - 5. Attach Sequence Controller to Root
        // Step 0: Pull Knob -> Step 1: Switch Lever
        root.components.set(SequenceInteractionComponent(
            steps: [.pull, .push]
        ))
        
        return root
    }
}
