//
//  SwitchSystem.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 03/11/26.
//

import RealityKit
import ARKit
import ILSHandTracking
import simd
internal import ILSFoundation

public struct SwitchSystem: System {
    
    private static let query = EntityQuery(where: .has(SwitchComponent.self))
        
    public init(scene: RealityKit.Scene) {}
        
    public func update(context: SceneUpdateContext) {
        let switches = Array(context.scene.performQuery(Self.query))
        guard !switches.isEmpty else { return }
            
        let provider = SpatialRuntime.handPoseProvider
        let hands = [provider?.leftHand, provider?.rightHand].compactMap { $0 }
            
        for switchEntity in switches {
            guard var comp = switchEntity.components[SwitchComponent.self] else { continue }
            
            // Simpan rotasi awal sebagai referensi titik nol (0 radian)
            if comp.initialRotation == nil {
                comp.initialRotation = switchEntity.transform.rotation
            }
            
            guard let initialRot = comp.initialRotation else { continue }
            
            let localBounds = switchEntity.visualBounds(relativeTo: switchEntity).center
            let switchCenter = switchEntity.convert(position: localBounds, to: nil)
            var activePinchCenter: SIMD3<Float>? = nil
            var isPinching = false
                             
            // Deteksi Pinch
            for hand in hands {
                let allTips = [hand.thumbTipPosition] + hand.nonThumbFingertips
                for i in 0..<allTips.count {
                    for j in (i + 1)..<allTips.count {
                        let tip1 = allTips[i]
                        let tip2 = allTips[j]
                        if simd_distance(tip1, tip2) <= 0.03 {
                            let pinchMidpoint = (tip1 + tip2) / 2.0
                            if simd_distance(pinchMidpoint, switchCenter) <= comp.interactionRadius {
                                isPinching = true
                                activePinchCenter = pinchMidpoint
                                break
                            }
                        }
                    }
                    if isPinching { break }
                }
                if isPinching { break }
            }
                
            // Logika Interaksi Switch
            if let pinchCenter = activePinchCenter, isPinching {
                if !comp.isInteracting {
                    // Saat pertama kali jari melakukan pinch (grab)
                    comp.isInteracting = true
                    comp.startFingerPosition = pinchCenter
                    comp.startIndexAtGrab = comp.currentStateIndex
                } else if let startPos = comp.startFingerPosition {
                    // Saat jari bergerak sambil pinch
                    let pullDelta = pinchCenter - startPos
                    
                    // Hitung seberapa jauh tarikan pada sumbu pergerakan switch
                    let worldMovementAxis = switchEntity.parent?.convert(direction: comp.movementAxis, to: nil) ?? comp.movementAxis
                    let pullAmount = simd_dot(pullDelta, simd_normalize(worldMovementAxis))
                    
                    // Tentukan perubahan langkah (step) berdasarkan dragSensitivity
                    // Jika dragSensitivity 0.03, maka menarik sejauh 3cm = pindah 1 state
                    let stepsToMove = Int(round(pullAmount / comp.dragSensitivity))
                    var newIndex = comp.startIndexAtGrab + stepsToMove
                    
                    // Batasi index agar tidak keluar dari batas array states
                    newIndex = max(0, min(newIndex, comp.states.count - 1))
                    
                    if newIndex != comp.currentStateIndex {
                        comp.currentStateIndex = newIndex
                        print("Switch State Changed to Index: \(newIndex)")
                    }
                }
            } else {
                // Saat jari dilepas
                if comp.isInteracting {
                    comp.isInteracting = false
                    comp.startFingerPosition = nil
                }
            }
            
            // Visual Update: Rotasi objek ke sudut target sesuai currentStateIndex
            let targetAngle = comp.states[comp.currentStateIndex]
            let rotationDelta = simd_quatf(angle: targetAngle, axis: simd_normalize(comp.localRotationAxis))
            let targetRotation = initialRot * rotationDelta
            
            // Interpolasi (slerp) agar pergerakan rotasinya halus, tidak patah-patah
            switchEntity.transform.rotation = simd_slerp(
                switchEntity.transform.rotation,
                targetRotation,
                0.25 // Kecepatan animasi
            )
            
            // Simpan komponen yang sudah dimutasi kembali ke entitas
            switchEntity.components.set(comp)
        }
    }
}
