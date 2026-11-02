//
//  InteractiveRotaryDial.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 02/11/26.
//

import RealityKit
import UIKit
import simd

/// Demonstrates another stacked combination: Rotate -> Push
/// 1. Requires 2 fingertips (`[.thumb, .index]`).
/// 2. Step 0: `RotateInteraction` (rotates dial 90 degrees).
/// 3. Step 1: `PushInteraction` (pushes dial inward to lock/confirm).
public struct InteractiveRotaryDial {
    
    public static func create(
        position: SIMD3<Float> = [0.18, 1.0, -0.6],
        onConfirmed: (() -> Void)? = nil
    ) -> Entity {
        let root = Entity()
        root.name = "InteractiveRotaryDialRoot"
        root.position = position
        
        // Base plate
        let baseMesh = MeshResource.generateBox(width: 0.12, height: 0.12, depth: 0.02, cornerRadius: 0.01)
        var baseMat = PhysicallyBasedMaterial()
        baseMat.baseColor = .init(tint: UIColor(white: 0.18, alpha: 1.0))
        baseMat.metallic = 0.7
        baseMat.roughness = 0.4
        let base = ModelEntity(mesh: baseMesh, materials: [baseMat])
        root.addChild(base)
        
        // Rotary Knob entity
        let knobEntity = Entity()
        knobEntity.name = "DialKnob"
        knobEntity.position = [0.0, 0.0, 0.015]
        root.addChild(knobEntity)
        
        // Dial cylinder
        let knobMesh = MeshResource.generateCylinder(height: 0.025, radius: 0.038)
        var knobMat = PhysicallyBasedMaterial()
        knobMat.baseColor = .init(tint: UIColor(red: 0.3, green: 0.35, blue: 0.45, alpha: 1.0))
        knobMat.metallic = 0.8
        knobMat.roughness = 0.25
        let knobModel = ModelEntity(mesh: knobMesh, materials: [knobMat])
        knobModel.orientation = simd_quatf(angle: .pi * 0.5, axis: [1, 0, 0])
        knobEntity.addChild(knobModel)
        
        // Pointer notch
        let notchMesh = MeshResource.generateBox(width: 0.006, height: 0.018, depth: 0.008, cornerRadius: 0.001)
        var notchMat = PhysicallyBasedMaterial()
        notchMat.baseColor = .init(tint: UIColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 1.0))
        notchMat.emissiveColor = .init(color: UIColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 0.7))
        let notch = ModelEntity(mesh: notchMesh, materials: [notchMat])
        notch.position = [0.0, 0.024, 0.015]
        knobEntity.addChild(notch)
        
        // Snap Target: Thumb + Index
        root.components.set(SnapTargetComponent(
            requiredFingers: [.thumb, .index],
            snapDistance: 0.045,
            releaseDistance: 0.08,
            snapPoints: [
                .thumb: [-0.025, 0.0, 0.025],
                .index: [0.025, 0.0, 0.025]
            ],
            defaultSnapPoint: [0.0, 0.0, 0.025],
            detectionRadius: 0.18
        ))
        
        // Flow: Step 0 (Rotate 90 degrees around Z axis) -> Step 1 (Push 1.5 cm)
        let rotateStep = RotateInteraction(
            name: "Rotate Dial",
            axis: [0, 0, 1], // rotates around local Z axis
            targetAngleRadians: .pi * 0.5,
            springBackOnRelease: false,
            affectsTransform: true,
            rotateEntity: knobEntity
        )
        
        let pushStep = PushInteraction(
            name: "Lock In",
            direction: [0, 0, -1],
            targetDistance: 0.015,
            springBackOnRelease: false,
            affectsTransform: true,
            pushEntity: knobEntity
        )
        
        var confirmedMat = PhysicallyBasedMaterial()
        confirmedMat.baseColor = .init(tint: UIColor(red: 0.2, green: 0.9, blue: 0.4, alpha: 1.0))
        confirmedMat.emissiveColor = .init(color: UIColor(red: 0.2, green: 0.9, blue: 0.4, alpha: 0.8))
        
        let flow = InteractionFlowComponent(
            steps: [rotateStep, pushStep],
            autoAdvance: true,
            releasePolicy: .resetIncompleteStepOnly,
            onStepCompleted: { stepIndex, interaction in
                if stepIndex == 0 {
                    print("[InteractiveRotaryDial] Dial turned 90°! Now push inward to confirm.")
                }
            },
            onFlowCompleted: {
                print("[InteractiveRotaryDial] Dial confirmed and locked!")
                notch.model?.materials = [confirmedMat]
                onConfirmed?()
            }
        )
        root.components.set(flow)
        
        return root
    }
}

