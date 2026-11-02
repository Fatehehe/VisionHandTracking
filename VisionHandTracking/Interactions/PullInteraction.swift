//
//  PullInteraction.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 02/11/26.
//

import Foundation
import RealityKit
import simd

/// A decoupled interaction where a component or sub-entity must be pulled along a specific axis.
/// For example: pulling a safety pin, opening a drawer, or pulling a switch knob outward.
public final class PullInteraction: SpatialInteraction {
    public let id: UUID = UUID()
    public var name: String
    public var status: InteractionStatus = .idle
    
    /// The normalized local vector along which pulling occurs (e.g., `[0, 0, 1]` for pulling forward/outward).
    public var direction: SIMD3<Float>
    
    /// Target distance in meters required to complete the pull (e.g., 0.035 for 3.5 cm).
    public var targetDistance: Float
    
    /// Whether the pulled element snaps back to its origin if released before completion.
    public var springBackOnRelease: Bool
    
    /// Whether the interaction directly manipulates the visual position of `pullEntity`.
    public var affectsTransform: Bool
    
    /// Optional specific sub-entity (e.g. latch, knob) to slide. If nil, slides the owning target entity.
    public weak var pullEntity: Entity?
    
    // Internal state caching
    private var initialEntityPosition: SIMD3<Float> = .zero
    private var initialHandPosition: SIMD3<Float> = .zero
    private var hasRecordedInitialEntityPos = false
    
    public init(
        name: String = "Pull",
        direction: SIMD3<Float> = [0, 0, 1],
        targetDistance: Float = 0.035,
        springBackOnRelease: Bool = true,
        affectsTransform: Bool = true,
        pullEntity: Entity? = nil
    ) {
        self.name = name
        self.direction = simd_normalize(direction)
        self.targetDistance = targetDistance
        self.springBackOnRelease = springBackOnRelease
        self.affectsTransform = affectsTransform
        self.pullEntity = pullEntity
    }
    
    public func onStart(targetEntity: Entity, handAnchorTransform: Transform) {
        let entity = pullEntity ?? targetEntity
        if !hasRecordedInitialEntityPos {
            initialEntityPosition = entity.position
            hasRecordedInitialEntityPos = true
        }
        initialHandPosition = handAnchorTransform.translation
        if !status.isCompleted {
            status = .inProgress(progress: 0.0)
        }
    }
    
    public func update(
        targetEntity: Entity,
        currentHandTransform: Transform,
        initialHandTransform: Transform,
        deltaTime: Float
    ) -> InteractionStatus {
        guard !status.isCompleted else { return .completed }
        
        let entity = pullEntity ?? targetEntity
        
        // Convert local pull direction to world coordinates
        let worldDirection = entity.convert(direction: direction, to: nil)
        let normalizedWorldDir = simd_normalize(worldDirection)
        
        // Calculate hand translation delta in world coordinates
        let handDelta = currentHandTransform.translation - initialHandPosition
        let pulledDistance = simd_dot(handDelta, normalizedWorldDir)
        
        // Clamp distance between 0 and targetDistance
        let clampedDistance = max(0.0, min(pulledDistance, targetDistance))
        let progress = targetDistance > 0.0001 ? (clampedDistance / targetDistance) : 1.0
        
        if affectsTransform {
            entity.position = initialEntityPosition + (direction * clampedDistance)
        }
        
        if progress >= 1.0 {
            status = .completed
            return .completed
        } else {
            status = .inProgress(progress: progress)
            return status
        }
    }
    
    public func reset(targetEntity: Entity) {
        let entity = pullEntity ?? targetEntity
        if springBackOnRelease || !status.isCompleted {
            if hasRecordedInitialEntityPos {
                entity.position = initialEntityPosition
            }
            status = .idle
        }
    }
}

