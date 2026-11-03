//
//  HandPoseProviding.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 03/11/26.
//

import Foundation

@MainActor
public protocol HandPoseProviding: AnyObject {
    var leftHand: HandPose? { get }
    var rightHand: HandPose? { get }

    func start() async throws
    func stop()
}
