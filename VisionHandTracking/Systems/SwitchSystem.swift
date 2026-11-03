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
                
            if comp.initialPosition == nil {
                comp.initialPosition = switchEntity.transform.translation
            }
            
            guard let initialPos = comp.initialPosition else { continue }
            
            let localBounds = switchEntity.visualBounds(relativeTo: nil).center
            let switchCenter = switchEntity.convert(position: localBounds, to: nil)
            var activePinchCenter: SIMD3<Float>? = nil
            var isPinching = false
                             
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
                
            if let pinchCenter = activePinchCenter, isPinching {
                if !comp.isGrabbed {
                    comp.isGrabbed = true
                    comp.isUnlocked = false
                    comp.startPinchPosition = pinchCenter
                } else if let startPinch = comp.startPinchPosition {
                    let pullDelta = pinchCenter - startPinch
                    
                    let worldPullAxis = switchEntity.parent?.convert(direction: comp.pullAxis, to: nil) ?? comp.pullAxis
                    let pullAmount = simd_dot(pullDelta, simd_normalize(worldPullAxis))
                                                    
                    let visualPull = max(0, min(pullAmount, comp.pullDistanceToUnlock))
                    let targetTranslation = initialPos + (comp.pullAxis * visualPull)
                    
                    switchEntity.transform.translation = simd_mix(switchEntity.transform.translation, targetTranslation, SIMD3<Float>(repeating: 0.4))
                                                    
                    if comp.isUnlocked {
                        print("pull is unlock")
                    } else {
                        if pullAmount >= comp.pullDistanceToUnlock {
                            comp.isUnlocked = true
                        }
                    }
                }
            } else {
                if comp.isGrabbed {
                    comp.isGrabbed = false
                    comp.isUnlocked = false
                    comp.startPinchPosition = nil
                }
                                                    
                switchEntity.transform.translation = simd_mix(
                    switchEntity.transform.translation,
                    initialPos,
                    SIMD3<Float>(repeating: 0.25)
                )
            }
            
            switchEntity.components.set(comp)
        }
    }
}
