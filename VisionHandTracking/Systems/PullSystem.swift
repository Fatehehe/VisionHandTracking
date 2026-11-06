//
//  PullSystem.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 03/11/26.
//

import RealityKit
import simd

/// RealityKit System that handles pulling interactions.
///
/// It delegates all raw hand contact detection and movement calculation to `HandInteractionComponent`.
public struct PullSystem: System {
    
    private static let query = EntityQuery(where: .has(PullComponent.self))
        
    public init(scene: RealityKit.Scene) {}
        
    public func update(context: SceneUpdateContext) {
        for pullEntity in context.scene.performQuery(Self.query) {
            guard var comp = pullEntity.components[PullComponent.self] else { continue }
            
            // Ensure HandInteractionComponent is present
            if pullEntity.components[HandInteractionComponent.self] == nil {
                pullEntity.components.set(HandInteractionComponent(mode: .twoFingers, interactionRadius: comp.interactionRadius))
            }
            
            if comp.initialPosition == nil {
                comp.initialPosition = pullEntity.transform.translation
            }
            guard let initialPos = comp.initialPosition else { continue }
            
            let hand = pullEntity.components[HandInteractionComponent.self]
                    
            if let hand = hand, hand.isInteracting {
                comp.isGrabbed = true // Broadcast bahwa objek sedang dipegang
                comp.grabbingChirality = hand.interactingChirality
                
                let worldPullAxis = pullEntity.parent?.convert(direction: comp.pullAxis, to: nil) ?? comp.pullAxis
                let pullAmount = simd_dot(hand.totalDelta, simd_normalize(worldPullAxis))
                
                let visualPull = max(0, min(pullAmount, comp.pullDistanceToUnlock))
                let targetTranslation = initialPos + (comp.pullAxis * visualPull)
                
                pullEntity.transform.translation = simd_mix(
                    pullEntity.transform.translation,
                    targetTranslation,
                    SIMD3<Float>(repeating: 0.4)
                )
                
                if !comp.isUnlocked && pullAmount >= comp.pullDistanceToUnlock {
                    comp.isUnlocked = true
                    print("[PullSystem] Safety latch unlocked! Ready to switch.")
                }
            } else {
                comp.isGrabbed = false // Lepas pegangan
                comp.grabbingChirality = nil
                
                let targetPos = comp.isUnlocked
                    ? initialPos + (comp.pullAxis * comp.pullDistanceToUnlock)
                    : initialPos
                
                pullEntity.transform.translation = simd_mix(
                    pullEntity.transform.translation,
                            targetPos,
                            SIMD3<Float>(repeating: 0.25)
                        )
                    }
                    
                    pullEntity.components.set(comp)
        }
    }
}
