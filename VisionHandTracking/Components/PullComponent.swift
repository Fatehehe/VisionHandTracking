//
//  PullComponent.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 03/11/26.
//

import RealityKit
import simd
import ARKit

public struct PullComponent: Component {
    public var pullAxis: SIMD3<Float>
    public var pullDistanceToUnlock: Float
    public var isUnlocked: Bool = false
    public var initialPosition: SIMD3<Float>?
    public var interactionRadius: Float
    
    // NEW: State untuk memberi tahu sistem visual bahwa objek sedang ditarik
    public var isGrabbed: Bool = false
    
    /// Which hand (left or right) is currently grabbing this pull component.
    public var grabbingChirality: HandAnchor.Chirality? = nil
    
    /// Which fingers are actively grabbing this pull component (e.g. [.thumb, .index]).
    public var interactingFingers: Set<Finger> = [.thumb, .index]
    
    // NEW: Titik lokal pada objek di mana jari (cubitan) seharusnya menempel
    public var dragOffset: SIMD3<Float> = .zero
    
    public init(
        pullAxis: SIMD3<Float> = [0, 0, 1],
        pullDistanceToUnlock: Float = 0.025,
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
