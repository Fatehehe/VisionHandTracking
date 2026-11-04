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
            
            if !handComp.isInteracting {
                if let contact = detectInitialContact(hands: hands, center: entityCenter, mode: handComp.mode, radius: handComp.interactionRadius) {
                    handComp.phase = .began
                    handComp.isInteracting = true
                    handComp.activeGrip = contact.grip
                    handComp.startPosition = contact.position
                    handComp.currentPosition = contact.position
                    handComp.previousPosition = contact.position
                    handComp.totalDelta = .zero
                    handComp.frameDelta = .zero
                } else {
                    clearInteractionState(comp: &handComp, isEnded: false)
                }
            } else if let startPos = handComp.startPosition, let activeGrip = handComp.activeGrip {
                if let currentPos = trackActiveContact(hands: hands, center: entityCenter, activeGrip: activeGrip, radius: handComp.interactionRadius) {
                    handComp.phase = .active
                    let prev = handComp.currentPosition ?? currentPos
                    handComp.previousPosition = prev
                    handComp.currentPosition = currentPos
                    handComp.totalDelta = currentPos - startPos
                    handComp.frameDelta = currentPos - prev
                } else {
                    clearInteractionState(comp: &handComp, isEnded: true)
                }
            }
            
            entity.components.set(handComp)
        }
    }
    
    private func detectInitialContact(hands: [HandPose], center: SIMD3<Float>, mode: HandGestureMode, radius: Float) -> (position: SIMD3<Float>, grip: HandGestureMode)? {
        for hand in hands {
            if mode == .twoFingers || mode == .either {
                if let pinch = getPinchMidpoint(hand: hand, threshold: 0.04), simd_distance(pinch, center) <= (radius * 1.5) {
                    return (pinch, .twoFingers)
                }
            }
            
            if mode == .oneFinger || mode == .either {
                let indexTip = hand.indexTipPosition
                if simd_distance(indexTip, center) <= radius {
                    return (indexTip, .oneFinger)
                }
            }
        }
        return nil
    }
    
    private func trackActiveContact(hands: [HandPose], center: SIMD3<Float>, activeGrip: HandGestureMode, radius: Float) -> SIMD3<Float>? {
        for hand in hands {
            if activeGrip == .twoFingers {
                if let pinch = getPinchMidpoint(hand: hand, threshold: 0.055), simd_distance(pinch, center) <= (radius * 2.5) {
                    return pinch
                }
            } else if activeGrip == .oneFinger {
                let indexTip = hand.indexTipPosition
                if simd_distance(indexTip, center) <= (radius * 2.2) {
                    return indexTip
                }
            }
        }
        return nil
    }
    
    private func getPinchMidpoint(hand: HandPose, threshold: Float) -> SIMD3<Float>? {
        let allTips = [hand.thumbTipPosition] + hand.nonThumbFingertips
        for i in 0..<allTips.count {
            for j in (i + 1)..<allTips.count {
                let tip1 = allTips[i]
                let tip2 = allTips[j]
                if simd_distance(tip1, tip2) <= threshold {
                    return (tip1 + tip2) / 2.0
                }
            }
        }
        return nil
    }
    
    private func clearInteractionState(comp: inout HandInteractionComponent, isEnded: Bool) {
        comp.phase = isEnded ? .ended : .idle
        comp.isInteracting = false
        comp.activeGrip = nil
        comp.startPosition = nil
        comp.currentPosition = nil
        comp.previousPosition = nil
        comp.totalDelta = .zero
        comp.frameDelta = .zero
    }
}
