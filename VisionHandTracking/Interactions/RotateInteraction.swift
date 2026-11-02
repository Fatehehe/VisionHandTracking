//
//  RotateInteraction.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 02/11/26.
//

import Foundation
import RealityKit
import simd

/// A decoupled interaction where a component or sub-entity must be rotated around a specific axis.
/// For example: turning a rotary dial, twisting a valve, or rotating a safe lock.
public final class RotateInteraction: SpatialInteraction {
    public let id: UUID = UUID()
    public var name: String
    public var status: InteractionStatus = .idle
    
    /// The normalized local axis of rotation (e.g., `[0, 1, 0]` for vertical yaw twist, `[0, 0, 1]` for roll).
    public var axis: SIMD3<Float>
    
    /// Target angle in radians required to complete the interaction (e.g., `Float.pi / 2` for 90°).
    public var targetAngleRadians: Float
    
    /// Whether the rotated element springs back to initial orientation upon release if not completed.
    public var springBackOnRelease: Bool
    
    /// Whether the interaction visually turns `rotateEntity`.
    public var affectsTransform: Bool
    
    /// Optional specific sub-entity (e.g. knob, dial mesh). If nil, rotates the owning target entity.
    public weak var rotateEntity: Entity?
    
    // Internal state caching
    private var initialEntityOrientation: simd_quatf = simd_quatf(real: 1, imag: .zero)
    private var initialHandOrientation: simd_quatf = simd_quatf(real: 1, imag: .zero)
    private var initialHandPosition: SIMD3<Float> = .zero
    private var hasRecordedInitialEntityRot = false
    
    public init(
        name: String = "Rotate",
        axis: SIMD3<Float> = [0, 1, 0],
        targetAngleRadians: Float = .pi * 0.5,
        springBackOnRelease: Bool = false,
        affectsTransform: Bool = true,
        rotateEntity: Entity? = nil
    ) {
        self.name = name
        self.axis = simd_normalize(axis)
        self.targetAngleRadians = targetAngleRadians
        self.springBackOnRelease = springBackOnRelease
        self.affectsTransform = affectsTransform
        self.rotateEntity = rotateEntity
    }
    
    public func onStart(targetEntity: Entity, handAnchorTransform: Transform) {
        let entity = rotateEntity ?? targetEntity
        if !hasRecordedInitialEntityRot {
            initialEntityOrientation = entity.orientation
            hasRecordedInitialEntityRot = true
        }
        initialHandOrientation = handAnchorTransform.rotation
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
        
        let entity = rotateEntity ?? targetEntity
        
        // 1. Calculate hand orientation delta
        let currentHandRot = currentHandTransform.rotation
        let deltaHandRot = currentHandRot * initialHandOrientation.inverse
        
        // World rotation axis
        let worldAxis = simd_normalize(entity.convert(direction: axis, to: nil))
        
        // Project quaternion twist onto the world axis
        // q = [cos(theta/2), sin(theta/2) * axis]
        let twistImag = simd_dot(deltaHandRot.imag, worldAxis)
        let angleDelta = 2.0 * atan2(twistImag, deltaHandRot.real)
        
        // Clamp angle between 0 and targetAngleRadians
        let isReversed = targetAngleRadians < 0
        let clampedAngle: Float
        if isReversed {
            clampedAngle = min(0.0, max(angleDelta, targetAngleRadians))
        } else {
            clampedAngle = max(0.0, min(angleDelta, targetAngleRadians))
        }
        
        let progress = abs(targetAngleRadians) > 0.001 ? abs(clampedAngle / targetAngleRadians) : 1.0
        
        if affectsTransform {
            let rotationDelta = simd_quatf(angle: clampedAngle, axis: axis)
            entity.orientation = initialEntityOrientation * rotationDelta
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
        let entity = rotateEntity ?? targetEntity
        if springBackOnRelease || !status.isCompleted {
            if hasRecordedInitialEntityRot {
                entity.orientation = initialEntityOrientation
            }
            status = .idle
        }
    }
}

