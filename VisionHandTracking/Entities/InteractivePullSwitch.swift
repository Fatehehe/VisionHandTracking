//
//  InteractivePullSwitch.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 02/11/26.
//

import RealityKit
import UIKit
import simd

/// A ready-to-use interactive spatial safety switch demonstrating:
/// 1. Multi-fingertip snapping (requires Thumb + Index).
/// 2. Sequential interaction flow: Step 0 (Pull latch) -> Step 1 (Flip switch).
/// 3. Visual feedback (LED status indicators, physical latch slide, switch lever pivot).
public struct InteractivePullSwitch {
    
    public static func create(
        position: SIMD3<Float> = [0.0, 1.0, -0.6],
        onActivated: (() -> Void)? = nil
    ) -> Entity {
        let root = Entity()
        root.name = "InteractivePullSwitchRoot"
        root.position = position
        
        // MARK: - 1. Base Housing Mount
        let baseSize = SIMD3<Float>(0.13, 0.17, 0.025)
        let baseMesh = MeshResource.generateBox(
            width: baseSize.x,
            height: baseSize.y,
            depth: baseSize.z,
            cornerRadius: 0.01
        )
        var baseMat = PhysicallyBasedMaterial()
        baseMat.baseColor = .init(tint: UIColor(red: 0.15, green: 0.16, blue: 0.20, alpha: 1.0))
        baseMat.roughness = 0.4
        baseMat.metallic = 0.7
        let baseEntity = ModelEntity(mesh: baseMesh, materials: [baseMat])
        baseEntity.name = "SwitchBase"
        root.addChild(baseEntity)
        
        // MARK: - 2. Status LED Indicator
        let ledMesh = MeshResource.generateSphere(radius: 0.009)
        var ledMatLocked = PhysicallyBasedMaterial()
        ledMatLocked.baseColor = .init(tint: UIColor(red: 0.95, green: 0.2, blue: 0.2, alpha: 1.0))
        ledMatLocked.emissiveColor = .init(color: UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 0.8))
        ledMatLocked.roughness = 0.1
        
        let ledEntity = ModelEntity(mesh: ledMesh, materials: [ledMatLocked])
        ledEntity.name = "StatusLED"
        ledEntity.position = [0.0, 0.06, baseSize.z * 0.5 + 0.005]
        root.addChild(ledEntity)
        
        // MARK: - 3. Switch Lever
        let leverArm = Entity()
        leverArm.name = "SwitchLeverArm"
        leverArm.position = [0.0, -0.015, baseSize.z * 0.5 + 0.01]
        
        let leverBarMesh = MeshResource.generateCylinder(height: 0.07, radius: 0.006)
        var leverMat = PhysicallyBasedMaterial()
        leverMat.baseColor = .init(tint: UIColor(white: 0.85, alpha: 1.0))
        leverMat.metallic = 0.9
        leverMat.roughness = 0.15
        let leverBar = ModelEntity(mesh: leverBarMesh, materials: [leverMat])
        leverBar.position = [0.0, 0.035, 0.0]
        leverArm.addChild(leverBar)
        
        // Initial lever angle: -30 degrees (OFF)
        let initialAngle: Float = -0.52
        leverArm.orientation = simd_quatf(angle: initialAngle, axis: [1, 0, 0])
        root.addChild(leverArm)
        
        // MARK: - 4. Pull Safety Latch
        let latchEntity = Entity()
        latchEntity.name = "PullSafetyLatch"
        latchEntity.position = [0.0, 0.068, 0.0] // sits on top of lever
        leverArm.addChild(latchEntity)
        
        let latchKnobMesh = MeshResource.generateBox(width: 0.04, height: 0.018, depth: 0.022, cornerRadius: 0.004)
        var latchMat = PhysicallyBasedMaterial()
        latchMat.baseColor = .init(tint: UIColor(red: 0.9, green: 0.55, blue: 0.1, alpha: 1.0)) // safety amber/orange
        latchMat.roughness = 0.3
        latchMat.metallic = 0.5
        let latchKnob = ModelEntity(mesh: latchKnobMesh, materials: [latchMat])
        latchEntity.addChild(latchKnob)
        
        // MARK: - 5. Configure Snap Target (Thumb + Index Required!)
        // Thumb snaps to the left grip notch, Index snaps to the right grip notch
        let thumbSnapPoint = SIMD3<Float>(-0.018, 0.0, 0.02)
        let indexSnapPoint = SIMD3<Float>(0.018, 0.0, 0.02)
        
        root.components.set(SnapTargetComponent(
            requiredFingers: [.thumb, .index],
            snapDistance: 0.045,
            releaseDistance: 0.08,
            snapPoints: [
                .thumb: thumbSnapPoint,
                .index: indexSnapPoint
            ],
            defaultSnapPoint: [0, 0.05, 0.02],
            detectionRadius: 0.2
        ))
        
        // MARK: - 6. Configure Stacked Interaction Flow
        // Step 0: Pull latch out towards user by 3 cm
        let pullStep = PullInteraction(
            name: "Pull Safety Latch",
            direction: [0, 0, 1],
            targetDistance: 0.03,
            springBackOnRelease: true,
            affectsTransform: true,
            pullEntity: latchEntity
        )
        
        // Step 1: Flip switch lever forward/upward by 60 degrees
        let switchStep = SwitchInteraction(
            name: "Flip Switch Lever",
            pivotAxis: [1, 0, 0],
            offAngleRadians: -0.52,
            onAngleRadians: 0.52,
            flipDirection: [0, 1, 0],
            travelDistance: 0.035,
            toggleThreshold: 0.6,
            springBackOnRelease: true,
            affectsTransform: true,
            leverEntity: leverArm
        )
        
        var ledMatUnlocked = PhysicallyBasedMaterial()
        ledMatUnlocked.baseColor = .init(tint: UIColor(red: 0.95, green: 0.8, blue: 0.1, alpha: 1.0))
        ledMatUnlocked.emissiveColor = .init(color: UIColor(red: 0.9, green: 0.7, blue: 0.1, alpha: 0.7))
        
        var ledMatActive = PhysicallyBasedMaterial()
        ledMatActive.baseColor = .init(tint: UIColor(red: 0.1, green: 0.95, blue: 0.35, alpha: 1.0))
        ledMatActive.emissiveColor = .init(color: UIColor(red: 0.1, green: 0.95, blue: 0.35, alpha: 0.9))
        
        let flow = InteractionFlowComponent(
            steps: [pullStep, switchStep],
            autoAdvance: true,
            releasePolicy: .resetIncompleteStepOnly,
            onStepCompleted: { stepIndex, interaction in
                if stepIndex == 0 {
                    print("[InteractivePullSwitch] Step 0 complete: Safety latch pulled out! Ready to flip lever.")
                    ledEntity.model?.materials = [ledMatUnlocked]
                }
            },
            onFlowCompleted: {
                print("[InteractivePullSwitch] Flow complete: Switch fully activated!")
                ledEntity.model?.materials = [ledMatActive]
                onActivated?()
            },
            onFlowReset: {
                print("[InteractivePullSwitch] Flow reset to locked.")
                ledEntity.model?.materials = [ledMatLocked]
            }
        )
        root.components.set(flow)
        
        return root
    }
}

