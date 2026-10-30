//
//  HandVisualizationConfig.swift
//  VisionHandTracking
//
//  Created by Senior Spatial Engineer on 28/10/26.
//

import Foundation
import os

/// Thread-safe configuration bridge shared between SwiftUI state (`AppModel`) and RealityKit ECS Systems.
/// Allows per-frame systems (`HandVisualizationSystem`, `FingertipSnappingSystem`) to read user options
/// with zero allocations and zero thread contention.
public final class HandVisualizationConfig: @unchecked Sendable {
    public static let shared = HandVisualizationConfig()
    
    private var lock = os_unfair_lock()
    
    private var _isVisible: Bool = true
    private var _mode: HandRepresentationMode = .jointSpheres
    private var _isSnappingEnabled: Bool = true
    private var _snapDistanceThreshold: Float = 0.045     // 4.5 cm
    private var _releaseDistanceThreshold: Float = 0.075  // 7.5 cm (hysteresis)
    
    public init() {}
    
    /// Whether hand representations should be rendered in the immersive space.
    public var isVisible: Bool {
        get {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            return _isVisible
        }
        set {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            _isVisible = newValue
        }
    }
    
    /// The active representation mode: `.jointSpheres` or `.glove`.
    public var mode: HandRepresentationMode {
        get {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            return _mode
        }
        set {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            _mode = newValue
        }
    }
    
    /// Whether fingertip surface snapping is enabled.
    public var isSnappingEnabled: Bool {
        get {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            return _isSnappingEnabled
        }
        set {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            _isSnappingEnabled = newValue
        }
    }
    
    /// Distance (in meters) within which a fingertip snaps to a surface.
    public var snapDistanceThreshold: Float {
        get {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            return _snapDistanceThreshold
        }
        set {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            _snapDistanceThreshold = newValue
        }
    }
    
    /// Distance (in meters) beyond which a snapped fingertip breaks free from the surface.
    public var releaseDistanceThreshold: Float {
        get {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            return _releaseDistanceThreshold
        }
        set {
            os_unfair_lock_lock(&lock)
            defer { os_unfair_lock_unlock(&lock) }
            _releaseDistanceThreshold = newValue
        }
    }
}
