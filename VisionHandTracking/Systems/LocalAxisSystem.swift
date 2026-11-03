//
//  LocalAxisSystem.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 02/11/26.
//

import RealityKit

/// RealityKit System that dynamically toggles and manages local coordinate axis gizmos across entities.
public struct LocalAxisSystem: System {
    public static let query = EntityQuery(where: .has(LocalAxisComponent.self))
    
    public init(scene: RealityKit.Scene) {}
    
    public func update(context: SceneUpdateContext) {
        for entity in context.scene.performQuery(Self.query) {
            guard var axisComp = entity.components[LocalAxisComponent.self] else { continue }
            if axisComp.gizmoEntity == nil {
                let gizmo = CoordinateAxesGizmo.makeGizmo(
                    length: axisComp.axisLength,
                    thickness: axisComp.axisThickness
                )
                entity.addChild(gizmo)
                axisComp.gizmoEntity = gizmo
                entity.components.set(axisComp)
            }

            let shouldBeVisible = axisComp.isVisible
            
            if axisComp.gizmoEntity?.isEnabled != shouldBeVisible {
                axisComp.gizmoEntity?.isEnabled = shouldBeVisible
            }
        }
    }
}
