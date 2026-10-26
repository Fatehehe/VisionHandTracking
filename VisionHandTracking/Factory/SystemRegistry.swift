//
//  SystemRegistry.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 26/10/26.
//

import Foundation
import RealityKit
import ILSHandTracking

public struct SystemRegistry {
    public static func registerAllSystems() {
        ILFeatureHandTrackingSetup.registerSystems()
        HandVisualizationComponent.registerComponent()
        HandVisualizationSystem.registerSystem()
    }
}
