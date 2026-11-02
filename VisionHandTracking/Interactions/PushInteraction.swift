//
//  PushInteraction.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 02/11/26.
//

import Foundation
import RealityKit
import simd

/// A decoupled interaction where a component or sub-entity must be pushed inward along a specific axis.
/// For example: pressing a physical push-button or plunging a mechanical pin.
public final class PushInteraction: SpatialInteraction {
    public let id: UUID = UUID()
    public var name: String
    public var status: InteractionStatus = .idle
    
    /// The normalized local vector along which pushing occurs (e.g., `[0, 0, -1]` for pushing inward/away).
    public var direction: SIMD3<Float>
    
    /// Target travel distance in meters required to activate (e.g., 0.02 for 2 cm).
    public var targetDistance: Float
    
    /// Whether the pressed element springs back to its resting state upon release.
    public var springBackOnRelease: Bool
    
    /// Whether the interaction visually moves `pushEntity`.
    public var affectsTransform: Bool
    
    /// Optional specific sub-entity (e.g. button plunger). If nil, slides the owning target entity.
    public weak var pushEntity: Entity?
    
    // Internal state caching
    private var initialEntityPosition: SIMD3<Float> = .zero
    private var initialHandPosition: SIMD3<Float> = .zero
    private var hasRecordedInitialEntityPos = false
    
    public init(
        name: String = "Push",
        direction: SIMD3<Float> = [0, 0, -1],
        targetDistance: Float = 0.02,
        springBackOnRelease: Bool = true,
        affectsTransform: Bool = true,
        pushEntity: Entity? = nil
    ) {
        self.name = name
        self.direction = simd_normalize(direction)
        self.targetDistance = targetDistance
        self.springBackOnRelease = springBackOnRelease
        self.affectsTransform = affectsTransform
        self.pushEntity = pushEntity
    }
    
    public func onStart(targetEntity: Entity, handAnchorTransform: Transform) {
        let entity = pushEntity ?? targetEntity
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
        
        let entity = pushEntity ?? targetEntity
        
        // Convert local push direction to world coordinates
        let worldDirection = entity.convert(direction: direction, to: nil)
        let normalizedWorldDir = simd_normalize(worldDirection)
        
        // Calculate hand translation delta along the push axis
        let handDelta = currentHandTransform.translation - initialHandPosition
        let pushedDistance = simd_dot(handDelta, normalizedWorldDir)
        
        // Clamp distance between 0 and targetDistance
        let clampedDistance = max(0.0, min(pushedDistance, targetDistance))
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
        let entity = pushEntity ?? targetEntity
        if springBackOnRelease || !status.isCompleted {
            if hasRecordedInitialEntityPos {
                entity.position = initialEntityPosition
            }
            status = .idle
        }
    }
}

