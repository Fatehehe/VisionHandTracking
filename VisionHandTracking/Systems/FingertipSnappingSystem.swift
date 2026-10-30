//
//  FingertipSnappingSystem.swift
//  VisionHandTracking
//
//  Created by Senior Spatial Engineer on 28/10/26.
//

import RealityKit
import ARKit
import ILSHandTracking
import ILSFoundation
import simd

/// A decoupled RealityKit System responsible for computing proximity between fingertips and
/// all entities tagged with `SnappableSurfaceComponent`.
///
/// Features:
/// - Evaluates closest point projections against Box, Plane, and Sphere surfaces.
/// - Implements dual-threshold hysteresis (snap distance vs. release distance) to eliminate jitter.
/// - Applies exponential damping to transition fingertips organically to surface contacts.
/// - Publishes real-time snap states to `FingertipSnappingService`.
public struct FingertipSnappingSystem: System {
    public static let surfaceQuery = EntityQuery(where: .has(SnappableSurfaceComponent.self))
    
    public init(scene: RealityKit.Scene) {}
    
    public func update(context: SceneUpdateContext) {
        let config = HandVisualizationConfig.shared
        guard config.isSnappingEnabled else {
            FingertipSnappingService.shared.reset()
            return
        }
        
        // 1. Gather all active snappable surfaces in the scene
        var activeSurfaces: [(entity: Entity, component: SnappableSurfaceComponent, worldTransform: Transform)] = []
        for entity in context.scene.performQuery(Self.surfaceQuery) {
            guard let comp = entity.components[SnappableSurfaceComponent.self], comp.isEnabled else { continue }
            let worldMatrix = entity.transformMatrix(relativeTo: nil)
            activeSurfaces.append((entity, comp, Transform(matrix: worldMatrix)))
        }
        
        // 2. Process Left and Right hand anchors from HandTrackingService
        let service = HandTrackingService.shared
        processHand(
            chirality: .left,
            handAnchor: service.latestLeftHand,
            surfaces: activeSurfaces,
            deltaTime: Float(context.deltaTime)
        )
        processHand(
            chirality: .right,
            handAnchor: service.latestRightHand,
            surfaces: activeSurfaces,
            deltaTime: Float(context.deltaTime)
        )
    }
    
    // MARK: - Hand Proximity Processing
    
    private func processHand(
        chirality: HandAnchor.Chirality,
        handAnchor: HandAnchor?,
        surfaces: [(entity: Entity, component: SnappableSurfaceComponent, worldTransform: Transform)],
        deltaTime: Float
    ) {
        guard let anchor = handAnchor, anchor.isTracked, let skeleton = anchor.handSkeleton else {
            // Clear snap states if hand is lost
            for tip in Hand.fingertipJoints {
                FingertipSnappingService.shared.setSnapState(
                    for: chirality,
                    joint: tip.joint,
                    state: SnappedTipState(isSnapped: false, finger: tip.finger)
                )
            }
            return
        }
        
        let anchorWorldMatrix = anchor.originFromAnchorTransform
        
        for tip in Hand.fingertipJoints {
            let jointTransform = skeleton.joint(tip.joint).anchorFromJointTransform
            let rawTipWorldMatrix = anchorWorldMatrix * jointTransform
            let rawTipWorldPos = rawTipWorldMatrix.translation
            
            // Check if this tip was previously snapped
            let previousState = FingertipSnappingService.shared.snapState(for: chirality, joint: tip.joint)
            let wasSnapped = previousState?.isSnapped ?? false
            
            var bestCandidate: (point: SIMD3<Float>, normal: SIMD3<Float>, distance: Float)?
            
            for surface in surfaces {
                let threshold = wasSnapped ? surface.component.releaseDistance : surface.component.snapDistance
                let contact = surface.component.closestSurfacePoint(
                    to: rawTipWorldPos,
                    surfaceWorldTransform: surface.worldTransform
                )
                
                if contact.distance <= threshold {
                    if let best = bestCandidate {
                        if contact.distance < best.distance {
                            bestCandidate = contact
                        }
                    } else {
                        bestCandidate = contact
                    }
                }
            }
            
            if let candidate = bestCandidate {
                // Smoothly interpolate towards surface contact point (spring-like magnetic pull)
                let currentPos = previousState?.worldPosition ?? rawTipWorldPos
                let blendSpeed: Float = wasSnapped ? 24.0 : 32.0
                let t = simd_clamp(deltaTime * blendSpeed, 0.0, 1.0)
                let smoothedPos = simd_mix(currentPos, candidate.point, SIMD3<Float>(repeating: t))
                
                let snapState = SnappedTipState(
                    isSnapped: true,
                    worldPosition: smoothedPos,
                    surfaceNormal: candidate.normal,
                    finger: tip.finger,
                    snapFactor: 1.0
                )
                FingertipSnappingService.shared.setSnapState(for: chirality, joint: tip.joint, state: snapState)
            } else {
                // Released or outside snap threshold
                let snapState = SnappedTipState(
                    isSnapped: false,
                    worldPosition: rawTipWorldPos,
                    surfaceNormal: [0, 1, 0],
                    finger: tip.finger,
                    snapFactor: 0.0
                )
                FingertipSnappingService.shared.setSnapState(for: chirality, joint: tip.joint, state: snapState)
            }
        }
    }
}
