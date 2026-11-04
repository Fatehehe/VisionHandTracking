//
//  PullComponent.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 03/11/26.
//

import RealityKit
import simd

public struct PullComponent: Component {
    public var pullAxis: SIMD3<Float>
    
    public var pullDistanceToUnlock: Float
    
    public var isUnlocked: Bool = false
    
    public var initialPosition: SIMD3<Float>?
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
