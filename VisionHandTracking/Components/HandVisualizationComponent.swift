//
//  HandVisualizationComponent.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 26/10/26.
//  Refactored by Senior Spatial Engineer on 28/10/26.
//

import RealityKit
import ARKit

/// Configures an Entity as a root Hand Anchor visualization.
/// Holds references to both the joint spheres representation and the skinned glove model,
/// enabling instant zero-allocation switching between representation styles and visibility modes.
public struct HandVisualizationComponent: Component {
    /// Hand chirality (left or right).
    public let chirality: HandAnchor.Chirality
    
    /// The active representation mode.
    public var mode: HandRepresentationMode
    
    /// Whether hand visuals are rendered.
    public var isVisible: Bool
    
    /// Root entity container for the joint spheres representation.
    public var jointSpheresRoot: Entity?
    
    /// Root entity container for the rigged glove model.
    public var gloveRoot: Entity?
    
    /// Cached reference to the skinned ModelEntity (rigged mesh) inside the glove hierarchy.
    public var skinnedModel: ModelEntity?
    
    /// Mesh scale multiplier.
    public var scale: SIMD3<Float>
    
    public init(
        chirality: HandAnchor.Chirality,
        mode: HandRepresentationMode = .jointSpheres,
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
