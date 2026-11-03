//
//  SequenceInteractionSystem.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 03/11/26.
//

import RealityKit

public struct SequenceInteractionSystem: System {
    public static let query = EntityQuery(where: .has(SequenceInteractionComponent.self))
    
    public init(scene: RealityKit.Scene) {}
    
    public func update(context: SceneUpdateContext) {
        for entity in context.scene.performQuery(Self.query) {
            guard var seqComp = entity.components[SequenceInteractionComponent.self] else { continue }
            
            guard let activeStep = seqComp.activeStep else { continue }
            
            if var pullComp = entity.components[PullComponent.self] {
                pullComp.isUnlocked = (activeStep != .pull)
                entity.components.set(pullComp)
            }
            
            if var switchComp = entity.components[SwitchComponent.self] {
//                switchComp.isUnlocked = (activeStep != .slide)
                entity.components.set(switchComp)
            }
        }
    }
}
