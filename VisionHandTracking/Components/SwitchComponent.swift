//
//  SwitchComponent.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 03/11/26.
//

import RealityKit
import simd

public struct SwitchComponent: Component {
    
    // Sudut rotasi target dalam radian (contoh: -0.3 rad untuk state 0, 0.3 rad untuk state 1)
    public var states: [Float]
    public var currentStateIndex: Int
    
    // Sumbu putar (contoh: rotasi di sumbu X)
    public var localRotationAxis: SIMD3<Float>
    
    // Sumbu tarikan jari yang memicu perubahan (contoh: jari ditarik di sumbu Z)
    public var movementAxis: SIMD3<Float>
    
    // Jarak (dalam meter) yang harus dicapai jari untuk memindahkan 1 index. Default: 3cm
    public var dragSensitivity: Float
    public var interactionRadius: Float
    
    public var isInteracting: Bool = false
    public var startFingerPosition: SIMD3<Float>?
    public var startIndexAtGrab: Int = 0
    public var initialRotation: simd_quatf?
    
    public init(
        states: [Float] = [-0.3, 0.3],
        currentStateIndex: Int = 0,
        localRotationAxis: SIMD3<Float> = [1, 0, 0],
        movementAxis: SIMD3<Float> = [0, 0, 1],
        dragSensitivity: Float = 0.03,
        interactionRadius: Float = 0.035
    ) {
        self.states = states
        self.currentStateIndex = currentStateIndex
        self.localRotationAxis = localRotationAxis
        self.movementAxis = movementAxis
        self.dragSensitivity = dragSensitivity
        self.interactionRadius = interactionRadius
    }
}
