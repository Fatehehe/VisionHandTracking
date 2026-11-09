//
//  SequenceInteractionComponent.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 03/11/26.
//

import RealityKit

public struct InteractionStep: Sendable, Equatable {
    public let type: InteractionMode
    public var isCompleted: Bool = false
    
    public init(type: InteractionMode, isCompleted: Bool = false) {
        self.type = type
        self.isCompleted = isCompleted
    }
}

public struct SequenceInteractionComponent: Component {
    /// Ordered steps required to complete the interaction sequence (e.g. [.pull, .switchLever]).
    public var steps: [InteractionStep]
    
    /// The index of the current active step in `steps`.
    public var currentStepIndex: Int = 0
    
    /// Whether the sequence automatically resets back to step 0 when the entire sequence is completed.
    public var autoResetOnCompletion: Bool = true
    
    /// Whether the sequence has completed all steps.
    public var isSequenceCompleted: Bool = false
    
    /// Recorded baseline state index when a switch step began (used to detect when state changes).
    public var stateIndexAtStepStart: Int? = nil
    
    /// Callback triggered whenever an individual step is completed.
    public var onStepCompleted: ((Int, InteractionMode) -> Void)? = nil
    
    /// Callback triggered when the entire sequence is completed.
    public var onSequenceCompleted: (() -> Void)? = nil
    
    /// Callback triggered when the sequence resets back to step 0.
    public var onSequenceReset: (() -> Void)? = nil
    
    public init(
        steps: [InteractionMode] = [.pull, .switchLever],
        autoResetOnCompletion: Bool = true,
        onStepCompleted: ((Int, InteractionMode) -> Void)? = nil,
        onSequenceCompleted: (() -> Void)? = nil,
        onSequenceReset: (() -> Void)? = nil
    ) {
        self.steps = steps.map { InteractionStep(type: $0) }
        self.autoResetOnCompletion = autoResetOnCompletion
        self.onStepCompleted = onStepCompleted
        self.onSequenceCompleted = onSequenceCompleted
        self.onSequenceReset = onSequenceReset
    }
    
    /// The currently active step mode, or `nil` if the sequence is finished.
    public var activeStep: InteractionMode? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex].type
    }
}
