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
    public var skinnedModel: ModelEntity?
    public var scale: SIMD3<Float>
    
    public init(
        chirality: HandAnchor.Chirality,
        skinnedModel: ModelEntity? = nil,
        scale: SIMD3<Float> = .one
    ) {
        self.chirality = chirality
        self.skinnedModel = skinnedModel
        self.scale = scale
    }
}
