//
//  HandJointEntityComponent.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 26/10/26.
//

import RealityKit
import ARKit

public struct HandJointEntityComponent: Component {
    public let jointName: HandSkeleton.JointName
    public let finger: Finger?
    public let bone: Bone
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

public struct BoneConnectorComponent: Component {
    public let fromJoint: HandSkeleton.JointName
    public let toJoint: HandSkeleton.JointName
    
    public init(
        fromJoint: HandSkeleton.JointName,
        toJoint: HandSkeleton.JointName
    ) {
        self.fromJoint = fromJoint
        self.toJoint = toJoint
    }
}
