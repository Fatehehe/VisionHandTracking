//
//  LocalAxisComponent.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 02/11/26.
//

import RealityKit

public enum LocalAxisCategory: String, Sendable, CaseIterable {
    case all = "All"
    case elements = "Scene Elements"
    case fingertips = "Fingertips"
    case joints = "All Joints"
    case hands = "Hand Anchors"
}

public struct LocalAxisComponent: Component {
    public var axisLength: Float
    public var axisThickness: Float
    public var category: LocalAxisCategory
    public var isVisible: Bool
    public var gizmoEntity: Entity?
    
    public init(
        axisLength: Float = 0.035,
        axisThickness: Float = 0.0012,
        category: LocalAxisCategory = .elements,
        isVisible: Bool = false,
        gizmoEntity: Entity? = nil
    ) {
        self.axisLength = axisLength
        self.axisThickness = axisThickness
        self.category = category
        self.isVisible = isVisible
        self.gizmoEntity = gizmoEntity
    }
}

extension Entity {
    public func enableLocalAxis(
        length: Float = 0.035,
        thickness: Float = 0.0012,
        category: LocalAxisCategory = .elements,
        startVisible: Bool = false
    ) -> Entity {
        let gizmo = CoordinateAxesGizmo.makeGizmo(length: length, thickness: thickness)
        gizmo.isEnabled = startVisible
        addChild(gizmo)
        
        components.set(LocalAxisComponent(
            axisLength: length,
            axisThickness: thickness,
            category: category,
            isVisible: startVisible,
            gizmoEntity: gizmo
        ))
        
        return self
    }
}
