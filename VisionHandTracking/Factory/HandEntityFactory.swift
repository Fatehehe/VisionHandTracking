//
//  HandEntityFactory.swift
//  VisionHandTracking
//
//  Created by Senior Spatial Engineer on 28/10/26.
//

import RealityKit
import ARKit
import ILSHandTracking

/// High-level factory that assembles the complete Hand Anchor entity.
/// Combines both the Joint Spheres representation and the Rigged Glove model under a single anchor,
/// pre-wiring ECS components and ensuring instant zero-cost switching between representations.
public struct HandEntityFactory {
    
    /// Spawns a fully configured hand anchor entity containing both representations.
    ///
    /// - Parameters:
    ///   - chirality: Left or Right hand.
    ///   - gloveScene: Optional loaded scene containing the glove models (e.g. from `world.reality`).
    /// - Returns: Complete Hand Anchor entity ready to be added to the RealityView content.
    public static func createHand(
        chirality: HandAnchor.Chirality,
        gloveScene: Entity? = nil
    ) -> Entity {
        let handAnchor = Entity()
        handAnchor.name = (chirality == .left) ? "LeftHandAnchor" : "RightHandAnchor"
        
        // 1. Attach ILS tracking component for shared services compatibility
        handAnchor.components.set(ILHandTrackingComponent())
        
        // 2. Build Joint Spheres representation
        let jointSpheres = JointSpheresSpawner.spawnJointSpheres(chirality: chirality)
        handAnchor.addChild(jointSpheres)
        
        // 3. Extract and attach Rigged Glove representation (if scene available)
        var gloveRoot: Entity?
        var skinnedModel: ModelEntity?
        
        if let scene = gloveScene,
           let extracted = GloveSpawner.extractGlove(from: scene, chirality: chirality) {
            gloveRoot = extracted.root
            skinnedModel = extracted.skinnedModel
            handAnchor.addChild(extracted.root)
        }
        
        // 4. Initial representation active state
        let currentMode = HandVisualizationConfig.shared.mode
        let isVisible = HandVisualizationConfig.shared.isVisible
        
        jointSpheres.isEnabled = (currentMode == .jointSpheres)
        gloveRoot?.isEnabled = (currentMode == .glove)
        handAnchor.isEnabled = isVisible
        
        // 5. Attach master visualization component
        handAnchor.components.set(HandVisualizationComponent(
            chirality: chirality,
            mode: currentMode,
            isVisible: isVisible,
            jointSpheresRoot: jointSpheres,
            gloveRoot: gloveRoot,
            skinnedModel: skinnedModel
        ))
        
        return handAnchor
    }
}
