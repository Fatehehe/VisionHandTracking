//
//  SwitchSystem.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 03/11/26.
//

import RealityKit
import ARKit
import ILSHandTracking
import simd
internal import ILSFoundation

/// RealityKit System that drives mechanical switch and lever interactions using spatial hand tracking.
///
/// Features:
/// - Supports configurable finger modes:
///   - `.oneFinger`: Poke/push with the index fingertip.
///   - `.twoFingers`: Pinch/grab with thumb + fingertip.
///   - `.either`: Accepts both 1-finger poke and 2-finger pinch gestures.
/// - Supports configurable physical behavior modes:
///   - `.snap`: Automatically snaps directly to the target rotation angle when triggered.
///   - `.leverLike`: Continuously tracks hand movement in real time and snaps to detent on release.
public struct SwitchSystem: System {
    
    private static let query = EntityQuery(where: .has(SwitchComponent.self))
        
    public init(scene: RealityKit.Scene) {}
        
    public func update(context: SceneUpdateContext) {
        let switches = Array(context.scene.performQuery(Self.query))
        guard !switches.isEmpty else { return }
            
        let provider = SpatialRuntime.handPoseProvider
        let hands = [provider?.leftHand, provider?.rightHand].compactMap { $0 }
            
        for switchEntity in switches {
            guard var comp = switchEntity.components[SwitchComponent.self] else { continue }
            
            // 1. Establish reference rotation baseline (0 radian baseline)
            if comp.initialRotation == nil {
                let currentAngle = comp.states.indices.contains(comp.currentStateIndex) ? comp.states[comp.currentStateIndex] : 0.0
                let offset = simd_quatf(angle: currentAngle, axis: simd_normalize(comp.localRotationAxis))
                comp.initialRotation = switchEntity.transform.rotation * offset.inverse
            }
            
            guard let initialRot = comp.initialRotation else { continue }
            
            // 2. Compute interaction center in world coordinates
            let localBounds = switchEntity.visualBounds(relativeTo: switchEntity).center
            let switchCenter = switchEntity.convert(position: localBounds, to: nil)
            
            // 3. Contact Detection (when not currently interacting)
            if !comp.isInteracting {
                var detectedPos: SIMD3<Float>? = nil
                var detectedGrip: SwitchFingerMode? = nil
                
                for hand in hands {
                    // Check 2-Finger Pinch (if mode allows twoFingers)
                    if comp.fingerMode == .twoFingers || comp.fingerMode == .either {
                        let allTips = [hand.thumbTipPosition] + hand.nonThumbFingertips
                        for i in 0..<allTips.count {
                            for j in (i + 1)..<allTips.count {
                                let tip1 = allTips[i]
                                let tip2 = allTips[j]
                                if simd_distance(tip1, tip2) <= 0.04 {
                                    let pinchMidpoint = (tip1 + tip2) / 2.0
                                    if simd_distance(pinchMidpoint, switchCenter) <= (comp.interactionRadius * 1.5) {
                                        detectedPos = pinchMidpoint
                                        detectedGrip = .twoFingers
                                        break
                                    }
                                }
                            }
                            if detectedPos != nil { break }
                        }
                    }
                    
                    // Check 1-Finger Poke/Push (if mode allows oneFinger)
                    if detectedPos == nil && (comp.fingerMode == .oneFinger || comp.fingerMode == .either) {
                        let indexTip = hand.indexTipPosition
                        if simd_distance(indexTip, switchCenter) <= comp.interactionRadius {
                            detectedPos = indexTip
                            detectedGrip = .oneFinger
                            break
                        }
                    }
                    
                    if detectedPos != nil { break }
                }
                
                if let startPos = detectedPos, let grip = detectedGrip {
                    comp.isInteracting = true
                    comp.activeGrip = grip
                    comp.startFingerPosition = startPos
                    comp.startIndexAtGrab = comp.currentStateIndex
                }
            }
            
            // 4. Handle Active Switch Interaction
            if comp.isInteracting, let startPos = comp.startFingerPosition {
                var currentInteractionPos: SIMD3<Float>? = nil
                var isStillActive = false
                
                if comp.activeGrip == .twoFingers {
                    // Track 2-finger pinch
                    for hand in hands {
                        let allTips = [hand.thumbTipPosition] + hand.nonThumbFingertips
                        for i in 0..<allTips.count {
                            for j in (i + 1)..<allTips.count {
                                let tip1 = allTips[i]
                                let tip2 = allTips[j]
                                if simd_distance(tip1, tip2) <= 0.055 {
                                    let mid = (tip1 + tip2) / 2.0
                                    if simd_distance(mid, switchCenter) <= (comp.interactionRadius * 2.5) {
                                        currentInteractionPos = mid
                                        isStillActive = true
                                        break
                                    }
                                }
                            }
                            if isStillActive { break }
                        }
                        if isStillActive { break }
                    }
                } else if comp.activeGrip == .oneFinger {
                    // Track 1-finger poke/push
                    for hand in hands {
                        let indexTip = hand.indexTipPosition
                        if simd_distance(indexTip, switchCenter) <= (comp.interactionRadius * 2.2) {
                            currentInteractionPos = indexTip
                            isStillActive = true
                            break
                        }
                    }
                }
                
                if isStillActive, let handPos = currentInteractionPos {
                    let handDelta = handPos - startPos
                    let worldMovementAxis = switchEntity.parent?.convert(direction: comp.movementAxis, to: nil) ?? comp.movementAxis
                    let moveAmount = simd_dot(handDelta, simd_normalize(worldMovementAxis))
                    
                    switch comp.behaviorMode {
                    case .snap:
                        // SNAP MODE: Evaluates movement direction and snaps directly to the target rotation
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
                        
                        // In snap mode, rotation directly interpolates toward target angle
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
                        
                        // Rotate smoothly following the finger
                        let dynamicRotation = initialRot * simd_quatf(angle: currentAngle, axis: simd_normalize(comp.localRotationAxis))
                        switchEntity.transform.rotation = simd_slerp(switchEntity.transform.rotation, dynamicRotation, 0.45)
                        
                        // Determine discrete target state
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
                    // Hand released or moved outside interaction range
                    comp.isInteracting = false
                    comp.activeGrip = nil
                    comp.startFingerPosition = nil
                }
            }
            
            // 5. Resting Detent Orientation (when not interacting)
            if !comp.isInteracting {
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
