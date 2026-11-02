//
//  SpatialInteraction.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 02/11/26.
//

import Foundation
import RealityKit
import simd

/// Status lifecycle for a spatial interaction.
public enum InteractionStatus: Equatable, Sendable {
    case idle
    case inProgress(progress: Float) // 0.0 ... 1.0
    case completed
    case cancelled
    
    public var progress: Float {
        switch self {
        case .idle:
            return 0.0
        case .inProgress(let p):
            return p
        case .completed:
            return 1.0
        case .cancelled:
            return 0.0
        }
    }
    
    public var isCompleted: Bool {
        if case .completed = self { return true }
        return false
    }
}

/// A decoupled protocol representing a discrete spatial physical interaction (e.g. Pull, Push, Rotate, Switch).
/// Can be attached to any entity and stacked sequentially inside an `InteractionFlowComponent`.
public protocol SpatialInteraction: AnyObject {
    /// Unique identifier for this interaction instance.
    var id: UUID { get }
    
    /// Descriptive name (e.g. "Pull Safety Pin", "Flip Breaker").
    var name: String { get set }
    
    /// Current lifecycle status.
    var status: InteractionStatus { get set }
    
    /// Current normalized progress [0.0 ... 1.0].
    var progress: Float { get }
    
    /// Whether the interaction has been fulfilled.
    var isCompleted: Bool { get }
    
    /// Called when this interaction step becomes the active step in the flow.
    func onStart(targetEntity: Entity, handAnchorTransform: Transform)
    
    /// Called every frame while this interaction is active and hand remains snapped.
    ///
    /// - Parameters:
    ///   - targetEntity: The entity owning the interaction flow.
    ///   - currentHandTransform: Current world transform of the snapped hand anchor.
    ///   - initialHandTransform: Reference world transform of the hand when snap engaged / step started.
    ///   - deltaTime: Elapsed frame time in seconds.
    /// - Returns: Updated status.
    func update(
        targetEntity: Entity,
        currentHandTransform: Transform,
        initialHandTransform: Transform,
        deltaTime: Float
    ) -> InteractionStatus
    
    /// Called to reset the interaction back to its starting state (e.g., if hand releases early).
    func reset(targetEntity: Entity)
}

extension SpatialInteraction {
    public var isCompleted: Bool {
        return status.isCompleted
    }
    
    public var progress: Float {
        return status.progress
    }
}

