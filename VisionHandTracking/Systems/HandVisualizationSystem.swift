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
    private static let switchQuery = EntityQuery(where: .has(SwitchComponent.self))
    
    private var tipDefaultMaterial: RealityKit.Material?
    private var tipSnappedMaterial: RealityKit.Material?
    
    required public init(scene: RealityKit.Scene) {
        tipDefaultMaterial = HandSpawner.makeTipMaterial(isSnapped: false)
        tipSnappedMaterial = HandSpawner.makeTipMaterial(isSnapped: true)
    }
    
    public func update(context: SceneUpdateContext) {
        let pullEntities = Array(context.scene.performQuery(Self.pullQuery))
        let switchEntities = Array(context.scene.performQuery(Self.switchQuery))
        
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
            
            // 1. Check if holding a Pull Entity
            let grabbedPullEntity = pullEntities.first { entity in
                guard let pull = entity.components[PullComponent.self] else { return false }
                return pull.isGrabbed && (pull.grabbingChirality == visualization.chirality || pull.grabbingChirality == nil)
            }
            
            // 2. Check if holding a Switch Entity
            let grabbedSwitchEntity = switchEntities.first { entity in
                guard let switchComp = entity.components[SwitchComponent.self] else { return false }
                return switchComp.isGrabbed && (switchComp.grabbingChirality == visualization.chirality || switchComp.grabbingChirality == nil)
            }
            
            // 3. Resolve active target and fingers
            let targetEntity = grabbedPullEntity ?? grabbedSwitchEntity
            var activeFingers: Set<Finger> = [.thumb, .index]
            
            if let pullTarget = grabbedPullEntity, let pull = pullTarget.components[PullComponent.self] {
                activeFingers = pull.interactingFingers.isEmpty ? [.thumb, .index] : pull.interactingFingers
            } else if let switchTarget = grabbedSwitchEntity, let switchComp = switchTarget.components[SwitchComponent.self] {
                activeFingers = switchComp.interactingFingers.isEmpty ? [.thumb, .index] : switchComp.interactingFingers
            }
            
            // 4. Apply Snapping Logic
            if let target = targetEntity {
                if !visualization.isSnapped {
                    visualization.isSnapped = true
                    visualization.snappedTargetEntity = target
                    visualization.snappedFingers = activeFingers
                    
                    if let gloveModel = visualization.skinnedModel {
                        updateGloveJoints(for: gloveModel, with: skeleton)
                        visualization.preservedGloveTransforms = gloveModel.jointTransforms
                    }
                    
                    var jointPositions: [HandSkeleton.JointName: SIMD3<Float>] = [:]
                    for joint in skeleton.allJoints {
                        jointPositions[joint.name] = skeleton.joint(joint.name).anchorFromJointTransform.translation
                    }
                    visualization.preservedJointPositions = jointPositions
                    
                    let targetWorld = target.transformMatrix(relativeTo: nil)
                    let handWorld = trackedHand.originFromAnchorTransform
                    visualization.anchorOffsetFromTarget = simd_mul(simd_inverse(targetWorld), handWorld)
                }
                
                if let offset = visualization.anchorOffsetFromTarget {
                    let currentTargetWorld = target.transformMatrix(relativeTo: nil)
                    let snappedWorld = simd_mul(currentTargetWorld, offset)
                    anchorEntity.transform = Transform(matrix: snappedWorld)
                } else {
                    anchorEntity.transform = Transform(matrix: trackedHand.originFromAnchorTransform)
                }
                
                switch visualization.mode {
                case .jointSpheres:
                    if let spheresRoot = visualization.jointSpheresRoot, let savedPos = visualization.preservedJointPositions {
                        updateSelectiveJointSpheres(
                            root: spheresRoot,
                            skeleton: skeleton,
                            preservedPositions: savedPos,
                            snappedFingers: visualization.snappedFingers
                        )
                    }
                case .gloves:
                    if let gloveModel = visualization.skinnedModel, let savedTransforms = visualization.preservedGloveTransforms {
                        updateSelectiveGloveJoints(
                            for: gloveModel,
                            with: skeleton,
                            preservedTransforms: savedTransforms,
                            snappedFingers: visualization.snappedFingers
                        )
                    }
                }
            } else {
                // 5. Reset Unsnapped State
                if visualization.isSnapped {
                    visualization.isSnapped = false
                    visualization.preservedGloveTransforms = nil
                    visualization.preservedJointPositions = nil
                    visualization.snappedTargetEntity = nil
                    visualization.anchorOffsetFromTarget = nil
                    visualization.snappedFingers = []
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
    
    private func updateSelectiveJointSpheres(
        root: Entity,
        skeleton: HandSkeleton,
        preservedPositions: [HandSkeleton.JointName: SIMD3<Float>],
        snappedFingers: Set<Finger>
    ) {
        var currentPositions: [HandSkeleton.JointName: SIMD3<Float>] = [:]
        
        for child in root.children {
            guard let jointComp = child.components[HandJointEntityComponent.self] else { continue }
            let jointName = jointComp.jointName
            let isSnappedJoint = jointComp.finger.map { snappedFingers.contains($0) || $0 == .forearm } ?? false
            
            let localPos: SIMD3<Float>
            if isSnappedJoint, let saved = preservedPositions[jointName] {
                localPos = saved
                if jointComp.isTip, let model = child as? ModelEntity, let snappedMat = tipSnappedMaterial {
                    model.model?.materials = [snappedMat]
                }
            } else {
                localPos = skeleton.joint(jointName).anchorFromJointTransform.translation
                if jointComp.isTip, let model = child as? ModelEntity, let defaultMat = tipDefaultMaterial {
                    model.model?.materials = [defaultMat]
                }
            }
            
            child.position = localPos
            currentPositions[jointName] = localPos
        }
        
        updateBones(root: root, jointPositions: currentPositions)
    }
    
    private func updateJointSpheres(
        root: Entity,
        skeleton: HandSkeleton
    ) {
        var currentPositions: [HandSkeleton.JointName: SIMD3<Float>] = [:]
        
        for child in root.children {
            guard let jointComp = child.components[HandJointEntityComponent.self] else { continue }
            let jointName = jointComp.jointName
            
            let localPos = skeleton.joint(jointName).anchorFromJointTransform.translation
            
            if jointComp.isTip, let model = child as? ModelEntity, let defaultMat = tipDefaultMaterial {
                model.model?.materials = [defaultMat]
            }
            
            child.position = localPos
            currentPositions[jointName] = localPos
        }
        
        updateBones(root: root, jointPositions: currentPositions)
    }
    
    private func updateBones(
        root: Entity,
        jointPositions: [HandSkeleton.JointName: SIMD3<Float>]
    ) {
        for child in root.children {
            guard let boneComp = child.components[BoneConnectorComponent.self] else { continue }
            guard let posA = jointPositions[boneComp.fromJoint],
                  let posB = jointPositions[boneComp.toJoint] else { continue }
            
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
    
    private func updateSelectiveGloveJoints(
        for model: ModelEntity,
        with skeleton: HandSkeleton,
        preservedTransforms: [Transform],
        snappedFingers: Set<Finger>
    ) {
        let joints = skeleton.allJoints
        var transforms = model.jointTransforms
        
        for (index, joint) in joints.enumerated() {
            guard index < transforms.count else { break }
            let finger = Hand.finger(for: joint.name)
            let isSnappedJoint = finger.map { snappedFingers.contains($0) || $0 == .forearm } ?? false
            
            if isSnappedJoint && index < preservedTransforms.count {
                transforms[index].rotation = preservedTransforms[index].rotation
            } else {
                let jointTransform = skeleton.joint(joint.name).parentFromJointTransform
                transforms[index].rotation = simd_quatf(jointTransform)
            }
        }
        model.jointTransforms = transforms
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
