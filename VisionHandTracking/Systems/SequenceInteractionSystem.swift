//
//  SequenceInteractionSystem.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 03/11/26.
//

import RealityKit

/// RealityKit System that orchestrates sequential multi-step interactions.
///
/// Example Sequence:
/// - Step 0 (Pull): Knob/handle must be pulled past `pullDistanceToUnlock`.
///   While in Step 0, subsequent steps (like Switch) remain locked (`isLocked = true`).
/// - Step 1 (Switch): Once unlocked, the switch lever unlocks (`isLocked = false`)
///   and can be toggled to a new state.
/// - On Completion: When the switch state changes, if `autoResetOnCompletion` is true,
///   the pull knob springs back locked, the switch locks at the new state,
///   and the sequence resets to Step 0.
public struct SequenceInteractionSystem: System {
    public static let query = EntityQuery(where: .has(SequenceInteractionComponent.self))
    
    public init(scene: RealityKit.Scene) {}
    
    public func update(context: SceneUpdateContext) {
        for entity in context.scene.performQuery(Self.query) {
            guard var seqComp = entity.components[SequenceInteractionComponent.self] else { continue }
            
            // Locate associated component entities (checking self or descendants)
            let pullEntity = findPullEntity(from: entity)
            let switchEntity = findSwitchEntity(from: entity)
            
            guard let activeStep = seqComp.activeStep else {
                // Sequence is past all steps
                if seqComp.autoResetOnCompletion {
                    resetSequence(seqComp: &seqComp, pullEntity: pullEntity, switchEntity: switchEntity)
                    entity.components.set(seqComp)
                }
                continue
            }
            
            switch activeStep {
            case .pull:
                // Step: PULL
                // 1. Ensure switch is locked while waiting for pull to unlock
                if let sEntity = switchEntity, var sComp = sEntity.components[SwitchComponent.self] {
                    if !sComp.isLocked {
                        sComp.isLocked = true
                        sEntity.components.set(sComp)
                    }
                }
                
                // 2. Check if pull component has unlocked
                if let pEntity = pullEntity, let pComp = pEntity.components[PullComponent.self] {
                    if pComp.isUnlocked {
                        // Step 0 Completed!
                        seqComp.steps[seqComp.currentStepIndex].isCompleted = true
                        seqComp.onStepCompleted?(seqComp.currentStepIndex, .pull)
                        print("[SequenceSystem] Step \(seqComp.currentStepIndex) (.pull) completed!")
                        
                        // Advance to next step
                        seqComp.currentStepIndex += 1
                        seqComp.stateIndexAtStepStart = nil
                        
                        // Unlock the switch immediately
                        if let sEntity = switchEntity, var sComp = sEntity.components[SwitchComponent.self] {
                            sComp.isLocked = false
                            seqComp.stateIndexAtStepStart = sComp.currentStateIndex
                            sEntity.components.set(sComp)
                            print("[SequenceSystem] Unlocked switch for next step!")
                        }
                    }
                }
                
            case .switchLever, .rotate:
                // Step: SWITCH / ROTATE
                // 1. Ensure switch is unlocked
                if let sEntity = switchEntity, var sComp = sEntity.components[SwitchComponent.self] {
                    if sComp.isLocked {
                        sComp.isLocked = false
                        sEntity.components.set(sComp)
                    }
                    
                    // Track starting state index
                    if seqComp.stateIndexAtStepStart == nil {
                        seqComp.stateIndexAtStepStart = sComp.currentStateIndex
                    }
                    
                    // 2. Check if switch has toggled to a new state
                    if let startIdx = seqComp.stateIndexAtStepStart, sComp.currentStateIndex != startIdx {
                        // Step Completed!
                        seqComp.steps[seqComp.currentStepIndex].isCompleted = true
                        seqComp.onStepCompleted?(seqComp.currentStepIndex, activeStep)
                        print("[SequenceSystem] Step \(seqComp.currentStepIndex) (\(activeStep)) completed! New state: \(sComp.currentStateIndex)")
                        
                        seqComp.currentStepIndex += 1
                        seqComp.isSequenceCompleted = true
                        seqComp.onSequenceCompleted?()
                        
                        // If autoResetOnCompletion is enabled, relock and reset back to Step 0
                        if seqComp.autoResetOnCompletion {
                            resetSequence(seqComp: &seqComp, pullEntity: pullEntity, switchEntity: switchEntity)
                        }
                    }
                }
                
            case .push, .slide:
                // Other interaction modes can be handled here
                break
            }
            
            entity.components.set(seqComp)
        }
    }
    
    private func resetSequence(
        seqComp: inout SequenceInteractionComponent,
        pullEntity: Entity?,
        switchEntity: Entity?
    ) {
        print("[SequenceSystem] Auto-resetting sequence back to start (relocked).")
        seqComp.currentStepIndex = 0
        seqComp.isSequenceCompleted = false
        seqComp.stateIndexAtStepStart = nil
        for i in 0..<seqComp.steps.count {
            seqComp.steps[i].isCompleted = false
        }
        
        // Relock pull component (springs back to resting position)
        if let pEntity = pullEntity, var pComp = pEntity.components[PullComponent.self] {
            pComp.isUnlocked = false
            pEntity.components.set(pComp)
        }
        
        // Relock switch component (locks at current state)
        if let sEntity = switchEntity, var sComp = sEntity.components[SwitchComponent.self] {
            sComp.isLocked = true
            sEntity.components.set(sComp)
        }
        
        seqComp.onSequenceReset?()
    }
    
    private func findPullEntity(from root: Entity) -> Entity? {
        if root.components[PullComponent.self] != nil { return root }
        return root.findEntity(where: { $0.components[PullComponent.self] != nil })
    }
    
    private func findSwitchEntity(from root: Entity) -> Entity? {
        if root.components[SwitchComponent.self] != nil { return root }
        return root.findEntity(where: { $0.components[SwitchComponent.self] != nil })
    }
}
