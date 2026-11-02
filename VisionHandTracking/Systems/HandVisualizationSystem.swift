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
    
    private var tipDefaultMaterial: RealityKit.Material?
    private var tipSnappedMaterial: RealityKit.Material?
    
    required public init(scene: RealityKit.Scene) {
        tipDefaultMaterial = HandSpawner.makeTipMaterial(isSnapped: false)
        tipSnappedMaterial = HandSpawner.makeTipMaterial(isSnapped: true)
    }
    
    public func update(context: SceneUpdateContext) {
        for anchorEntity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard let visualization = anchorEntity.components[HandVisualizationComponent.self] else { continue }
            
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
            anchorEntity.transform = Transform(matrix: trackedHand.originFromAnchorTransform)
            
            switch visualization.mode {
            case .jointSpheres:
                if let spheresRoot = visualization.jointSpheresRoot {
                    updateJointSpheres(
                        root: spheresRoot,
                        anchorEntity: anchorEntity,
                        chirality: visualization.chirality,
                        skeleton: skeleton
                    )
                }
                
            case .gloves:
                if let gloveModel = visualization.skinnedModel {
                    updateGloveJoints(for: gloveModel, with: skeleton)
                }
            }
        }
    }
    
    private func updateJointSpheres(
        root: Entity,
        anchorEntity: Entity,
        chirality: HandAnchor.Chirality,
        skeleton: HandSkeleton
    ) {
        var jointLocalPositions: [HandSkeleton.JointName: SIMD3<Float>] = [:]
        
        for child in root.children {
            guard let jointComp = child.components[HandJointEntityComponent.self] else { continue }
            let jointName = jointComp.jointName
            
            let rawLocalPos = skeleton.joint(jointName).anchorFromJointTransform.translation
            
            if jointComp.isTip,
               let finger = jointComp.finger,
               let worldSnapPos = SnapService.shared.snappedWorldPosition(for: chirality, finger: finger) {
                
                // Convert world-space snap target position to hand anchor coordinate space
                let localSnapPos = anchorEntity.convert(position: worldSnapPos, from: nil)
                child.position = localSnapPos
                jointLocalPositions[jointName] = localSnapPos
                
                if let model = child as? ModelEntity, let snappedMat = tipSnappedMaterial {
                    model.model?.materials = [snappedMat]
                }
            } else {
                child.position = rawLocalPos
                jointLocalPositions[jointName] = rawLocalPos
                
                if jointComp.isTip, let model = child as? ModelEntity, let defaultMat = tipDefaultMaterial {
                    model.model?.materials = [defaultMat]
                }
            }
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
