//
//  SwitchComponent.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 03/11/26.
//

import RealityKit
import simd

/// Specifies the hand gesture condition required to interact with the switch.
public enum SwitchFingerMode: String, Sendable, CaseIterable {
    /// 1 finger: Interact by poking or pushing with the index fingertip.
    case oneFinger = "1 Finger"
    /// 2 fingers: Interact by pinching or grabbing with thumb + fingertip.
    case twoFingers = "2 Fingers"
    /// Either: Can be interacted with 1 finger (poke) or 2 fingers (pinch).
    case either = "1 or 2 Fingers"
}

/// Specifies the physical interaction behavior mode of the switch.
public enum SwitchBehaviorMode: String, Sendable, CaseIterable {
    /// Snap mode: when triggered, automatically snaps directly to the targeted angle / state.
    case snap = "Snap"
    /// Lever-like mode: continuously follows finger displacement in real time, snapping to detent on release.
    case leverLike = "Lever-like"
}

/// Component that allows an entity to act as a realistic mechanical switch or lever.
///
/// Features:
/// - Configurable finger mode: 1 finger (`.oneFinger`), 2 fingers (`.twoFingers`), or either (`.either`).
/// - Configurable behavior mode: instant snap (`.snap`) or real-time continuous lever tracking (`.leverLike`).
/// - Multi-state support: any list of target angles in radians (e.g. `[-0.52, 0.52]` for 2-way, or `[-0.5, 0.0, 0.5]` for 3-way).
public struct SwitchComponent: Component {
    
    /// Target rotation angles in radians for each state (e.g. `[-0.52, 0.52]` for OFF -30° and ON +30°).
    public var states: [Float]
    
    /// Index of the current active state (default: 0).
    public var currentStateIndex: Int
    
    /// Local rotation axis around which the switch lever pivots (default: `[1, 0, 0]` - pitch around X).
    public var localRotationAxis: SIMD3<Float>
    
    /// Local axis along which finger movement drives the switch (default: `[0, 0, 1]` - along Z).
    public var movementAxis: SIMD3<Float>
    
    /// Distance (in meters) the hand must move to trigger a state transition (default: 0.035 m = 3.5 cm).
    public var dragSensitivity: Float
    
    /// Proximity radius in meters for fingertip or pinch detection (default: 0.065 m = 6.5 cm).
    public var interactionRadius: Float
    
    /// Condition specifying whether this switch requires 1 finger, 2 fingers, or allows either.
    public var fingerMode: SwitchFingerMode
    
    /// Physical behavior mode: `.snap` (instant snap to target state) or `.leverLike` (continuous tracking).
    public var behaviorMode: SwitchBehaviorMode
    
    /// Whether the switch is currently actively being manipulated by a hand.
    public var isInteracting: Bool = false
    
    /// The active finger mode that initiated the current interaction (.oneFinger or .twoFingers).
    public var activeGrip: SwitchFingerMode? = nil
    
    /// World position of the interacting finger/pinch when the interaction began.
    public var startFingerPosition: SIMD3<Float>?
    
    /// State index when grab/poke began.
    public var startIndexAtGrab: Int = 0
    
    /// Initial reference baseline rotation (0 radian baseline).
    public var initialRotation: simd_quatf?
    
    /// Callback triggered whenever the switch flips to a new state index.
    public var onStateChanged: ((Int) -> Void)?
    
    /// Convenience property indicating whether the switch is in the active / ON state (> 0).
    public var isOn: Bool {
        return currentStateIndex > 0
    }
    
    public init(
        states: [Float] = [-0.52, 0.52],
        currentStateIndex: Int = 0,
        localRotationAxis: SIMD3<Float> = [1, 0, 0],
        movementAxis: SIMD3<Float> = [0, 0, 1],
        dragSensitivity: Float = 0.035,
        interactionRadius: Float = 0.065,
        fingerMode: SwitchFingerMode = .either,
        behaviorMode: SwitchBehaviorMode = .snap,
        initialRotation: simd_quatf? = nil,
        onStateChanged: ((Int) -> Void)? = nil
    ) {
        self.states = states
        self.currentStateIndex = currentStateIndex
        self.localRotationAxis = localRotationAxis
        self.movementAxis = movementAxis
        self.dragSensitivity = dragSensitivity
        self.interactionRadius = interactionRadius
        self.fingerMode = fingerMode
        self.behaviorMode = behaviorMode
        self.initialRotation = initialRotation
        self.onStateChanged = onStateChanged
    }
}
