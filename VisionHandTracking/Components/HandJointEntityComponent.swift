//
//  HandJointEntityComponent.swift
//  VisionHandTracking
//
//  Created by Senior Spatial Engineer on 28/10/26.
//

import RealityKit
import ARKit

/// Component attached to individual joint sphere entities for direct identification and update.
public struct HandJointEntityComponent: Component {
    /// The skeleton joint name this entity corresponds to.
    public let jointName: HandSkeleton.JointName
    
    /// The associated finger (nil for forearm/wrist).
    public let finger: Finger?
    
    /// The bone classification (wrist, knuckle, tip, etc.).
    public let bone: Bone
    
    /// Whether this joint is an anatomical fingertip.
    public let isTip: Bool
    
    public init(
        jointName: HandSkeleton.JointName,
        finger: Finger?,
        bone: Bone,
        isTip: Bool
    ) {
        self.jointName = jointName
        self.finger = finger
        self.bone = bone
        self.isTip = isTip
    }
}

/// Component attached to cylinder entities spanning between two skeleton joints.
public struct BoneConnectorComponent: Component {
    /// Starting joint.
    public let fromJoint: HandSkeleton.JointName
    
    /// Ending joint.
    public let toJoint: HandSkeleton.JointName
    
    public init(
        fromJoint: HandSkeleton.JointName,
        toJoint: HandSkeleton.JointName
    ) {
        self.fromJoint = fromJoint
        self.toJoint = toJoint
    }
}
