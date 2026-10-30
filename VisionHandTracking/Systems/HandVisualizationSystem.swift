//
//  HandVisualizationSystem.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 26/10/26.
//  Refactored by Senior Spatial Engineer on 28/10/26.
//

import RealityKit
import ARKit
import SwiftUI
import ILSHandTracking
import ILSFoundation
import simd

/// The master RealityKit System driving hand representations in the immersive space.
///
/// Responsibilities:
/// 1. Synchronizes hand anchor root transforms with ARKit 6DOF tracking.
/// 2. Manages visual mode switching between `.jointSpheres` and `.glove`.
/// 3. Updates all 27 joint spheres and dynamically deforms bone connector cylinders.
/// 4. Enforces the fingertip snapping constraint:
///    - When snapped: only fingertip positions lock to surface contact points in local space.
///    - Other joints (metacarpals, knuckles, intermediate bones, wrist) continue moving freely with 1:1 ARKit tracking!
///    - Intermediate-to-tip bones dynamically stretch and rotate to match physical contact.
public class HandVisualizationSystem: System {
    public static let query = EntityQuery(where: .has(HandVisualizationComponent.self))
    
    // Cached materials for tip snap feedback to avoid frame-time allocations
    private var tipDefaultMaterial: RealityKit.Material?
    private var tipSnappedMaterial: RealityKit.Material?
    
    required public init(scene: RealityKit.Scene) {
        tipDefaultMaterial = JointSpheresSpawner.makeTipMaterial(isSnapped: false)
        tipSnappedMaterial = JointSpheresSpawner.makeTipMaterial(isSnapped: true)
    }
    
    public func update(context: SceneUpdateContext) {
        let config = HandVisualizationConfig.shared
        
        for anchorEntity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let visualization = anchorEntity.components[HandVisualizationComponent.self] else { continue }
            
            // 1. Visibility Check: If user disabled hand representation, hide and skip
            guard config.isVisible else {
                anchorEntity.isEnabled = false
                continue
            }
            
            // 2. Resolve ARKit HandAnchor for this hand
            let handAnchor = (visualization.chirality == .left) ?
                HandTrackingService.shared.latestLeftHand :
                HandTrackingService.shared.latestRightHand
            
            guard let trackedHand = handAnchor, trackedHand.isTracked, let skeleton = trackedHand.handSkeleton else {
                anchorEntity.isEnabled = false
                continue
            }
            
            // 3. Anchor is tracked: enable and update root transform
            anchorEntity.isEnabled = true
            anchorEntity.transform = Transform(matrix: trackedHand.originFromAnchorTransform)
            
            // 4. Synchronize active representation mode
            let currentMode = config.mode
            if let spheresRoot = visualization.jointSpheresRoot {
                spheresRoot.isEnabled = (currentMode == .jointSpheres)
            }
            if let gloveRoot = visualization.gloveRoot {
                gloveRoot.isEnabled = (currentMode == .glove)
            }
            
            // 5. Retrieve fingertip snapping states for this hand
            let snappedTips = FingertipSnappingService.shared.allSnappedTips(for: visualization.chirality)
            
            // 6. Update the active visualizer
            switch currentMode {
            case .jointSpheres:
                if let spheresRoot = visualization.jointSpheresRoot {
                    updateJointSpheres(
                        root: spheresRoot,
                        skeleton: skeleton,
                        anchorMatrix: trackedHand.originFromAnchorTransform,
                        snappedTips: snappedTips
                    )
                }
                
            case .glove:
                if let gloveModel = visualization.skinnedModel {
                    updateGloveJoints(
                        for: gloveModel,
                        with: skeleton,
                        anchorMatrix: trackedHand.originFromAnchorTransform,
                        snappedTips: snappedTips
                    )
                }
            }
        }
    }
    
    // MARK: - Joint Spheres Representation Update
    
    /// Updates joint sphere positions and bone connector cylinders.
    /// Locks snapped fingertips to the surface while knuckles and intermediate joints move freely.
    private func updateJointSpheres(
        root: Entity,
        skeleton: HandSkeleton,
        anchorMatrix: simd_float4x4,
        snappedTips: [HandSkeleton.JointName: SnappedTipState]
    ) {
        let worldFromAnchorInverse = simd_inverse(anchorMatrix)
        
        // Dictionary caching local positions of all joints for bone connection math
        var jointLocalPositions: [HandSkeleton.JointName: SIMD3<Float>] = [:]
        
        // 1. Update Joint Spheres
        for child in root.children {
            guard let jointComp = child.components[HandJointEntityComponent.self] else { continue }
            let jointName = jointComp.jointName
            
            let localPos: SIMD3<Float>
            
            if jointComp.isTip,
               let snapState = snappedTips[jointName],
               snapState.isSnapped {
                // FINGERTIP SNAPPING:
                // Transform the snapped world contact point into hand-anchor local space.
                // As the user raises or moves their wrist/knuckles, this local point compensates
                // so the visual sphere remains perfectly pinned on the surface!
                let local4 = worldFromAnchorInverse * simd_float4(snapState.worldPosition, 1.0)
                localPos = SIMD3<Float>(local4.x, local4.y, local4.z)
                
                // Visual feedback: apply glowing snapped material
                if let model = child as? ModelEntity, let snappedMat = tipSnappedMaterial {
                    model.model?.materials = [snappedMat]
                }
            } else {
                // Free tracking: follow ARKit skeleton transform 1:1
                localPos = skeleton.joint(jointName).anchorFromJointTransform.translation
                
                if jointComp.isTip, let model = child as? ModelEntity, let defaultMat = tipDefaultMaterial {
                    model.model?.materials = [defaultMat]
                }
            }
            
            child.position = localPos
            jointLocalPositions[jointName] = localPos
        }
        
        // 2. Update Dynamic Bone Connector Cylinders
        for child in root.children {
            guard let boneComp = child.components[BoneConnectorComponent.self] else { continue }
            guard let posA = jointLocalPositions[boneComp.fromJoint],
                  let posB = jointLocalPositions[boneComp.toJoint] else { continue }
            
            let delta = posB - posA
            let length = simd_length(delta)
            
            guard length > 0.001 else {
                child.scale = .zero
                continue
            }
            
            let direction = delta / length
            let midpoint = (posA + posB) * 0.5
            let rotation = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: direction)
            
            child.transform = Transform(
                scale: SIMD3<Float>(1.0, length, 1.0),
                rotation: rotation,
                translation: midpoint
            )
        }
    }
    
    // MARK: - Skinned Glove Model Update
    
    /// Updates joint rotations of the skinned glove mesh from the ARKit HandSkeleton.
    private func updateGloveJoints(
        for model: ModelEntity,
        with skeleton: HandSkeleton,
        anchorMatrix: simd_float4x4,
        snappedTips: [HandSkeleton.JointName: SnappedTipState]
    ) {
        let joints = skeleton.allJoints
        var transforms = model.jointTransforms
        
        for (index, joint) in joints.enumerated() {
            guard index < transforms.count else { break }
            let jointTransform = skeleton.joint(joint.name).parentFromJointTransform
            transforms[index].rotation = simd_quatf(jointTransform)
        }
        
        model.jointTransforms = transforms
    }
}
