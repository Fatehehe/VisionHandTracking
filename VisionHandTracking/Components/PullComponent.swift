//
//  PullComponent.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 03/11/26.
//

import RealityKit
import simd

public struct PullComponent: Component {
    public var switchAxis: SIMD3<Float> = [1, 0, 0]
    
    public var isGrabbed: Bool = false
    public var isUnlocked: Bool = false
    
    public var initialPosition: SIMD3<Float>?
    public var interactionRadius: Float = 0.035
    public var pullDistanceToUnlock: Float = 0.025
    
    public var startPinchPosition: SIMD3<Float>?
    
    public var pullAxis: SIMD3<Float>
    
    public init(pullAxis: SIMD3<Float> = [0, 0, 1], interactionRadius: Float = 0.035) {
        self.pullAxis = pullAxis
        self.interactionRadius = interactionRadius
    }
}
