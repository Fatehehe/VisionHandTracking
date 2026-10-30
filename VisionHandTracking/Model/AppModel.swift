//
//  AppModel.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 26/10/26.
//  Refactored by Senior Spatial Engineer on 28/10/26.
//

import SwiftUI
import ARKit

/// Maintains app-wide reactive state for visionOS windows and immersive spaces.
@MainActor
@Observable
public final class AppModel {
    public let immersiveSpaceID = "ImmersiveSpace"
    
    public enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    
    public var immersiveSpaceState = ImmersiveSpaceState.closed
    
    // MARK: - Hand Representation Options
    
    /// Controls whether custom hand representations (Spheres or Glove) are rendered.
    public var showHandRepresentation: Bool = true {
        didSet {
            HandVisualizationConfig.shared.isVisible = showHandRepresentation
        }
    }
    
    /// The active visual representation: `.jointSpheres` or `.glove`.
    public var handRepresentationMode: HandRepresentationMode = .jointSpheres {
        didSet {
            HandVisualizationConfig.shared.mode = handRepresentationMode
        }
    }
    
    // MARK: - Fingertip Snapping Options
    
    /// Enables or disables magnetic surface snapping for fingertips.
    public var isFingertipSnappingEnabled: Bool = true {
        didSet {
            HandVisualizationConfig.shared.isSnappingEnabled = isFingertipSnappingEnabled
        }
    }
    
    /// Proximity threshold (in meters) within which a fingertip snaps to a surface.
    public var snappingDistanceThreshold: Float = 0.045 {
        didSet {
            HandVisualizationConfig.shared.snapDistanceThreshold = snappingDistanceThreshold
        }
    }
    
    // MARK: - Live Telemetry & Snapping Feedback
    
    /// Set of fingers on the left hand currently snapped to a surface.
    public var snappedFingersLeft: Set<Finger> = []
    
    /// Set of fingers on the right hand currently snapped to a surface.
    public var snappedFingersRight: Set<Finger> = []
    
    public init() {
        // Sync default configuration to thread-safe config
        HandVisualizationConfig.shared.isVisible = showHandRepresentation
        HandVisualizationConfig.shared.mode = handRepresentationMode
        HandVisualizationConfig.shared.isSnappingEnabled = isFingertipSnappingEnabled
        HandVisualizationConfig.shared.snapDistanceThreshold = snappingDistanceThreshold
    }
}
