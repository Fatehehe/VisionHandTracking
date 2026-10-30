//
//  FingertipSnappingService.swift
//  VisionHandTracking
//
//  Created by Senior Spatial Engineer on 28/10/26.
//

import Foundation
import ARKit
import os

/// State information for a single fingertip snapped to a surface.
public struct SnappedTipState: Sendable {
    public var isSnapped: Bool
    public var worldPosition: SIMD3<Float>
    public var surfaceNormal: SIMD3<Float>
    public var finger: Finger
    public var snapFactor: Float
    
    public init(
        isSnapped: Bool,
        worldPosition: SIMD3<Float> = .zero,
        surfaceNormal: SIMD3<Float> = [0, 1, 0],
        finger: Finger,
        snapFactor: Float = 0.0
    ) {
        self.isSnapped = isSnapped
        self.worldPosition = worldPosition
        self.surfaceNormal = surfaceNormal
        self.finger = finger
        self.snapFactor = snapFactor
    }
}

/// Centralized, thread-safe service tracking the surface snap states of all fingertips.
/// Completely decouples proximity detection (`FingertipSnappingSystem`) from visual rendering
/// (`HandVisualizationSystem`) and user interface telemetry (`AppModel`).
public final class FingertipSnappingService: @unchecked Sendable {
    public static let shared = FingertipSnappingService()
    
    private var lock = os_unfair_lock()
    
    /// Snapped state indexed by [Chirality: [JointName: SnappedTipState]]
    private var state: [HandAnchor.Chirality: [HandSkeleton.JointName: SnappedTipState]] = [
        .left: [:],
        .right: [:]
    ]
    
    public init() {}
    
    /// Records or updates the snap state of a fingertip.
    public func setSnapState(
        for chirality: HandAnchor.Chirality,
        joint: HandSkeleton.JointName,
        state: SnappedTipState
    ) {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        self.state[chirality]?[joint] = state
    }
    
    /// Retrieves the current snap state of a specific fingertip.
    public func snapState(
        for chirality: HandAnchor.Chirality,
        joint: HandSkeleton.JointName
    ) -> SnappedTipState? {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        return state[chirality]?[joint]
    }
    
    /// Returns the snapshot of all currently snapped tips for a given chirality.
    public func allSnappedTips(for chirality: HandAnchor.Chirality) -> [HandSkeleton.JointName: SnappedTipState] {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        return state[chirality] ?? [:]
    }
    
    /// Returns the set of fingers currently snapped for a given hand.
    public func activeSnappedFingers(for chirality: HandAnchor.Chirality) -> Set<Finger> {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        guard let handTips = state[chirality] else { return [] }
        var result = Set<Finger>()
        for (_, tipState) in handTips where tipState.isSnapped {
            result.insert(tipState.finger)
        }
        return result
    }
    
    /// Resets all snapping states (e.g. when hand tracking stops or system resets).
    public func reset() {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        state = [.left: [:], .right: [:]]
    }
}
