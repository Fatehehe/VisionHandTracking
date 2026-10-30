//
//  Hand.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 26/10/26.
//  Enhanced by Senior Spatial Engineer on 28/10/26.
//

import ARKit

public struct Hand {
    /// Mapping of each skeleton joint to its associated finger and bone classification.
    public static let joints: [(HandSkeleton.JointName, Finger, Bone)] = [
        // Define the thumb bones.
        (.thumbKnuckle, .thumb, .knuckle),
        (.thumbIntermediateBase, .thumb, .intermediateBase),
        (.thumbIntermediateTip, .thumb, .intermediateTip),
        (.thumbTip, .thumb, .tip),

        // Define the index-finger bones.
        (.indexFingerMetacarpal, .index, .metacarpal),
        (.indexFingerKnuckle, .index, .knuckle),
        (.indexFingerIntermediateBase, .index, .intermediateBase),
        (.indexFingerIntermediateTip, .index, .intermediateTip),
        (.indexFingerTip, .index, .tip),

        // Define the middle-finger bones.
        (.middleFingerMetacarpal, .middle, .metacarpal),
        (.middleFingerKnuckle, .middle, .knuckle),
        (.middleFingerIntermediateBase, .middle, .intermediateBase),
        (.middleFingerIntermediateTip, .middle, .intermediateTip),
        (.middleFingerTip, .middle, .tip),

        // Define the ring-finger bones.
        (.ringFingerMetacarpal, .ring, .metacarpal),
        (.ringFingerKnuckle, .ring, .knuckle),
        (.ringFingerIntermediateBase, .ring, .intermediateBase),
        (.ringFingerIntermediateTip, .ring, .intermediateTip),
        (.ringFingerTip, .ring, .tip),

        // Define the little-finger bones.
        (.littleFingerMetacarpal, .little, .metacarpal),
        (.littleFingerKnuckle, .little, .knuckle),
        (.littleFingerIntermediateBase, .little, .intermediateBase),
        (.littleFingerIntermediateTip, .little, .intermediateTip),
        (.littleFingerTip, .little, .tip),

        // Define wrist and arm bones.
        (.forearmWrist, .forearm, .wrist),
        (.forearmArm, .forearm, .arm)
    ]
    
    /// The kinematic hierarchy connections defining bones between parent and child joints.
    public static let boneConnections: [(from: HandSkeleton.JointName, to: HandSkeleton.JointName)] = [
        // Forearm / Wrist
        (.forearmArm, .forearmWrist),
        (.forearmWrist, .wrist),
        
        // Wrist to Palm Metacarpals & Thumb Knuckle
        (.wrist, .thumbKnuckle),
        (.wrist, .indexFingerMetacarpal),
        (.wrist, .middleFingerMetacarpal),
        (.wrist, .ringFingerMetacarpal),
        (.wrist, .littleFingerMetacarpal),
        
        // Thumb kinematic chain
        (.thumbKnuckle, .thumbIntermediateBase),
        (.thumbIntermediateBase, .thumbIntermediateTip),
        (.thumbIntermediateTip, .thumbTip),
        
        // Index finger kinematic chain
        (.indexFingerMetacarpal, .indexFingerKnuckle),
        (.indexFingerKnuckle, .indexFingerIntermediateBase),
        (.indexFingerIntermediateBase, .indexFingerIntermediateTip),
        (.indexFingerIntermediateTip, .indexFingerTip),
        
        // Middle finger kinematic chain
        (.middleFingerMetacarpal, .middleFingerKnuckle),
        (.middleFingerKnuckle, .middleFingerIntermediateBase),
        (.middleFingerIntermediateBase, .middleFingerIntermediateTip),
        (.middleFingerIntermediateTip, .middleFingerTip),
        
        // Ring finger kinematic chain
        (.ringFingerMetacarpal, .ringFingerKnuckle),
        (.ringFingerKnuckle, .ringFingerIntermediateBase),
        (.ringFingerIntermediateBase, .ringFingerIntermediateTip),
        (.ringFingerIntermediateTip, .ringFingerTip),
        
        // Little finger kinematic chain
        (.littleFingerMetacarpal, .littleFingerKnuckle),
        (.littleFingerKnuckle, .littleFingerIntermediateBase),
        (.littleFingerIntermediateBase, .littleFingerIntermediateTip),
        (.littleFingerIntermediateTip, .littleFingerTip)
    ]
    
    /// The 5 anatomical fingertips eligible for surface snapping.
    public static let fingertipJoints: [(joint: HandSkeleton.JointName, finger: Finger)] = [
        (.thumbTip, .thumb),
        (.indexFingerTip, .index),
        (.middleFingerTip, .middle),
        (.ringFingerTip, .ring),
        (.littleFingerTip, .little)
    ]
    
    /// Identifies whether a joint name represents a fingertip.
    public static func isFingertip(_ jointName: HandSkeleton.JointName) -> Bool {
        switch jointName {
        case .thumbTip, .indexFingerTip, .middleFingerTip, .ringFingerTip, .littleFingerTip:
            return true
        default:
            return false
        }
    }
    
    /// Maps a fingertip joint name to its corresponding finger enum.
    public static func finger(for tipJoint: HandSkeleton.JointName) -> Finger? {
        switch tipJoint {
        case .thumbTip: return .thumb
        case .indexFingerTip: return .index
        case .middleFingerTip: return .middle
        case .ringFingerTip: return .ring
        case .littleFingerTip: return .little
        default: return nil
        }
    }
}
