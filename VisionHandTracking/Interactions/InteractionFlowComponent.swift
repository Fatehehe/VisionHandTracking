//
//  InteractionFlowComponent.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 02/11/26.
//

import RealityKit
import Foundation

/// Policy defining how the interaction flow behaves when fingertips release mid-flow.
public enum FlowReleasePolicy: Sendable {
    /// Resets only the active incomplete step; previously completed steps remain locked in place.
    case resetIncompleteStepOnly
    /// Resets the entire flow back to Step 0.
    case resetEntireFlow
    /// Holds all positions where released without resetting.
    case persistState
}

/// A decoupled RealityKit Component that manages a sequential chain or stack of spatial interactions.
///
/// Example:
/// A pull-switch component where Step 0 is a `PullInteraction` (unlock latch),
/// followed by Step 1 `SwitchInteraction` (flip lever).
/// Fulfilling Step 0 automatically transitions the system to Step 1.
public struct InteractionFlowComponent: Component {
    /// The sequential stack of interactions that must be fulfilled in order.
    public var steps: [SpatialInteraction]
    
    /// The index of the currently active step.
    public var currentStepIndex: Int
    
    /// Whether all steps in the flow have been fulfilled.
    public var isFlowCompleted: Bool
    
    /// Whether fulfilling a step automatically advances to the next step immediately.
    public var autoAdvance: Bool
    
    /// Behavior when hand releases mid-flow.
    public var releasePolicy: FlowReleasePolicy
    
    /// Internal flag tracking whether `onStart` has been dispatched for the current step.
    public var currentStepStarted: Bool
    
    // MARK: - Callbacks
    public var onStepStarted: ((Int, SpatialInteraction) -> Void)?
    public var onStepProgress: ((Int, Float) -> Void)?
    public var onStepCompleted: ((Int, SpatialInteraction) -> Void)?
    public var onFlowCompleted: (() -> Void)?
    public var onFlowReset: (() -> Void)?
    
    public init(
        steps: [SpatialInteraction] = [],
        autoAdvance: Bool = true,
        releasePolicy: FlowReleasePolicy = .resetIncompleteStepOnly,
        onStepStarted: ((Int, SpatialInteraction) -> Void)? = nil,
        onStepProgress: ((Int, Float) -> Void)? = nil,
        onStepCompleted: ((Int, SpatialInteraction) -> Void)? = nil,
        onFlowCompleted: (() -> Void)? = nil,
        onFlowReset: (() -> Void)? = nil
    ) {
        self.steps = steps
        self.currentStepIndex = 0
        self.isFlowCompleted = false
        self.autoAdvance = autoAdvance
        self.releasePolicy = releasePolicy
        self.currentStepStarted = false
        self.onStepStarted = onStepStarted
        self.onStepProgress = onStepProgress
        self.onStepCompleted = onStepCompleted
        self.onFlowCompleted = onFlowCompleted
        self.onFlowReset = onFlowReset
    }
    
    /// The currently active interaction step, if any.
    public var currentStep: SpatialInteraction? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }
    
    /// Advances the flow to the next step.
    public mutating func advance(on entity: Entity) {
        currentStepIndex += 1
        currentStepStarted = false
        if currentStepIndex >= steps.count {
            isFlowCompleted = true
            onFlowCompleted?()
        }
    }
    
    /// Resets the flow back to the beginning.
    public mutating func reset(on entity: Entity) {
        for step in steps {
            step.reset(targetEntity: entity)
        }
        currentStepIndex = 0
        currentStepStarted = false
        isFlowCompleted = false
        onFlowReset?()
    }
}

