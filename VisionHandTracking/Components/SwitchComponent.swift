//
//  SwitchComponent.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 03/11/26.
//

import RealityKit
import simd

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
    
    /// Gesture condition: 1 finger (`.oneFinger`), 2 fingers (`.twoFingers`), or either (`.either`).
    public var fingerMode: HandGestureMode
    
    /// Physical behavior mode: `.snap` (instant snap to target state) or `.leverLike` (continuous tracking).
    public var behaviorMode: SwitchMode
    
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
        dragSensitivity: Float = 0.04,
        interactionRadius: Float = 0.05,
        fingerMode: HandGestureMode = .either,
        behaviorMode: SwitchMode = .snap,
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
