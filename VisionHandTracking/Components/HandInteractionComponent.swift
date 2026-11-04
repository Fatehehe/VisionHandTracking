//
//  HandInteractionComponent.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 04/11/26.
//

import RealityKit
import simd

public enum HandGestureMode: String, Sendable, CaseIterable {
    case oneFinger = "1 Finger"
    case twoFingers = "2 Fingers"
    case either = "1 or 2 Fingers"
}

public enum InteractionPhase: String, Sendable {
    case idle
    case began
    case active
    case ended
}

public struct HandInteractionComponent: Component {
    
    public var mode: HandGestureMode
    public var interactionRadius: Float
    
    public var phase: InteractionPhase = .idle
    
    public var isInteracting: Bool = false
    public var activeGrip: HandGestureMode? = nil
    
    public var startPosition: SIMD3<Float>? = nil
    public var currentPosition: SIMD3<Float>? = nil
    public var previousPosition: SIMD3<Float>? = nil
    
    public var totalDelta: SIMD3<Float> = .zero
    public var frameDelta: SIMD3<Float> = .zero
    
    public init(
        mode: HandGestureMode = .either,
        interactionRadius: Float = 0.065
    ) {
        self.mode = mode
        self.interactionRadius = interactionRadius
    }
}

