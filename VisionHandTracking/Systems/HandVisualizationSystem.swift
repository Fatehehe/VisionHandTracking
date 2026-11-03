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
    
    required public init(scene: RealityKit.Scene) {
        tipDefaultMaterial = HandSpawner.makeTipMaterial(isSnapped: false)
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
                    updateJointSpheres(root: spheresRoot, skeleton: skeleton)
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
        skeleton: HandSkeleton
    ) {
        var jointLocalPositions: [HandSkeleton.JointName: SIMD3<Float>] = [:]
        
        for child in root.children {
            guard let jointComp = child.components[HandJointEntityComponent.self] else { continue }
            let jointName = jointComp.jointName
            
            let jointTransform = skeleton.joint(jointName).anchorFromJointTransform
            let localPos = jointTransform.translation
            
            if jointComp.isTip, let model = child as? ModelEntity, let defaultMat = tipDefaultMaterial {
                model.model?.materials = [defaultMat]
            }
            
            child.position = localPos
            child.orientation = simd_quatf(jointTransform)
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
