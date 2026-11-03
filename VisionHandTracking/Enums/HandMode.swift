//
//  HandMode.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 30/10/26.
//

import Foundation

public enum HandMode: String, CaseIterable, Identifiable, Sendable {
    public var id: String {rawValue}
    
    case jointSpheres = "Joint Spheres"
    case gloves = "Hand Gloves"
    
    public var iconName: String{
        switch self {
        case .jointSpheres:
            return "circle.hexagongrid"
        case .gloves:
            return "hand.raised.fill"
        }
    }
    
    public var description: String{
        switch self {
        case .jointSpheres:
            return "Individual joint spheres and dynamic bone connections that reflect ARKit tracking and tip snapping."
        case .gloves:
            return "High-fidelity rigged glove mesh dynamically deformed by skeletal joint transforms."
        }
    }
}
