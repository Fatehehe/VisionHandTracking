//
//  HandBuilder.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 30/10/26.
//

import RealityKit
import ILSHandTracking
import Foundation
import ARKit

public struct HandBuilder {
    public static func createHand(
        chirality: HandAnchor.Chirality,
        gloveScene: Entity? = nil
    ) -> Entity {
        let handAnchor = Entity()
        handAnchor.name = (chirality == .left) ? "LeftHandAnchor" : "RightHandAnchor"
        
        handAnchor.components.set(ILHandTrackingComponent())
        
        let jointSpheres = HandSpawner.spawnJointSpheres(chirality: chirality)
        handAnchor.addChild(jointSpheres)
        
        var gloveRoot: Entity?
        var skinnedModel: ModelEntity?
        
        if let scene = gloveScene,
           let extracted = HandSpawner.spawnGlove(from: scene, chirality: chirality) {
            gloveRoot = extracted.root
            skinnedModel = extracted.skinnedModel
            handAnchor.addChild(extracted.root)
        }
        
        let currentMode = HandMode.jointSpheres
        let isVisible = true
        
        jointSpheres.isEnabled = (currentMode == .jointSpheres)
        gloveRoot?.isEnabled = (currentMode == .gloves)
        handAnchor.isEnabled = isVisible
        
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
