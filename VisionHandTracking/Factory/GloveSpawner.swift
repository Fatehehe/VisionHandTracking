//
//  GloveSpawner.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 26/10/26.
//  Refactored by Senior Spatial Engineer on 28/10/26.
//

import RealityKit
import Foundation
import ARKit

/// Responsible for extracting and preparing rigged 3D glove meshes from the Reality Composer scene (`world.reality`).
public struct GloveSpawner {
    
    /// Loads the `world.reality` scene bundle asynchronously.
    public static func loadScene() async -> Entity? {
        do {
            if let url = Bundle.main.url(forResource: "world", withExtension: "reality") {
                let scene = try await Entity(contentsOf: url)
                return scene
            }
            let scene = try await Entity(named: "world", in: Bundle.main)
            return scene
        } catch {
            print("[GloveSpawner] Failed to load 'world.reality': \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Extracts a glove entity for the given chirality from the scene root.
    /// Resets authoring offsets and extracts the internal skinned ModelEntity.
    public static func extractGlove(
        from scene: Entity,
        chirality: HandAnchor.Chirality,
        scale: SIMD3<Float> = .one
    ) -> (root: Entity, skinnedModel: ModelEntity?)? {
        let entityName = (chirality == .right) ? "2910_right_glove" : "2910_left_glove"
        
        guard let gloveNode = scene.findEntity(named: entityName) else {
            print("[GloveSpawner] Entity '\(entityName)' not found in scene.")
            return nil
        }
        
        // Detach from scene root
        gloveNode.removeFromParent()
        
        // In world.reality, RightGlove is positioned at (0.17, 0, 0) for side-by-side staging.
        // Reset translation to origin so it aligns precisely with the ARKit hand anchor wrist.
        gloveNode.position = .zero
        gloveNode.orientation = simd_quatf(real: 1, imag: .zero)
        gloveNode.scale = scale
        
        // Locate the rigged ModelEntity with joint names
        let skinnedModel = findSkinnedModel(in: gloveNode)
        
        return (root: gloveNode, skinnedModel: skinnedModel)
    }
    
    /// Finds the descendant ModelEntity that contains skeletal bones/joint definitions.
    public static func findSkinnedModel(in root: Entity) -> ModelEntity? {
        var queue: [Entity] = [root]
        while !queue.isEmpty {
            let current = queue.removeFirst()
            if let model = current as? ModelEntity, !model.jointNames.isEmpty {
                return model
            }
            queue.append(contentsOf: current.children)
        }
        return nil
    }
}
