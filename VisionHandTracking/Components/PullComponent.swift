//
//  PullComponent.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 03/11/26.
//

import RealityKit
import ARKit
import simd

public struct PullComponent: Component {
    public var pullAxis: SIMD3<Float>
    public var pullDistanceToUnlock: Float
    public var isUnlocked: Bool = false
    public var initialPosition: SIMD3<Float>?
    public var interactionRadius: Float
    
    public var isGrabbed: Bool = false
    
    public var grabbingChirality: HandAnchor.Chirality? = nil
    public var interactingFingers: Set<Finger> = [.thumb, .index]
    
    public var dragOffset: SIMD3<Float> = .zero
    
    public init(
        pullAxis: SIMD3<Float> = [0, 0, 1],
        pullDistanceToUnlock: Float = 0.05,
        interactionRadius: Float = 0.05,
        dragOffset: SIMD3<Float> = .zero,
        grabbingChirality: HandAnchor.Chirality? = nil,
        interactingFingers: Set<Finger> = [.thumb, .index]
    ) {
        self.pullAxis = pullAxis
        self.pullDistanceToUnlock = pullDistanceToUnlock
        self.interactionRadius = interactionRadius
        self.dragOffset = dragOffset
        self.grabbingChirality = grabbingChirality
        self.interactingFingers = interactingFingers
    }
}
