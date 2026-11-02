//
//  SnapSystem.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 02/11/26.
//

import RealityKit
import ARKit
import ILSHandTracking
import simd
internal import ILSFoundation

/// RealityKit System responsible for proximity detection between tracked fingertips
/// and entities with `SnapTargetComponent`.
///
/// Features:
/// - Supports arbitrary combinations of required fingertips (1 or more).
/// - Enforces dual-threshold hysteresis (`snapDistance` vs. `releaseDistance`).
/// - Publishes active snap transforms to `SnapService` for visual synchronization and decoupled interactions.
public struct SnapSystem: System {
    public static let targetQuery = EntityQuery(where: .has(SnapTargetComponent.self))
    
    public init(scene: RealityKit.Scene) {}
    
    public func update(context: SceneUpdateContext) {
        let service = HandTrackingService.shared
        
        processHand(
            chirality: .left,
            handAnchor: service.latestLeftHand,
            scene: context.scene
        )
        processHand(
            chirality: .right,
            handAnchor: service.latestRightHand,
            scene: context.scene
        )
    }
    
    private func processHand(
        chirality: HandAnchor.Chirality,
        handAnchor: HandAnchor?,
        scene: RealityKit.Scene
    ) {
        // 1. Validate tracking state
        guard let anchor = handAnchor, anchor.isTracked, let skeleton = anchor.handSkeleton else {
            // Hand lost -> release any active snaps
            if SnapService.shared.isHandSnapped(chirality) {
                releaseActiveSnapForHand(chirality: chirality, scene: scene)
            }
            return
        }
        
        let handOrigin = anchor.originFromAnchorTransform
        
        // 2. Compute current world positions for all tracked fingertips
        var trackedTipPositions: [Finger: SIMD3<Float>] = [:]
        for (jointName, finger) in Hand.fingertipJoints {
            let jointTransform = skeleton.joint(jointName).anchorFromJointTransform
            let worldMatrix = handOrigin * jointTransform
            trackedTipPositions[finger] = worldMatrix.translation
        }
        
        // 3. Check if hand is currently engaged in an active snap
        if let snappedEntity = SnapService.shared.snappedEntity(for: chirality) {
            handleActiveSnap(
                chirality: chirality,
                entity: snappedEntity,
                trackedTips: trackedTipPositions,
                scene: scene
            )
            return
        }
        
        // 4. Hand is free: search for new candidate snap targets
        searchAndEngageCandidate(
            chirality: chirality,
            anchor: anchor,
            trackedTips: trackedTipPositions,
            scene: scene
        )
    }
    
    // MARK: - Active Snap Handling
    
    private func handleActiveSnap(
        chirality: HandAnchor.Chirality,
        entity: Entity,
        trackedTips: [Finger: SIMD3<Float>],
        scene: RealityKit.Scene
    ) {
        guard var target = entity.components[SnapTargetComponent.self],
              target.isEnabled,
              target.snappedHand == chirality else {
            SnapService.shared.releaseSnap(chirality: chirality)
            return
        }
        
        // Check if any required finger has exceeded releaseDistance
        var isBroken = false
        for finger in target.requiredFingers {
            guard let trackedPos = trackedTips[finger] else {
                isBroken = true
                break
            }
            let worldSnapPoint = target.worldSnapPoint(for: finger, entity: entity)
            let distance = simd_distance(trackedPos, worldSnapPoint)
            if distance > target.releaseDistance {
                isBroken = true
                break
            }
        }
        
        if isBroken {
            // Release snap
            target.isSnapped = false
            target.snappedHand = nil
            target.initialHandTransform = nil
            entity.components.set(target)
            
            target.onSnapReleased?(chirality)
            SnapService.shared.releaseSnap(chirality: chirality)
        } else {
            // Update snap positions to match current entity transform
            var updatedPositions: [Finger: SIMD3<Float>] = [:]
            for finger in target.requiredFingers {
                updatedPositions[finger] = target.worldSnapPoint(for: finger, entity: entity)
            }
            SnapService.shared.updateSnapPositions(chirality: chirality, fingerPositions: updatedPositions)
        }
    }
    
    // MARK: - Candidate Discovery
    
    private func searchAndEngageCandidate(
        chirality: HandAnchor.Chirality,
        anchor: HandAnchor,
        trackedTips: [Finger: SIMD3<Float>],
        scene: RealityKit.Scene
    ) {
        var bestCandidate: (entity: Entity, target: SnapTargetComponent, averageDistance: Float)?
        
        for entity in scene.performQuery(Self.targetQuery) {
            guard var target = entity.components[SnapTargetComponent.self],
                  target.isEnabled,
                  !target.isSnapped else { continue }
            
            // Check chirality filter
            if let allowed = target.allowedChirality, allowed != chirality {
                continue
            }
            
            // Optional fast-cull by detection radius
            if let radius = target.detectionRadius {
                let entityWorldPos = entity.convert(position: .zero, to: nil)
                let handWorldPos = anchor.originFromAnchorTransform.translation
                if simd_distance(entityWorldPos, handWorldPos) > (radius + 0.15) {
                    continue
                }
            }
            
            // Verify all required fingertips are within snapDistance
            var allFingersInRange = true
            var totalDistance: Float = 0
            
            for finger in target.requiredFingers {
                guard let trackedPos = trackedTips[finger] else {
                    allFingersInRange = false
                    break
                }
                
                let worldSnapPoint = target.worldSnapPoint(for: finger, entity: entity)
                let distance = simd_distance(trackedPos, worldSnapPoint)
                
                if distance > target.snapDistance {
                    allFingersInRange = false
                    break
                }
                
                totalDistance += distance
            }
            
            if allFingersInRange {
                let avgDistance = totalDistance / Float(target.requiredFingers.count)
                if let best = bestCandidate {
                    if avgDistance < best.averageDistance {
                        bestCandidate = (entity, target, avgDistance)
                    }
                } else {
                    bestCandidate = (entity, target, avgDistance)
                }
            }
        }
        
        // Engage the best candidate target
        if var (bestEntity, target, _) = bestCandidate {
            target.isSnapped = true
            target.snappedHand = chirality
            target.initialHandTransform = Transform(matrix: anchor.originFromAnchorTransform)
            bestEntity.components.set(target)
            
            var snapPoints: [Finger: SIMD3<Float>] = [:]
            for finger in target.requiredFingers {
                snapPoints[finger] = target.worldSnapPoint(for: finger, entity: bestEntity)
            }
            
            SnapService.shared.registerSnap(
                chirality: chirality,
                entity: bestEntity,
                fingerPositions: snapPoints
            )
            
            target.onSnapEngaged?(chirality)
        }
    }
    
    private func releaseActiveSnapForHand(
        chirality: HandAnchor.Chirality,
        scene: RealityKit.Scene
    ) {
        for entity in scene.performQuery(Self.targetQuery) {
            guard var target = entity.components[SnapTargetComponent.self],
                  target.snappedHand == chirality else { continue }
            
            target.isSnapped = false
            target.snappedHand = nil
            target.initialHandTransform = nil
            entity.components.set(target)
            target.onSnapReleased?(chirality)
        }
        SnapService.shared.releaseSnap(chirality: chirality)
    }
}

