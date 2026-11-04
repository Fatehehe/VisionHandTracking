//
//  SwitchSystem.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 03/11/26.
//

import RealityKit
import simd

/// RealityKit System that drives mechanical switch and lever behaviors.
///
/// Hand contact detection, finger tracking, and movement deltas are computed
/// once per frame by `HandInteractionSystem` and read via `HandInteractionComponent`.
public struct SwitchSystem: System {
    
    private static let query = EntityQuery(where: .has(SwitchComponent.self))
        
    public init(scene: RealityKit.Scene) {}
        
    public func update(context: SceneUpdateContext) {
        for switchEntity in context.scene.performQuery(Self.query) {
            guard var comp = switchEntity.components[SwitchComponent.self] else { continue }
            
            // Ensure HandInteractionComponent is present with the switch's finger mode
            if switchEntity.components[HandInteractionComponent.self] == nil {
                switchEntity.components.set(HandInteractionComponent(mode: comp.fingerMode, interactionRadius: comp.interactionRadius))
            }
            
            // 1. Establish reference rotation baseline (0 radian baseline)
            if comp.initialRotation == nil {
                let currentAngle = comp.states.indices.contains(comp.currentStateIndex) ? comp.states[comp.currentStateIndex] : 0.0
                let offset = simd_quatf(angle: currentAngle, axis: simd_normalize(comp.localRotationAxis))
                comp.initialRotation = switchEntity.transform.rotation * offset.inverse
            }
            guard let initialRot = comp.initialRotation else { continue }
            
            // 2. Read normalized hand interaction data from HandInteractionComponent
            let hand = switchEntity.components[HandInteractionComponent.self]
            
            if let hand = hand, hand.isInteracting {
                if hand.phase == .began {
                    comp.startIndexAtGrab = comp.currentStateIndex
                }
                
                // Project total hand displacement onto the switch's movement axis
                let worldMovementAxis = switchEntity.parent?.convert(direction: comp.movementAxis, to: nil) ?? comp.movementAxis
                let moveAmount = simd_dot(hand.totalDelta, simd_normalize(worldMovementAxis))
                
                switch comp.behaviorMode {
                case .snap:
                    // SNAP MODE: Snap directly to the target state when movement exceeds trigger threshold
                    let triggerThreshold = comp.dragSensitivity * 0.35
                    let stepsToMove: Int
                    if abs(moveAmount) > comp.dragSensitivity {
                        stepsToMove = Int(round(moveAmount / comp.dragSensitivity))
                    } else if moveAmount > triggerThreshold {
                        stepsToMove = 1
                    } else if moveAmount < -triggerThreshold {
                        stepsToMove = -1
                    } else {
                        stepsToMove = 0
                    }
                    
                    var targetIndex = comp.startIndexAtGrab + stepsToMove
                    targetIndex = max(0, min(targetIndex, comp.states.count - 1))
                    
                    if targetIndex != comp.currentStateIndex {
                        comp.currentStateIndex = targetIndex
                        print("[SwitchSystem - Snap] Snapped to state \(targetIndex) (Angle: \(comp.states[targetIndex]) rad)")
                        comp.onStateChanged?(targetIndex)
                    }
                    
                    // Directly animate toward target rotation angle
                    let targetAngle = comp.states[comp.currentStateIndex]
                    let targetRotation = initialRot * simd_quatf(angle: targetAngle, axis: simd_normalize(comp.localRotationAxis))
                    switchEntity.transform.rotation = simd_slerp(switchEntity.transform.rotation, targetRotation, 0.55)
                    
                case .leverLike:
                    // LEVER-LIKE MODE: Continuous real-time visual tracking of the lever
                    let angle0 = comp.states.first ?? -0.52
                    let angleLast = comp.states.last ?? 0.52
                    let baseAngle = comp.states[comp.startIndexAtGrab]
                    let angleRange = angleLast - angle0
                    
                    let progress = comp.dragSensitivity > 0.001 ? (moveAmount / comp.dragSensitivity) : 0.0
                    let unclampedAngle = baseAngle + (progress * angleRange)
                    let currentAngle = simd_clamp(unclampedAngle, min(angle0, angleLast), max(angle0, angleLast))
                    
                    let dynamicRotation = initialRot * simd_quatf(angle: currentAngle, axis: simd_normalize(comp.localRotationAxis))
                    switchEntity.transform.rotation = simd_slerp(switchEntity.transform.rotation, dynamicRotation, 0.45)
                    
                    let stepsToMove = Int(round(moveAmount / comp.dragSensitivity))
                    var newIndex = comp.startIndexAtGrab + stepsToMove
                    newIndex = max(0, min(newIndex, comp.states.count - 1))
                    
                    if newIndex != comp.currentStateIndex {
                        comp.currentStateIndex = newIndex
                        print("[SwitchSystem - Lever] Lever state changed to \(newIndex)")
                        comp.onStateChanged?(newIndex)
                    }
                }
            } else {
                // 3. Resting Detent Orientation (when not interacting)
                let targetAngle = comp.states[comp.currentStateIndex]
                let targetRotation = initialRot * simd_quatf(angle: targetAngle, axis: simd_normalize(comp.localRotationAxis))
                
                switchEntity.transform.rotation = simd_slerp(
                    switchEntity.transform.rotation,
                    targetRotation,
                    comp.behaviorMode == .snap ? 0.6 : 0.35
                )
            }
            
            switchEntity.components.set(comp)
        }
    }
}
