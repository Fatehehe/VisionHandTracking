//
//  FingertipSnapComponent.swift
//  VisionHandTracking
//
//  Created by Senior Spatial Engineer on 28/10/26.
//

import RealityKit
import ARKit

/// Component attached to individual fingertip entities or tracked per-hand to manage
/// magnetic surface snapping state.
public struct FingertipSnapComponent: Component {
    /// Hand chirality (left or right).
    public let chirality: HandAnchor.Chirality
    
    /// The specific anatomical tip joint (e.g. `.indexFingerTip`).
    public let jointName: HandSkeleton.JointName
    
    /// Finger classification.
    public let finger: Finger
    
    /// Whether this fingertip is currently locked/snapped onto a surface.
    public var isSnapped: Bool = false
    
    /// The target contact point on the surface in world coordinates.
    public var targetWorldPosition: SIMD3<Float>?
    
    /// The smoothly interpolated visual world position (prevents jarring teleportation).
    public var currentWorldPosition: SIMD3<Float>?
    
    /// Outward surface normal vector at the point of contact.
    public var surfaceNormal: SIMD3<Float>?
    
    /// Visual snap animation progress (0.0 = free, 1.0 = fully snapped).
    public var snapFactor: Float = 0.0
    
    public init(
        chirality: HandAnchor.Chirality,
        jointName: HandSkeleton.JointName,
        finger: Finger
    ) {
        self.chirality = chirality
        self.jointName = jointName
        self.finger = finger
    }
}
