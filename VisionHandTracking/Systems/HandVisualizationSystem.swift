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
        for anchorEntity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var visualization = anchorEntity.components[HandVisualizationComponent.self] else { continue }
            
            // Resolve the skinned model (cached on component or discovered in hierarchy)
            let gloveModel: ModelEntity?
            if let cached = visualization.skinnedModel {
                gloveModel = cached
            } else if let found = findSkinnedModel(in: anchorEntity) {
                visualization.skinnedModel = found
                anchorEntity.components.set(visualization)
                gloveModel = found
            } else {
                continue
            }
            
            guard let model = gloveModel else { continue }

            let handAnchor = (visualization.chirality == .left) ?
                HandTrackingService.shared.latestLeftHand :
                HandTrackingService.shared.latestRightHand
            
            guard let trackedHand = handAnchor, trackedHand.isTracked, let skeleton = trackedHand.handSkeleton else {
                anchorEntity.isEnabled = false
                continue
            }
            
            anchorEntity.isEnabled = true
            anchorEntity.transform = Transform(matrix: trackedHand.originFromAnchorTransform)

            // Update skeletal joint rotations from ARKit HandSkeleton
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
    
    /// Finds the ModelEntity that contains the skeletal rig (jointNames array is non-empty)
    private func findSkinnedModel(in root: Entity) -> ModelEntity? {
        var queue: [Entity] = [root]
        while !queue.isEmpty {
            let current = queue.removeFirst()
            if let model = current as? ModelEntity, !model.jointNames.isEmpty {
                return model
            }
            queue.append(contentsOf: current.children)
        }
        return nil
    }
}
