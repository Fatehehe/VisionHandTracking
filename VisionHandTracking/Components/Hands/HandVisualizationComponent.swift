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
    
    // MARK: - Glove Snapping (OctaXR style)
    /// Whether this hand/glove is currently snapped to an interactable object.
    public var isSnapped: Bool = false
    
    /// Preserved joint transforms of the skinned glove model captured at grab.
    public var preservedGloveTransforms: [Transform]? = nil
    
    /// Preserved joint local positions for joint spheres mode captured at grab.
    public var preservedJointPositions: [HandSkeleton.JointName: SIMD3<Float>]? = nil
    
    /// The target entity the glove is currently snapped to.
    public var snappedTargetEntity: Entity? = nil
    
    /// World transform offset between target entity and hand anchor when grab began.
    public var anchorOffsetFromTarget: simd_float4x4? = nil
    
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
