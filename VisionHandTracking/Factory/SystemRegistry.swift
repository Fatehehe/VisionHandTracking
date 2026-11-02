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
    private static var isRegistered = false
    public static func registerAllSystems() {
        guard !isRegistered else { return }
        isRegistered = true
        
        ILFeatureHandTrackingSetup.registerSystems()
        
        HandVisualizationComponent.registerComponent()
        HandJointEntityComponent.registerComponent()
        BoneConnectorComponent.registerComponent()
        SnapTargetComponent.registerComponent()
        InteractionFlowComponent.registerComponent()
        
        HandVisualizationSystem.registerSystem()
        SnapSystem.registerSystem()
        InteractionFlowSystem.registerSystem()
    }
}
