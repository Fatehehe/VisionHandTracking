//
//  HandVisualizationComponent.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 26/10/26.
//

import RealityKit
import ARKit
 
public struct HandVisualizationComponent: Component {
    public let chirality: HandAnchor.Chirality
    public var mode: HandMode
    public var isVisible: Bool
    public var jointSpheresRoot: Entity?
    public var gloveRoot: Entity?
    public var skinnedModel: ModelEntity?
    public var scale: SIMD3<Float>
    
    public init(
        chirality: HandAnchor.Chirality,
        mode: HandMode = .jointSpheres,
        isVisible: Bool = true,
        jointSpheresRoot: Entity? = nil,
        gloveRoot: Entity? = nil,
        skinnedModel: ModelEntity? = nil,
        scale: SIMD3<Float> = .one
    ) {
        self.chirality = chirality
        self.mode = mode
        self.isVisible = isVisible
        self.jointSpheresRoot = jointSpheresRoot
        self.gloveRoot = gloveRoot
        self.skinnedModel = skinnedModel
        self.scale = scale
    }
}
