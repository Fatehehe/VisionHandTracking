//
//  SequenceInteractionComponent.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 03/11/26.
//

import RealityKit

public struct InteractionStep {
    public let type: InteractionMode
    public var isCompleted: Bool = false
}

public struct SequenceInteractionComponent: Component {
    public var steps: [InteractionStep]
    public var currentStepIndex: Int = 0
    
    public init(steps: [InteractionMode]) {
        self.steps = steps.map { InteractionStep(type: $0) }
    }
    
    public var activeStep: InteractionMode? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex].type
    }
}
