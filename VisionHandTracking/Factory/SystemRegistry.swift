//
//  SystemRegistry.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 26/10/26.
//  Refactored by Senior Spatial Engineer on 28/10/26.
//

import Foundation
import RealityKit
import ILSHandTracking

/// Centralized registry for initializing all RealityKit custom components and ECS systems.
public struct SystemRegistry {
    private static var isRegistered = false
    
    /// Registers all custom components and systems with RealityKit. Safe to call multiple times.
    public static func registerAllSystems() {
        guard !isRegistered else { return }
        isRegistered = true
        
        // 1. ILS Hand Tracking foundational systems
        ILFeatureHandTrackingSetup.registerSystems()
        
        // 2. Custom Components
        HandVisualizationComponent.registerComponent()
        SnappableSurfaceComponent.registerComponent()
        FingertipSnapComponent.registerComponent()
        HandJointEntityComponent.registerComponent()
        BoneConnectorComponent.registerComponent()
        
        // 3. Custom Systems
        FingertipSnappingSystem.registerSystem()
        HandVisualizationSystem.registerSystem()
    }
}
