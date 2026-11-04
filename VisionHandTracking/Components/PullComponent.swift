//
//  PullComponent.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 03/11/26.
//

import RealityKit
import simd

/// Component that allows an entity to be pulled along a local axis.
///
/// Hand contact and movement deltas are automatically provided by `HandInteractionComponent`.
public struct PullComponent: Component {
    /// Local axis along which the entity moves when pulled (default: `[0, 0, 1]`).
    public var pullAxis: SIMD3<Float>
    
    /// Distance (in meters) the entity must be pulled to trigger the unlock state (default: 0.025 m = 2.5 cm).
    public var pullDistanceToUnlock: Float
    
    /// Whether the entity is currently pulled to or past the unlock distance.
    public var isUnlocked: Bool = false
    
    /// Initial resting position of the entity before pulling.
    public var initialPosition: SIMD3<Float>?
    
    /// Proximity radius (used when auto-attaching HandInteractionComponent).
    public var interactionRadius: Float
    
    public init(
        pullAxis: SIMD3<Float> = [0, 0, 1],
        pullDistanceToUnlock: Float = 0.025,
        interactionRadius: Float = 0.05
    ) {
        self.pullAxis = pullAxis
        self.pullDistanceToUnlock = pullDistanceToUnlock
        self.interactionRadius = interactionRadius
    }
}
