//
//  SnappableBoard.swift
//  VisionHandTracking
//
//  Created by Senior Spatial Engineer on 28/10/26.
//

import RealityKit
import UIKit

/// An interactive spatial tabletop / console entity engineered specifically to demonstrate
/// and test fingertip magnetic surface snapping in the immersive space.
public struct SnappableBoard {
    
    /// Spawns a floating frosted glass console equipped with `SnappableSurfaceComponent`.
    public static func spawnInteractiveBoard(
        position: SIMD3<Float> = [0.0, 0.95, -0.55],
        size: SIMD3<Float> = [0.55, 0.03, 0.32]
    ) -> Entity {
        let root = Entity()
        root.name = "SnappableInteractiveBoard"
        root.position = position
        
        // 1. Main Table Surface
        let boardMesh = MeshResource.generateBox(
            width: size.x,
            height: size.y,
            depth: size.z,
            cornerRadius: 0.015
        )
        
        var boardMaterial = PhysicallyBasedMaterial()
        boardMaterial.baseColor = .init(tint: UIColor(red: 0.12, green: 0.15, blue: 0.22, alpha: 0.85))
        boardMaterial.roughness = 0.2
        boardMaterial.metallic = 0.5
        boardMaterial.clearcoat = .init(floatLiteral: 0.8)
        
        let boardEntity = ModelEntity(mesh: boardMesh, materials: [boardMaterial])
        boardEntity.name = "BoardSurface"
        root.addChild(boardEntity)
        
        // 2. Subtle Glowing Border Accent
        let borderMesh = MeshResource.generateBox(
            width: size.x + 0.004,
            height: 0.004,
            depth: size.z + 0.004,
            cornerRadius: 0.016
        )
        var borderMaterial = PhysicallyBasedMaterial()
        borderMaterial.baseColor = .init(tint: UIColor(red: 0.0, green: 0.75, blue: 1.0, alpha: 0.6))
        borderMaterial.emissiveColor = .init(color: UIColor(red: 0.0, green: 0.75, blue: 1.0, alpha: 0.5))
        borderMaterial.roughness = 0.1
        
        let borderEntity = ModelEntity(mesh: borderMesh, materials: [borderMaterial])
        borderEntity.position = [0, (size.y * 0.5) - 0.002, 0]
        root.addChild(borderEntity)
        
        // 3. Attach SnappableSurfaceComponent
        // Tips approaching within 4.5cm of this board's surface will snap to it!
        root.components.set(SnappableSurfaceComponent(
            shape: .box(extents: size),
            snapDistance: 0.045,
            releaseDistance: 0.075,
            surfaceOffset: 0.008,
            isEnabled: true
        ))
        
        return root
    }
}
