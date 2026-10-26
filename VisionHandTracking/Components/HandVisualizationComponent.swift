//
//  HandVisualizationComponent.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 26/10/26.
//

import RealityKit
import ARKit

struct HandVisualizationComponent: Component {
    public let chirality: HandAnchor.Chirality
    
    public init(chirality: HandAnchor.Chirality) {
        self.chirality = chirality
    }
}
