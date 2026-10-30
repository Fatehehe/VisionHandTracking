//
//  HandRepresentationMode.swift
//  VisionHandTracking
//
//  Created by Senior Spatial Engineer on 28/10/26.
//

import Foundation

/// Defines the visual representation style for user hands in the immersive space.
public enum HandRepresentationMode: String, CaseIterable, Identifiable, Sendable {
    /// Visualizes each joint of the ARKit hand skeleton as an interactive sphere with connecting bone links.
    /// Provides precise visual feedback for joint movements and physical tip-snapping.
    case jointSpheres = "Joint Spheres"
    
    /// Visualizes the rigged, skinned 3D glove model loaded from the Reality Composer scene (`world.reality`).
    case glove = "Glove"
    
    public var id: String { rawValue }
    
    /// SF Symbol icon name representing this mode.
    public var iconName: String {
        switch self {
        case .jointSpheres:
            return "circle.hexagongrid"
        case .glove:
            return "hand.raised.fill"
        }
    }
    
    /// Detailed description for developer & user documentation.
    public var description: String {
        switch self {
        case .jointSpheres:
            return "Individual joint spheres and dynamic bone connections that reflect ARKit tracking and tip snapping."
        case .glove:
            return "High-fidelity rigged glove mesh dynamically deformed by skeletal joint transforms."
        }
    }
}
