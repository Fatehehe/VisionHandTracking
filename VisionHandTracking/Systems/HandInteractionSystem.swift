//
//  HandInteractionSystem.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 04/11/26.
//

import RealityKit
import ARKit
import ILSHandTracking
import simd
internal import ILSFoundation

/// RealityKit System that performs all spatial hand calculations once per entity per frame.
///
/// It updates `HandInteractionComponent` on every entity that requests hand interaction,
/// providing normalized contact detection, start positions, and displacement deltas.
public struct HandInteractionSystem: System {
    
    private static let query = EntityQuery(where: .has(HandInteractionComponent.self))
    
    public init(scene: RealityKit.Scene) {}
    
    public func update(context: SceneUpdateContext) {
        let entities = Array(context.scene.performQuery(Self.query))
        guard !entities.isEmpty else { return }
        
        let provider = SpatialRuntime.handPoseProvider
        let hands = [provider?.leftHand, provider?.rightHand].compactMap { $0 }
        
        for entity in entities {
            guard var handComp = entity.components[HandInteractionComponent.self] else { continue }
            
            let localBounds = entity.visualBounds(relativeTo: entity).center
            let entityCenter = entity.convert(position: localBounds, to: nil)
            
            // 1. If NOT currently interacting, detect contact based on configured mode
            if !handComp.isInteracting {
                var detectedPos: SIMD3<Float>? = nil
                var detectedGrip: HandGestureMode? = nil
                var detectedChirality: HandAnchor.Chirality? = nil
                var detectedFingers: Set<Finger> = []
                
                let tipFingers: [Finger] = [.thumb, .index, .middle, .ring, .little]
                
                for hand in hands {
                    // Check 2-Finger Pinch (if mode allows twoFingers)
                    if handComp.mode == .twoFingers || handComp.mode == .either {
                        let allTips = [hand.thumbTipPosition] + hand.nonThumbFingertips
                        for i in 0..<allTips.count {
                            for j in (i + 1)..<allTips.count {
                                let tip1 = allTips[i]
                                let tip2 = allTips[j]
                                if simd_distance(tip1, tip2) <= 0.04 {
                                    let pinchMidpoint = (tip1 + tip2) / 2.0
                                    if simd_distance(pinchMidpoint, entityCenter) <= (handComp.interactionRadius * 1.5) {
                                        detectedPos = pinchMidpoint
                                        detectedGrip = .twoFingers
                                        detectedChirality = (hand.chirality == .left) ? .left : .right
                                        if i < tipFingers.count && j < tipFingers.count {
                                            detectedFingers = [tipFingers[i], tipFingers[j]]
                                        } else {
                                            detectedFingers = [.thumb, .index]
                                        }
                                        break
                                    }
                                }
                            }
                            if detectedPos != nil { break }
                        }
                    }
                    
                    // Check 1-Finger Poke (if mode allows oneFinger)
                    if detectedPos == nil && (handComp.mode == .oneFinger || handComp.mode == .either) {
                        let indexTip = hand.indexTipPosition
                        if simd_distance(indexTip, entityCenter) <= handComp.interactionRadius {
                            detectedPos = indexTip
                            detectedGrip = .oneFinger
                            detectedChirality = (hand.chirality == .left) ? .left : .right
                            detectedFingers = [.index]
                            break
                        }
                    }
                    
                    if detectedPos != nil { break }
                }
                
                if let startPos = detectedPos, let grip = detectedGrip {
                    handComp.phase = .began
                    handComp.isInteracting = true
                    handComp.activeGrip = grip
                    handComp.interactingChirality = detectedChirality
                    handComp.interactingFingers = detectedFingers
                    handComp.startPosition = startPos
                    handComp.currentPosition = startPos
                    handComp.previousPosition = startPos
                    handComp.totalDelta = .zero
                    handComp.frameDelta = .zero
                } else {
                    handComp.phase = .idle
                    handComp.isInteracting = false
                    handComp.activeGrip = nil
                    handComp.interactingChirality = nil
                    handComp.interactingFingers = []
                    handComp.startPosition = nil
                    handComp.currentPosition = nil
                    handComp.previousPosition = nil
                    handComp.totalDelta = .zero
                    handComp.frameDelta = .zero
                }
            } else if let startPos = handComp.startPosition {
                // 2. Already interacting: track current hand position
                var currentPos: SIMD3<Float>? = nil
                var isStillActive = false
                
                if handComp.activeGrip == .twoFingers {
                    // Track 2-finger pinch
                    for hand in hands {
                        let allTips = [hand.thumbTipPosition] + hand.nonThumbFingertips
                        for i in 0..<allTips.count {
                            for j in (i + 1)..<allTips.count {
                                let tip1 = allTips[i]
                                let tip2 = allTips[j]
                                if simd_distance(tip1, tip2) <= 0.055 {
                                    let mid = (tip1 + tip2) / 2.0
                                    if simd_distance(mid, entityCenter) <= (handComp.interactionRadius * 2.5) {
                                        currentPos = mid
                                        isStillActive = true
                                        break
                                    }
                                }
                            }
                            if isStillActive { break }
                        }
                        if isStillActive { break }
                    }
                } else if handComp.activeGrip == .oneFinger {
                    // Track 1-finger poke
                    for hand in hands {
                        let indexTip = hand.indexTipPosition
                        if simd_distance(indexTip, entityCenter) <= (handComp.interactionRadius * 2.2) {
                            currentPos = indexTip
                            isStillActive = true
                            break
                        }
                    }
                }
                
                if isStillActive, let pos = currentPos {
                    handComp.phase = .active
                    let prev = handComp.currentPosition ?? pos
                    handComp.previousPosition = prev
                    handComp.currentPosition = pos
                    handComp.totalDelta = pos - startPos
                    handComp.frameDelta = pos - prev
                } else {
                    // Interaction ended this frame
                    handComp.phase = .ended
                    handComp.isInteracting = false
                    handComp.activeGrip = nil
                    handComp.interactingChirality = nil
                    handComp.interactingFingers = []
                    handComp.startPosition = nil
                    handComp.currentPosition = nil
                    handComp.previousPosition = nil
                    handComp.totalDelta = .zero
                    handComp.frameDelta = .zero
                }
            }
            
            entity.components.set(handComp)
        }
    }
}

