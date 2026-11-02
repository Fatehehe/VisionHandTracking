//
//  InteractivePushButton.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 02/11/26.
//

import RealityKit
import UIKit
import simd

/// Demonstrates a single-fingertip interactive component:
/// 1. Requires only 1 fingertip (`[.index]`).
/// 2. Utilizes `PushInteraction` decoupled interaction.
public struct InteractivePushButton {
    
    public static func create(
        position: SIMD3<Float> = [-0.18, 1.0, -0.6],
        onPressed: (() -> Void)? = nil
    ) -> Entity {
        let root = Entity()
        root.name = "InteractivePushButtonRoot"
        root.position = position
        
        // Base housing
        let housingMesh = MeshResource.generateCylinder(height: 0.02, radius: 0.04)
        var housingMat = PhysicallyBasedMaterial()
        housingMat.baseColor = .init(tint: UIColor(white: 0.2, alpha: 1.0))
        housingMat.metallic = 0.8
        housingMat.roughness = 0.3
        let housing = ModelEntity(mesh: housingMesh, materials: [housingMat])
        housing.orientation = simd_quatf(angle: .pi * 0.5, axis: [1, 0, 0])
        root.addChild(housing)
        
        // Push Plunger
        let plungerMesh = MeshResource.generateCylinder(height: 0.025, radius: 0.03)
        var plungerMat = PhysicallyBasedMaterial()
        plungerMat.baseColor = .init(tint: UIColor(red: 0.0, green: 0.65, blue: 0.95, alpha: 1.0))
        plungerMat.emissiveColor = .init(color: UIColor(red: 0.0, green: 0.5, blue: 0.8, alpha: 0.4))
        let plunger = ModelEntity(mesh: plungerMesh, materials: [plungerMat])
        plunger.name = "ButtonPlunger"
        plunger.position = [0.0, 0.0, 0.01]
        plunger.orientation = simd_quatf(angle: .pi * 0.5, axis: [1, 0, 0])
        root.addChild(plunger)
        
        // Snap Target: 1 Tip (Index only)
        root.components.set(SnapTargetComponent(
            requiredFingers: [.index],
            snapDistance: 0.04,
            releaseDistance: 0.07,
            snapPoints: [.index: [0.0, 0.0, 0.02]],
            defaultSnapPoint: [0.0, 0.0, 0.02],
            detectionRadius: 0.15
        ))
        
        // Push Interaction
        let pushStep = PushInteraction(
            name: "Press Button",
            direction: [0, 0, -1], // pushes inward away from user
            targetDistance: 0.015,
            springBackOnRelease: true,
            affectsTransform: true,
            pushEntity: plunger
        )
        
        var activePlungerMat = PhysicallyBasedMaterial()
        activePlungerMat.baseColor = .init(tint: UIColor(red: 0.2, green: 0.95, blue: 0.5, alpha: 1.0))
        activePlungerMat.emissiveColor = .init(color: UIColor(red: 0.2, green: 0.95, blue: 0.5, alpha: 0.8))
        
        let flow = InteractionFlowComponent(
            steps: [pushStep],
            autoAdvance: true,
            releasePolicy: .resetIncompleteStepOnly,
            onFlowCompleted: {
                print("[InteractivePushButton] Button pressed successfully!")
                plunger.model?.materials = [activePlungerMat]
                onPressed?()
            },
            onFlowReset: {
                plunger.model?.materials = [plungerMat]
            }
        )
        root.components.set(flow)
        
        return root
    }
}

