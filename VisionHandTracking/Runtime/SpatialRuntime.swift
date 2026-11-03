//
//  SpatialRuntime.swift
//  CockpitDomain
//
//  Created by Tafani Rabbani on 03/08/26.
//

import Foundation
import ILSHandTracking
import simd

@MainActor
public enum SpatialRuntime {
    public static var handPoseProvider: (any HandPoseProviding)?

    public static func deviceTransform() -> simd_float4x4? {
        HandTrackingService.shared.deviceTransform()
    }
}
