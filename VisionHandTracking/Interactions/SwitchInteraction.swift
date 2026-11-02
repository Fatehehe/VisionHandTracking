//
//  SwitchInteraction.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 02/11/26.
//

import Foundation
import RealityKit
import simd

/// A decoupled interaction for flipping or toggling a physical lever, knife switch, or toggle.
/// Features a mechanical threshold (e.g. 60% travel) where crossing it snaps the switch into the ON state.
public final class SwitchInteraction: SpatialInteraction {
    public let id: UUID = UUID()
    public var name: String
    public var status: InteractionStatus = .idle
    
    /// Pivot axis around which the switch lever rotates (e.g. `[1, 0, 0]` for flipping up/down).
    public var pivotAxis: SIMD3<Float>
    
    /// Lever angle in radians when in the OFF / starting state.
    public var offAngleRadians: Float
    
    /// Lever angle in radians when in the ON / target state.
    public var onAngleRadians: Float
    
    /// Local direction vector along which hand moves to flip the switch (e.g. `[0, 1, 0]` for upward flick).
    public var flipDirection: SIMD3<Float>
    
    /// Hand translation distance required to reach the toggle threshold (e.g. 0.035 for 3.5 cm).
    public var travelDistance: Float
    
    /// Threshold progress [0.0 ... 1.0] after which the switch snaps to ON. Default is 0.6 (60%).
    public var toggleThreshold: Float
    
    /// Whether the lever springs back to OFF if released before crossing `toggleThreshold`.
    public var springBackOnRelease: Bool
    
    /// Whether the interaction rotates `leverEntity`.
    public var affectsTransform: Bool
    
    /// Specific sub-entity representing the switch lever arm. If nil, rotates targetEntity.
    public weak var leverEntity: Entity?
    
    // Internal state caching
    private var initialLeverOrientation: simd_quatf = simd_quatf(real: 1, imag: .zero)
    private var initialHandPosition: SIMD3<Float> = .zero
    private var hasRecordedInitialRot = false
    
    public init(
        name: String = "Switch",
        pivotAxis: SIMD3<Float> = [1, 0, 0],
        offAngleRadians: Float = -0.52, // ~ -30 degrees
        onAngleRadians: Float = 0.52,   // ~ +30 degrees
        flipDirection: SIMD3<Float> = [0, 1, 0],
        travelDistance: Float = 0.035,
        toggleThreshold: Float = 0.6,
        springBackOnRelease: Bool = true,
        affectsTransform: Bool = true,
        leverEntity: Entity? = nil
    ) {
        self.name = name
        self.pivotAxis = simd_normalize(pivotAxis)
        self.offAngleRadians = offAngleRadians
        self.onAngleRadians = onAngleRadians
        self.flipDirection = simd_normalize(flipDirection)
        self.travelDistance = travelDistance
        self.toggleThreshold = toggleThreshold
        self.springBackOnRelease = springBackOnRelease
        self.affectsTransform = affectsTransform
        self.leverEntity = leverEntity
    }
    
    public func onStart(targetEntity: Entity, handAnchorTransform: Transform) {
        let entity = leverEntity ?? targetEntity
        if !hasRecordedInitialRot {
            initialLeverOrientation = entity.orientation
            hasRecordedInitialRot = true
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
        
        let entity = leverEntity ?? targetEntity
        
        // Convert flip direction to world coordinates
        let worldFlipDir = simd_normalize(entity.convert(direction: flipDirection, to: nil))
        
        // Measure hand movement along the flip direction
        let handDelta = currentHandTransform.translation - initialHandPosition
        let movement = simd_dot(handDelta, worldFlipDir)
        
        // Normalized progress between 0 and 1
        let rawProgress = travelDistance > 0.001 ? (movement / travelDistance) : 1.0
        let clampedProgress = max(0.0, min(rawProgress, 1.0))
        
        // Interpolate angle
        let currentAngle = offAngleRadians + (onAngleRadians - offAngleRadians) * clampedProgress
        
        if affectsTransform {
            entity.orientation = simd_quatf(angle: currentAngle, axis: pivotAxis)
        }
        
        // Check mechanical snap threshold
        if clampedProgress >= toggleThreshold {
            // Snaps fully to ON position
            if affectsTransform {
                entity.orientation = simd_quatf(angle: onAngleRadians, axis: pivotAxis)
            }
            status = .completed
            return .completed
        } else {
            status = .inProgress(progress: clampedProgress)
            return status
        }
    }
    
    public func reset(targetEntity: Entity) {
        let entity = leverEntity ?? targetEntity
        if springBackOnRelease && !status.isCompleted {
            if affectsTransform {
                entity.orientation = simd_quatf(angle: offAngleRadians, axis: pivotAxis)
            }
            status = .idle
        }
    }
}

