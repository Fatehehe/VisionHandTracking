//
//  HandVisualizationSystem.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 26/10/26.
//

import RealityKit
import ARKit
import SwiftUI
import ILSHandTracking
import simd
internal import ILSFoundation

public class HandVisualizationSystem: System {
    public static let query = EntityQuery(where: .has(HandVisualizationComponent.self))
    private static let pullQuery = EntityQuery(where: .has(PullComponent.self))
    
    private var tipDefaultMaterial: RealityKit.Material?
    private var tipSnappedMaterial: RealityKit.Material?
    
    required public init(scene: RealityKit.Scene) {
        tipDefaultMaterial = HandSpawner.makeTipMaterial(isSnapped: false)
        tipSnappedMaterial = HandSpawner.makeTipMaterial(isSnapped: true)
    }
    
    public func update(context: SceneUpdateContext) {
        let pullEntities = Array(context.scene.performQuery(Self.pullQuery))
        
        for anchorEntity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var visualization = anchorEntity.components[HandVisualizationComponent.self] else { continue }
            
            guard visualization.isVisible else {
                anchorEntity.isEnabled = false
                continue
            }
            
            let handAnchor = (visualization.chirality == .left) ?
                HandTrackingService.shared.latestLeftHand :
                HandTrackingService.shared.latestRightHand
            
            guard let trackedHand = handAnchor, trackedHand.isTracked, let skeleton = trackedHand.handSkeleton else {
                anchorEntity.isEnabled = false
                continue
            }
            
            anchorEntity.isEnabled = true
            
            // Check if any PullComponent is currently grabbed by this hand
            let grabbedPullEntity = pullEntities.first { entity in
                guard let pull = entity.components[PullComponent.self] else { return false }
                return pull.isGrabbed && (pull.grabbingChirality == visualization.chirality || pull.grabbingChirality == nil)
            }
            
            if let targetEntity = grabbedPullEntity {
                // MARK: - Hand/Glove Snapping Active (OctaXR style)
                if !visualization.isSnapped {
                    visualization.isSnapped = true
                    visualization.snappedTargetEntity = targetEntity
                    
                    // 1. Preserve glove joint transforms (freeze finger pose in pinch)
                    if let gloveModel = visualization.skinnedModel {
                        visualization.preservedGloveTransforms = gloveModel.jointTransforms
                    }
                    
                    // 2. Preserve joint positions (for joint spheres mode)
                    var jointPositions: [HandSkeleton.JointName: SIMD3<Float>] = [:]
                    for joint in skeleton.allJoints {
                        jointPositions[joint.name] = skeleton.joint(joint.name).anchorFromJointTransform.translation
                    }
                    visualization.preservedJointPositions = jointPositions
                    
                    // 3. Capture offset between target entity and tracked hand wrist in world coordinates
                    let targetWorld = targetEntity.transformMatrix(relativeTo: nil)
                    let handWorld = trackedHand.originFromAnchorTransform
                    visualization.anchorOffsetFromTarget = simd_mul(simd_inverse(targetWorld), handWorld)
                }
                
                // Move the visual hand along with the pulled component
                if let offset = visualization.anchorOffsetFromTarget {
                    let currentTargetWorld = targetEntity.transformMatrix(relativeTo: nil)
                    let snappedWorld = simd_mul(currentTargetWorld, offset)
                    anchorEntity.transform = Transform(matrix: snappedWorld)
                } else {
                    anchorEntity.transform = Transform(matrix: trackedHand.originFromAnchorTransform)
                }
                
                // Maintain the preserved hand pose (do NOT overwrite finger joints with live tracking)
                switch visualization.mode {
                case .jointSpheres:
                    if let spheresRoot = visualization.jointSpheresRoot, let savedPos = visualization.preservedJointPositions {
                        applyPreservedJointPositions(root: spheresRoot, positions: savedPos)
                    }
                case .gloves:
                    if let gloveModel = visualization.skinnedModel, let savedTransforms = visualization.preservedGloveTransforms {
                        gloveModel.jointTransforms = savedTransforms
                    }
                }
            } else {
                // MARK: - Normal Live Hand Tracking
                if visualization.isSnapped {
                    // Released! Clear snapping state and return to normal
                    visualization.isSnapped = false
                    visualization.preservedGloveTransforms = nil
                    visualization.preservedJointPositions = nil
                    visualization.snappedTargetEntity = nil
                    visualization.anchorOffsetFromTarget = nil
                }
                
                anchorEntity.transform = Transform(matrix: trackedHand.originFromAnchorTransform)
                
                switch visualization.mode {
                case .jointSpheres:
                    if let spheresRoot = visualization.jointSpheresRoot {
                        updateJointSpheres(root: spheresRoot, skeleton: skeleton)
                    }
                case .gloves:
                    if let gloveModel = visualization.skinnedModel {
                        updateGloveJoints(for: gloveModel, with: skeleton)
                    }
                }
            }
            
            anchorEntity.components.set(visualization)
        }
    }
    
    private func applyPreservedJointPositions(
        root: Entity,
        positions: [HandSkeleton.JointName: SIMD3<Float>]
    ) {
        for child in root.children {
            guard let jointComp = child.components[HandJointEntityComponent.self] else { continue }
            if let localPos = positions[jointComp.jointName] {
                child.position = localPos
            }
            if jointComp.isTip, let model = child as? ModelEntity, let snappedMat = tipSnappedMaterial {
                model.model?.materials = [snappedMat]
            }
        }
        
        for child in root.children {
            guard let boneComp = child.components[BoneConnectorComponent.self] else { continue }
            guard let posA = positions[boneComp.fromJoint],
                  let posB = positions[boneComp.toJoint] else { continue }
            
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
    
    private func updateJointSpheres(
        root: Entity,
        skeleton: HandSkeleton
    ) {
        var jointLocalPositions: [HandSkeleton.JointName: SIMD3<Float>] = [:]
        
        for child in root.children {
            guard let jointComp = child.components[HandJointEntityComponent.self] else { continue }
            let jointName = jointComp.jointName
            
            let localPos = skeleton.joint(jointName).anchorFromJointTransform.translation
            
            if jointComp.isTip, let model = child as? ModelEntity, let defaultMat = tipDefaultMaterial {
                model.model?.materials = [defaultMat]
            }
            
            child.position = localPos
            jointLocalPositions[jointName] = localPos
        }
        
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
    
    private func updateGloveJoints(
        for model: ModelEntity,
        with skeleton: HandSkeleton
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
