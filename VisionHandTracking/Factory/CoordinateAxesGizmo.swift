//
//  CoordinateAxesGizmo.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 02/11/26.
//

import RealityKit
import UIKit
import simd

/// Factory and Entity extension for generating 3D local coordinate axes gizmos (X: Red, Y: Green, Z: Blue).
public struct CoordinateAxesGizmo {
    
    /// Generates a 3D coordinate axis gizmo entity.
    ///
    /// - Parameters:
    ///   - length: Length of each axis shaft in meters.
    ///   - thickness: Radius of the cylindrical shaft in meters.
    /// - Returns: A configured `Entity` containing X (Red), Y (Green), and Z (Blue) axes.
    public static func makeGizmo(
        length: Float = 0.035,
        thickness: Float = 0.0012
    ) -> Entity {
        let root = Entity()
        root.name = "LocalAxisGizmo"
        
        let shaftMesh = MeshResource.generateCylinder(height: length, radius: thickness)
        let tipMesh = MeshResource.generateSphere(radius: thickness * 2.2)
        let originMesh = MeshResource.generateSphere(radius: thickness * 1.6)
        
        // Emissive Unlit materials so axes remain clearly visible in all immersive lighting conditions
        let redMat = UnlitMaterial(color: UIColor.systemRed)
        let greenMat = UnlitMaterial(color: UIColor.systemGreen)
        let blueMat = UnlitMaterial(color: UIColor.systemBlue)
        let originMat = UnlitMaterial(color: UIColor.white)
        
        // 0. Origin sphere at [0, 0, 0]
        let originEntity = ModelEntity(mesh: originMesh, materials: [originMat])
        originEntity.name = "AxisOrigin"
        root.addChild(originEntity)
        
        // 1. Y Axis (+Y = Green): RealityKit cylinder is naturally aligned with Y
        let yShaft = ModelEntity(mesh: shaftMesh, materials: [greenMat])
        yShaft.name = "Y_Shaft"
        yShaft.position = [0.0, length * 0.5, 0.0]
        let yTip = ModelEntity(mesh: tipMesh, materials: [greenMat])
        yTip.name = "Y_Tip"
        yTip.position = [0.0, length, 0.0]
        root.addChild(yShaft)
        root.addChild(yTip)
        
        // 2. X Axis (+X = Red): Rotate from Y to +X (-90° around Z)
        let xShaft = ModelEntity(mesh: shaftMesh, materials: [redMat])
        xShaft.name = "X_Shaft"
        xShaft.position = [length * 0.5, 0.0, 0.0]
        xShaft.orientation =  simd_quatf(angle: -.pi * 0.5, axis: [0, 0, 1])
        let xTip = ModelEntity(mesh: tipMesh, materials: [redMat])
        xTip.name = "X_Tip"
        xTip.position = [length, 0.0, 0.0]
        root.addChild(xShaft)
        root.addChild(xTip)
        
        // 3. Z Axis (+Z = Blue): Rotate from Y to +Z (+90° around X)
        let zShaft = ModelEntity(mesh: shaftMesh, materials: [blueMat])
        zShaft.name = "Z_Shaft"
        zShaft.position = [0.0, 0.0, length * 0.5]
        zShaft.orientation = simd_quatf(angle: .pi * 0.5, axis: [1, 0, 0])
        let zTip = ModelEntity(mesh: tipMesh, materials: [blueMat])
        zTip.name = "Z_Tip"
        zTip.position = [0.0, 0.0, length]
        root.addChild(zShaft)
        root.addChild(zTip)
        
        return root
    }
}
