//
//  AppModel.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 26/10/26.
//

import SwiftUI

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
    public var handRepresentationMode: HandMode = .jointSpheres
    public var showLocalAxisMode: Bool = false
    public var localAxisMode: LocalAxisCategory = .all
}
