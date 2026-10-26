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
}
