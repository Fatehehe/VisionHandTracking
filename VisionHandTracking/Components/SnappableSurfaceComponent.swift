//
//  SnappableSurfaceComponent.swift
//  VisionHandTracking
//
//  Created by Senior Spatial Engineer on 28/10/26.
//

import RealityKit
import simd

/// Component that marks an Entity as a magnetically snappable surface.
/// Any developer can attach this component to any entity (tables, walls, controls, models)
/// to make hand fingertips snap to its surface when reaching it.
public struct SnappableSurfaceComponent: Component {
    /// Supported geometric bounding shapes for accurate surface projection.
    public enum ShapeType: Sendable {
        /// Oriented 3D Box bounding volume with (width, height, depth) extents in meters.
        case box(extents: SIMD3<Float>)
        /// Oriented 2D planar face with (width, length) extents in the XZ plane.
        case plane(extents: SIMD2<Float>)
        /// Spherical boundary with radius in meters.
        case sphere(radius: Float)
    }
    
    /// The geometric collision/snapping boundary.
    public var shape: ShapeType
    
    /// Maximum distance (in meters) from the surface within which a fingertip will snap.
    public var snapDistance: Float
    
    /// Distance (in meters) required to pull away before snapping disengages (hysteresis).
    public var releaseDistance: Float
    
    /// Normal offset applied along the surface normal so that fingertip geometry sits
    /// cleanly on top of the surface without z-fighting or clipping.
    public var surfaceOffset: Float
    
    /// Whether snapping is currently active on this surface.
    public var isEnabled: Bool
    
    public init(
        shape: ShapeType = .box(extents: [0.5, 0.04, 0.3]),
        snapDistance: Float = 0.045,
        releaseDistance: Float = 0.075,
        surfaceOffset: Float = 0.008,
        isEnabled: Bool = true
    ) {
        self.shape = shape
        self.snapDistance = snapDistance
        self.releaseDistance = releaseDistance
        self.surfaceOffset = surfaceOffset
        self.isEnabled = isEnabled
    }
    
    /// Computes the closest point and surface normal on this surface for an arbitrary query world position.
    ///
    /// - Parameters:
    ///   - queryWorldPoint: The 3D world position of the fingertip.
    ///   - surfaceWorldTransform: The world transform of the entity owning this component.
    /// - Returns: The surface contact point (with offset), outward normal, and Euclidean distance to surface.
    public func closestSurfacePoint(
        to queryWorldPoint: SIMD3<Float>,
        surfaceWorldTransform: Transform
    ) -> (point: SIMD3<Float>, normal: SIMD3<Float>, distance: Float) {
        let worldMatrix = surfaceWorldTransform.matrix
        let inverseMatrix = simd_inverse(worldMatrix)
        
        // 1. Transform query world position into entity's local space
        let localQuery4 = inverseMatrix * simd_float4(queryWorldPoint, 1.0)
        let localQuery = SIMD3<Float>(localQuery4.x, localQuery4.y, localQuery4.z)
        
        let localContact: (point: SIMD3<Float>, normal: SIMD3<Float>)
        
        switch shape {
        case .box(let extents):
            let half = extents * 0.5
            let clampedX = simd_clamp(localQuery.x, -half.x, half.x)
            let clampedZ = simd_clamp(localQuery.z, -half.z, half.z)
            
            // Prefer the top face if hovering above top
            if localQuery.y >= half.y {
                localContact = (SIMD3<Float>(clampedX, half.y, clampedZ), SIMD3<Float>(0, 1, 0))
            } else if localQuery.y <= -half.y {
                localContact = (SIMD3<Float>(clampedX, -half.y, clampedZ), SIMD3<Float>(0, -1, 0))
            } else {
                // Internal or side: project to nearest box face
                let dx = half.x - abs(localQuery.x)
                let dy = half.y - abs(localQuery.y)
                let dz = half.z - abs(localQuery.z)
                
                if dy <= dx && dy <= dz {
                    let signY: Float = localQuery.y >= 0 ? 1 : -1
                    localContact = (SIMD3<Float>(clampedX, signY * half.y, clampedZ), SIMD3<Float>(0, signY, 0))
                } else if dx <= dz {
                    let signX: Float = localQuery.x >= 0 ? 1 : -1
                    let clampedY = simd_clamp(localQuery.y, -half.y, half.y)
                    localContact = (SIMD3<Float>(signX * half.x, clampedY, clampedZ), SIMD3<Float>(signX, 0, 0))
                } else {
                    let signZ: Float = localQuery.z >= 0 ? 1 : -1
                    let clampedY = simd_clamp(localQuery.y, -half.y, half.y)
                    localContact = (SIMD3<Float>(clampedX, clampedY, signZ * half.z), SIMD3<Float>(0, 0, signZ))
                }
            }
            
        case .plane(let extents):
            let half = extents * 0.5
            let clampedX = simd_clamp(localQuery.x, -half.x, half.x)
            let clampedZ = simd_clamp(localQuery.z, -half.y, half.y)
            let signY: Float = localQuery.y >= 0 ? 1 : -1
            localContact = (SIMD3<Float>(clampedX, 0, clampedZ), SIMD3<Float>(0, signY, 0))
            
        case .sphere(let radius):
            let dist = simd_length(localQuery)
            if dist > 0.0001 {
                let dir = localQuery / dist
                localContact = (dir * radius, dir)
            } else {
                localContact = (SIMD3<Float>(0, radius, 0), SIMD3<Float>(0, 1, 0))
            }
        }
        
        // 2. Transform the local contact point and normal back into world space
        let worldContact4 = worldMatrix * simd_float4(localContact.point, 1.0)
        let worldPoint = SIMD3<Float>(worldContact4.x, worldContact4.y, worldContact4.z)
        
        let worldNormal4 = worldMatrix * simd_float4(localContact.normal, 0.0)
        let worldNormal = simd_normalize(SIMD3<Float>(worldNormal4.x, worldNormal4.y, worldNormal4.z))
        
        // 3. Offset outward along normal to account for fingertip geometry thickness
        let offsetWorldPoint = worldPoint + (worldNormal * surfaceOffset)
        let distance = simd_distance(queryWorldPoint, offsetWorldPoint)
        
        return (offsetWorldPoint, worldNormal, distance)
    }
}
