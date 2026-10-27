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
    public static func spawnHandGlovesAsync() async -> [Entity] {
        let rightHand = Entity()
        rightHand.name = "RightHandAnchor"
        rightHand.components.set(ILHandTrackingComponent())
        
        let leftHand = Entity()
        leftHand.name = "LeftHandAnchor"
        leftHand.components.set(ILHandTrackingComponent())
            
        if let rightModel = await loadAssetUSDZ(named: "RightGlove") {
            rightHand.components.set(HandVisualizationComponent(chirality: .right))
            rightHand.addChild(rightModel)
        }
        
        
        if let leftModel = await loadAssetUSDZ(named: "LeftGlove") {
            leftHand.components.set(HandVisualizationComponent(chirality: .left))
            leftHand.addChild(leftModel)
        }
        
        return [rightHand, leftHand]
    }
    
    public static func loadAsset(named entityName: String) async -> Entity? {
            do {
                let rootScene = try await Entity(named: "world")
                
                if let targetEntity = rootScene.findEntity(named: entityName) {
                    targetEntity.removeFromParent()
                    return targetEntity
                } else {
                    print("Entity dengan nama '\(entityName)' tidak ditemukan di handtrack.reality")
                    return nil
                }
                
            } catch {
                print("Gagal memuat file handtrack.reality: \(error.localizedDescription)")
                return nil
            }
        }
    
    public static func loadAssetUSDZ(named name: String) async -> Entity? {
        do {
            // Memuat file dari Main Bundle.
            // Cukup panggil nama filenya, misalnya "GloveModel" (tanpa .usdz) atau "GloveModel.usdz"
            let asset = try await Entity(named: name)
            return asset
        } catch {
            print("[GloveSpawner] Failed to load USDZ asset \(name): \(error.localizedDescription)")
            return nil
        }
    }
    
    public static func findSkinnedModel(in root: Entity) -> ModelEntity? {
        var queue: [Entity] = [root]
        while !queue.isEmpty {
            let current = queue.removeFirst()
            if let model = current as? ModelEntity, !model.jointNames.isEmpty {
                return model
            }
            queue.append(contentsOf: current.children)
        }
        // Fallback: no skinned model, use first plain ModelEntity.
        queue = [root]
        while !queue.isEmpty {
            let current = queue.removeFirst()
            if let model = current as? ModelEntity {
                return model
            }
            queue.append(contentsOf: current.children)
        }
        return nil
    }
    
    public static func spawnHandGloves(from scene: Entity) -> [Entity] {
            let rightHand = Entity()
            rightHand.name = "RightHandAnchor"
            rightHand.components.set(ILHandTrackingComponent())
            
            let leftHand = Entity()
            leftHand.name = "LeftHandAnchor"
            leftHand.components.set(ILHandTrackingComponent())
                
            // 1. Cari Glove Kanan dari dalam scene
            if let rightGloveNode = scene.findEntity(named: "RightGlove") {
                // CABUT dari scene 'world'
                rightGloveNode.removeFromParent()
                
                // PASTIKAN kita mendapatkan model yang ada tulangnya
                if let skinnedRight = findSkinnedModel(in: rightGloveNode) {
                    rightHand.components.set(HandVisualizationComponent(chirality: .right))
                    rightHand.addChild(skinnedRight) // Pasang yang skinned
                } else {
                    // Fallback jika tidak punya tulang
                    rightHand.addChild(rightGloveNode)
                }
            }
            
            // 2. Cari Glove Kiri dari dalam scene
            if let leftGloveNode = scene.findEntity(named: "LeftGlove") {
                // CABUT dari scene 'world'
                leftGloveNode.removeFromParent()
                
                if let skinnedLeft = findSkinnedModel(in: leftGloveNode) {
                    leftHand.components.set(HandVisualizationComponent(chirality: .left))
                    leftHand.addChild(skinnedLeft)
                } else {
                    leftHand.addChild(leftGloveNode)
                }
            }
            
            return [rightHand, leftHand]
        }
        
        // Load scene tetap sama
        public static func loadScene() async -> Entity? {
            do {
                let scene = try await Entity(named: "world", in: Bundle.main)
                return scene
            } catch {
                print("Primary scene 'world' not found: \(error.localizedDescription)")
                return nil
            }
        }
}
