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

public class HandVisualizationSystem: System {
    public static let query = EntityQuery(where: .has(HandVisualizationComponent.self))
        
    required public init(scene: RealityKit.Scene) {}
    
    public func update(context: SceneUpdateContext) {
        for anchorEntity in context.entities(matching: Self.query, updatingSystemWhen: .rendering){
            
            guard let visualization = anchorEntity.components[HandVisualizationComponent.self] else { continue }
            
            guard let gloveWrapper = anchorEntity.children.first(where: { !$0.components.has(WeaponComponent.self) }) else { continue }
            guard let gloveModel = findModelEntity(in: gloveWrapper) else { continue }

            let handAnchor = (visualization.chirality == .left) ?
                HandTrackingService.shared.latestLeftHand :
                HandTrackingService.shared.latestRightHand
            
            guard let trackedHand = handAnchor, trackedHand.isTracked, let skeleton = trackedHand.handSkeleton else {
                anchorEntity.isEnabled = false
                continue
            }
            
            let isTriggerPose = HandPoseDetector.detect(handSkeleton: skeleton, thumb: true, index: true, mid: true, ring: true, little: true)

            anchorEntity.isEnabled = true
            anchorEntity.transform = Transform(matrix: trackedHand.originFromAnchorTransform)

            let joints = skeleton.allJoints
            for (index, joint) in joints.enumerated() {
                if index < gloveModel.jointTransforms.count {
                    let jointTransform = skeleton.joint(joint.name).parentFromJointTransform
                    gloveModel.jointTransforms[index].rotation = simd_quatf(jointTransform)
                }
            }
        }
    }
    
    private func findModelEntity(in entity: Entity) -> ModelEntity? {
        if let model = entity as? ModelEntity {
            return model
        }
        for child in entity.children {
            if let found = findModelEntity(in: child) {
                return found
            }
        }
        return nil
    }
}
