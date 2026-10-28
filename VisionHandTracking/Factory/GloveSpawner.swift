//
//  GloveSpawner.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 26/10/26.
//

import RealityKit
import ILSHandTracking
import Foundation
import ARKit

public struct GloveSpawner {
    
    /// Asynchronously loads `world.reality` and spawns both hand glove entities.
    /// Strictly loads from `world.reality` (never uses the USDZ files).
    public static func spawnHandGlovesAsync() async -> [Entity] {
        guard let scene = await loadScene() else {
            print("[GloveSpawner] Failed to load 'world.reality' scene.")
            return []
        }
        return spawnHandGloves(from: scene)
    }
    
    /// Extracts `RightGlove` and `LeftGlove` from the provided `world.reality` scene.
    /// Preserves internal hierarchy (converting cm-authored mesh to meters via parent scale 0.01),
    /// resets root positional staging offsets (e.g. +0.17m on RightGlove),
    /// and configures each hand anchor with `HandVisualizationComponent` and `ILHandTrackingComponent`.
    public static func spawnHandGloves(from scene: Entity, scale: SIMD3<Float> = .one) -> [Entity] {
        var spawnedHands: [Entity] = []
        
        let rightHand = Entity()
        rightHand.name = "RightHandAnchor"
        rightHand.components.set(ILHandTrackingComponent())
        
        if let rightGloveNode = scene.findEntity(named: "RightHumanHand") {
            // Remove from scene root (detaching from any outer 'Gloves' grouping)
            rightGloveNode.removeFromParent()
            
            // In world.reality, RightGlove is positioned at (0.17, 0, 0) for side-by-side staging in Reality Composer.
            // Reset position to (0, 0, 0) so the glove root aligns exactly with the user's wrist anchor.
            rightGloveNode.position = .zero
            rightGloveNode.orientation = simd_quatf(real: 1, imag: .zero)
            rightGloveNode.scale = scale
            
            // Find the skinned ModelEntity that contains the 27 joint definitions
            let skinnedRight = findSkinnedModel(in: rightGloveNode)
            
            // Attach the complete hierarchy under rightHand so scale conversion (0.01) and locators stay intact
            rightHand.addChild(rightGloveNode)
            rightHand.components.set(HandVisualizationComponent(
                chirality: .right,
                skinnedModel: skinnedRight,
                scale: scale
            ))
            
            spawnedHands.append(rightHand)
        } else {
            print("[GloveSpawner] Entity 'RightGlove' not found in world.reality")
        }
        
        // 2. Left Hand Glove
        let leftHand = Entity()
        leftHand.name = "LeftHandAnchor"
        leftHand.components.set(ILHandTrackingComponent())
        
        if let leftGloveNode = scene.findEntity(named: "LeftHumanHand") {
            leftGloveNode.removeFromParent()
            
            leftGloveNode.position = .zero
            leftGloveNode.orientation = simd_quatf(real: 1, imag: .zero)
            leftGloveNode.scale = scale
            
            let skinnedLeft = findSkinnedModel(in: leftGloveNode)
            
            leftHand.addChild(leftGloveNode)
            leftHand.components.set(HandVisualizationComponent(
                chirality: .left,
                skinnedModel: skinnedLeft,
                scale: scale
            ))
            
            spawnedHands.append(leftHand)
        } else {
            print("[GloveSpawner] Entity 'LeftGlove' not found in world.reality")
        }
        
        return spawnedHands
    }
    
    /// Loads the `world.reality` scene file from the main bundle.
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
    
    /// Finds the descendant ModelEntity with skeletal bones/joint definitions.
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
