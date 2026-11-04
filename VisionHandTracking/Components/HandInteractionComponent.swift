//
//  HandInteractionComponent.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 04/11/26.
//

import RealityKit
import simd

/// Specifies which hand gestures an entity accepts for interaction.
public enum HandGestureMode: String, Sendable, CaseIterable {
    /// 1 finger: Interact by poking or pushing with index fingertip.
    case oneFinger = "1 Finger"
    /// 2 fingers: Interact by pinching or grabbing with thumb + fingertip.
    case twoFingers = "2 Fingers"
    /// Either: Can be interacted with 1 finger (poke) or 2 fingers (pinch).
    case either = "1 or 2 Fingers"
}

/// The current lifecycle phase of hand interaction on an entity.
public enum InteractionPhase: String, Sendable {
    case idle
    case began
    case active
    case ended
}

/// Centralized component that detects and computes hand interaction data for an entity.
///
/// Specialized interaction components (e.g. `PullComponent`, `SwitchComponent`, `SliderComponent`)
/// simply read from this component instead of calculating hand poses themselves.
public struct HandInteractionComponent: Component {
    
    // MARK: - Configuration Settings
    
    /// The gesture mode accepted by this entity (.oneFinger, .twoFingers, or .either).
    public var mode: HandGestureMode
    
    /// Detection radius in meters around the entity's visual center.
    public var interactionRadius: Float
    
    // MARK: - Output Data (Computed each frame by HandInteractionSystem)
    
    /// Current interaction lifecycle phase (.idle, .began, .active, .ended).
    public var phase: InteractionPhase = .idle
    
    /// Whether a hand is currently actively interacting with this entity.
    public var isInteracting: Bool = false
    
    /// Which gesture mode actually initiated the current contact (.oneFinger or .twoFingers).
    public var activeGrip: HandGestureMode? = nil
    
    /// World position of the contact point when the interaction began.
    public var startPosition: SIMD3<Float>? = nil
    
    /// Current world position of the contact point (index tip or pinch midpoint).
    public var currentPosition: SIMD3<Float>? = nil
    
    /// Previous frame world position of the contact point.
    public var previousPosition: SIMD3<Float>? = nil
    
    /// Total displacement vector from start position to current position in world coordinates (`currentPosition - startPosition`).
    public var totalDelta: SIMD3<Float> = .zero
    
    /// Frame-to-frame displacement vector (`currentPosition - previousPosition`).
    public var frameDelta: SIMD3<Float> = .zero
    
    public init(
        mode: HandGestureMode = .either,
        interactionRadius: Float = 0.065
    ) {
        self.mode = mode
        self.interactionRadius = interactionRadius
    }
}

