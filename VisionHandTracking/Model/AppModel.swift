//
//  AppModel.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 26/10/26.
//

import SwiftUI
import ARKit

struct FingerInfo: Identifiable, Sendable {
    let id: String
    let name: String
    var curlRatio: Float
    var isPinching: Bool
    var isExtended: Bool
    var isCurled: Bool

    static let defaultStates: [FingerInfo] = [
        FingerInfo(id: "thumb", name: "Thumb", curlRatio: 1.0, isPinching: false, isExtended: false, isCurled: false),
        FingerInfo(id: "index", name: "Index", curlRatio: 1.0, isPinching: false, isExtended: false, isCurled: false),
        FingerInfo(id: "middle", name: "Middle", curlRatio: 1.0, isPinching: false, isExtended: false, isCurled: false),
        FingerInfo(id: "ring", name: "Ring", curlRatio: 1.0, isPinching: false, isExtended: false, isCurled: false),
        FingerInfo(id: "little", name: "Little", curlRatio: 1.0, isPinching: false, isExtended: false, isCurled: false)
    ]
}

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    var showJointSpheres = true
    
    var handTrackingAuthorizationStatus: ARKitSession.AuthorizationStatus = .notDetermined
    
    func observeHandTrackingAuthorizationStatus() async {
        // The sample uses this instance to monitor for authorization changes.
        let arkitSession = ARKitSession()
        let authorizationResults = await arkitSession.requestAuthorization(for: [.handTracking])
        
        if let status = authorizationResults[.handTracking] {
            handTrackingAuthorizationStatus = status
        }
        
        for await event in arkitSession.events {
            guard case .authorizationChanged(let type, let status) = event,
                  type == .handTracking else {
                continue
            }

            handTrackingAuthorizationStatus = status
        }
    }
    
    var leftFingerStates: [FingerInfo] = FingerInfo.defaultStates
    var rightFingerStates: [FingerInfo] = FingerInfo.defaultStates
}
