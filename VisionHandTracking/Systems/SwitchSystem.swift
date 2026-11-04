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
/// Features:
/// - Hand contact detection, finger tracking, and movement deltas are computed
///   once per frame by `HandInteractionSystem` and read via `HandInteractionComponent`.
/// - Supports continuous multi-step interaction while the hand remains attached:
///   - `.snap` Mode: Pushing past the threshold snaps directly to the target state.
///     The anchor point immediately resets to the current finger position, allowing you
///     to seamlessly continue snapping forward or backward in one continuous interaction!
///   - `.leverLike` Mode: The lever continuously follows the finger displacement in real time,
///     and snaps into the next/previous detent when crossing the 50% stroke threshold.
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
            
            if let hand = hand, hand.isInteracting, let currentHandPos = hand.currentPosition {
                // Initialize anchor when hand contact begins
                if comp.lastInteractionPosition == nil {
                    comp.lastInteractionPosition = currentHandPos
                }
                
                guard let anchor = comp.lastInteractionPosition else { continue }
                
                // Project displacement from anchor onto the switch's local movement axis
                let worldMovementAxis = switchEntity.parent?.convert(direction: comp.movementAxis, to: nil) ?? comp.movementAxis
                var moveAmount = simd_dot(currentHandPos - anchor, simd_normalize(worldMovementAxis))
                
                switch comp.behaviorMode {
                case .snap:
                    // SNAP MODE:
                    // Clamp anchor at state boundaries so reversing direction triggers immediately without deadzone
                    if comp.currentStateIndex == 0 && moveAmount < 0 {
                        comp.lastInteractionPosition = currentHandPos
                        moveAmount = 0
                    } else if comp.currentStateIndex >= (comp.states.count - 1) && moveAmount > 0 {
                        comp.lastInteractionPosition = currentHandPos
                        moveAmount = 0
                    }
                    
                    let snapThreshold = comp.dragSensitivity * 0.45
                    
                    if moveAmount > snapThreshold && comp.currentStateIndex < (comp.states.count - 1) {
                        // Snap forward to next state
                        comp.currentStateIndex += 1
                        comp.lastInteractionPosition = currentHandPos
                        print("[SwitchSystem - Snap] Snapped forward to state \(comp.currentStateIndex) (Angle: \(comp.states[comp.currentStateIndex]) rad)")
                        comp.onStateChanged?(comp.currentStateIndex)
                    } else if moveAmount < -snapThreshold && comp.currentStateIndex > 0 {
                        // Snap backward to previous state
                        comp.currentStateIndex -= 1
                        comp.lastInteractionPosition = currentHandPos
                        print("[SwitchSystem - Snap] Snapped backward to state \(comp.currentStateIndex) (Angle: \(comp.states[comp.currentStateIndex]) rad)")
                        comp.onStateChanged?(comp.currentStateIndex)
                    }
                    
                    // Directly animate toward target rotation angle with crisp snap slerp
                    let targetAngle = comp.states[comp.currentStateIndex]
                    let targetRotation = initialRot * simd_quatf(angle: targetAngle, axis: simd_normalize(comp.localRotationAxis))
                    switchEntity.transform.rotation = simd_slerp(switchEntity.transform.rotation, targetRotation, 0.55)
                    
                case .leverLike:
                    // LEVER-LIKE MODE:
                    // Clamp anchor at state boundaries
                    if comp.currentStateIndex == 0 && moveAmount < 0 {
                        comp.lastInteractionPosition = currentHandPos
                        moveAmount = 0
                    } else if comp.currentStateIndex >= (comp.states.count - 1) && moveAmount > 0 {
                        comp.lastInteractionPosition = currentHandPos
                        moveAmount = 0
                    }
                    
                    let currentBaseAngle = comp.states[comp.currentStateIndex]
                    var visualAngle = currentBaseAngle
                    let detentThreshold = comp.dragSensitivity * 0.5
                    
                    if moveAmount > 0 && comp.currentStateIndex < (comp.states.count - 1) {
                        let nextAngle = comp.states[comp.currentStateIndex + 1]
                        let progress = min(1.0, max(0.0, moveAmount / comp.dragSensitivity))
                        visualAngle = currentBaseAngle + (progress * (nextAngle - currentBaseAngle))
                        
                        // Check if dragged past the detent snap threshold
                        if moveAmount >= detentThreshold {
                            comp.currentStateIndex += 1
                            comp.lastInteractionPosition = currentHandPos
                            visualAngle = comp.states[comp.currentStateIndex]
                            print("[SwitchSystem - Lever Snap] Snapped forward to state \(comp.currentStateIndex)")
                            comp.onStateChanged?(comp.currentStateIndex)
                        }
                    } else if moveAmount < 0 && comp.currentStateIndex > 0 {
                        let prevAngle = comp.states[comp.currentStateIndex - 1]
                        let progress = min(1.0, max(0.0, -moveAmount / comp.dragSensitivity))
                        visualAngle = currentBaseAngle + (progress * (prevAngle - currentBaseAngle))
                        
                        // Check if dragged past the detent snap threshold
                        if -moveAmount >= detentThreshold {
                            comp.currentStateIndex -= 1
                            comp.lastInteractionPosition = currentHandPos
                            visualAngle = comp.states[comp.currentStateIndex]
                            print("[SwitchSystem - Lever Snap] Snapped backward to state \(comp.currentStateIndex)")
                            comp.onStateChanged?(comp.currentStateIndex)
                        }
                    }
                    
                    // Smoothly rotate following the finger during drag
                    let dynamicRotation = initialRot * simd_quatf(angle: visualAngle, axis: simd_normalize(comp.localRotationAxis))
                    switchEntity.transform.rotation = simd_slerp(switchEntity.transform.rotation, dynamicRotation, 0.5)
                }
            } else {
                // Hand is released / outside range -> reset anchor
                comp.lastInteractionPosition = nil
                
                // Settle firmly into the resting detent orientation
                let targetAngle = comp.states[comp.currentStateIndex]
                let targetRotation = initialRot * simd_quatf(angle: targetAngle, axis: simd_normalize(comp.localRotationAxis))
                
                switchEntity.transform.rotation = simd_slerp(
                    switchEntity.transform.rotation,
                    targetRotation,
                    comp.behaviorMode == .snap ? 0.6 : 0.4
                )
            }
            
            switchEntity.components.set(comp)
        }
    }
}
