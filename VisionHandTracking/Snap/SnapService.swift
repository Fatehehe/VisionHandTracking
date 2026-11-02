//
//  SnapService.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 02/11/26.
//

import Foundation
import RealityKit
import ARKit
import os

/// Thread-safe central service that coordinates active fingertip snapping states.
/// Decouples snap detection (`SnapSystem`) from visual rendering (`HandVisualizationSystem`)
/// and decoupled interactions (`InteractionFlowSystem`).
public final class SnapService: @unchecked Sendable {
    public static let shared = SnapService()
    
    private var lock = os_unfair_lock()
    
    private struct HandSnapRecord {
        weak var entity: Entity?
        var fingerPositions: [Finger: SIMD3<Float>]
    }
    
    private var activeSnaps: [HandAnchor.Chirality: HandSnapRecord] = [:]
    
    public init() {}
    
    // MARK: - Registration & Updates
    
    /// Registers that a hand has successfully snapped to a target entity.
    public func registerSnap(
        chirality: HandAnchor.Chirality,
        entity: Entity,
        fingerPositions: [Finger: SIMD3<Float>]
    ) {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        activeSnaps[chirality] = HandSnapRecord(entity: entity, fingerPositions: fingerPositions)
    }
    
    /// Updates the world positions of snapped fingertips (e.g. as the target moves or rotates).
    public func updateSnapPositions(
        chirality: HandAnchor.Chirality,
        fingerPositions: [Finger: SIMD3<Float>]
    ) {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        activeSnaps[chirality]?.fingerPositions = fingerPositions
    }
    
    /// Releases the snap state for a given hand.
    public func releaseSnap(chirality: HandAnchor.Chirality) {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        activeSnaps.removeValue(forKey: chirality)
    }
    
    /// Clears all snap states.
    public func reset() {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        activeSnaps.removeAll()
    }
    
    // MARK: - Queries
    
    /// Checks whether the specified hand is currently snapped to any object.
    public func isHandSnapped(_ chirality: HandAnchor.Chirality) -> Bool {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        return activeSnaps[chirality]?.entity != nil
    }
    
    /// Checks whether a specific finger on a hand is currently snapped.
    public func isFingerSnapped(for chirality: HandAnchor.Chirality, finger: Finger) -> Bool {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        return activeSnaps[chirality]?.fingerPositions[finger] != nil
    }
    
    /// Retrieves the current world position to which a fingertip is snapped, or nil if free.
    public func snappedWorldPosition(for chirality: HandAnchor.Chirality, finger: Finger) -> SIMD3<Float>? {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        return activeSnaps[chirality]?.fingerPositions[finger]
    }
    
    /// Retrieves the entity currently snapped by the specified hand.
    public func snappedEntity(for chirality: HandAnchor.Chirality) -> Entity? {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        return activeSnaps[chirality]?.entity
    }
}

