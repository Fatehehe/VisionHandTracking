//
//  InteractionFlowSystem.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 02/11/26.
//

import RealityKit
import ARKit
import ILSHandTracking

/// RealityKit System driving the sequential execution of stacked spatial interactions.
///
/// Workflow:
/// 1. Queries entities possessing both `SnapTargetComponent` and `InteractionFlowComponent`.
/// 2. While snapped, directs real-time hand anchor delta movements into the active `SpatialInteraction` step.
/// 3. Upon step completion, automatically advances to the subsequent step until the entire flow is fulfilled.
/// 4. Manages release policies (spring-back reset vs. persistence) when fingertips disengage mid-flow.
public struct InteractionFlowSystem: System {
    public static let flowQuery = EntityQuery(where: .has(SnapTargetComponent.self) && .has(InteractionFlowComponent.self))
    
    public init(scene: RealityKit.Scene) {}
    
    public func update(context: SceneUpdateContext) {
        let deltaTime = Float(context.deltaTime)
        
        for entity in context.scene.performQuery(Self.flowQuery) {
            guard var flow = entity.components[InteractionFlowComponent.self],
                  let snapTarget = entity.components[SnapTargetComponent.self] else { continue }
            
            // Flow already completed
            if flow.isFlowCompleted {
                continue
            }
            
            if snapTarget.isSnapped, let chirality = snapTarget.snappedHand {
                let anchor = (chirality == .left) ?
                    HandTrackingService.shared.latestLeftHand :
                    HandTrackingService.shared.latestRightHand
                
                guard let trackedAnchor = anchor, trackedAnchor.isTracked else { continue }
                
                let currentHandTransform = Transform(matrix: trackedAnchor.originFromAnchorTransform)
                let initialHandTransform = snapTarget.initialHandTransform ?? currentHandTransform
                
                guard let currentStep = flow.currentStep else { continue }
                
                // Initialize step if entering it for the first time
                if !flow.currentStepStarted {
                    currentStep.onStart(targetEntity: entity, handAnchorTransform: currentHandTransform)
                    flow.currentStepStarted = true
                    flow.onStepStarted?(flow.currentStepIndex, currentStep)
                }
                
                // Update active step with hand kinematics
                let status = currentStep.update(
                    targetEntity: entity,
                    currentHandTransform: currentHandTransform,
                    initialHandTransform: initialHandTransform,
                    deltaTime: deltaTime
                )
                
                flow.onStepProgress?(flow.currentStepIndex, status.progress)
                
                // Check if current step was fulfilled
                if status.isCompleted {
                    flow.onStepCompleted?(flow.currentStepIndex, currentStep)
                    
                    if flow.autoAdvance {
                        flow.currentStepIndex += 1
                        flow.currentStepStarted = false
                        
                        if flow.currentStepIndex >= flow.steps.count {
                            // Entire flow fulfilled!
                            flow.isFlowCompleted = true
                            flow.onFlowCompleted?()
                        } else if let nextStep = flow.currentStep {
                            // Immediately initialize next step
                            nextStep.onStart(targetEntity: entity, handAnchorTransform: currentHandTransform)
                            flow.currentStepStarted = true
                            flow.onStepStarted?(flow.currentStepIndex, nextStep)
                        }
                    }
                }
                
                entity.components.set(flow)
                
            } else {
                // Hand is not snapped
                if flow.currentStepStarted {
                    switch flow.releasePolicy {
                    case .resetIncompleteStepOnly:
                        flow.currentStep?.reset(targetEntity: entity)
                        flow.currentStepStarted = false
                    case .resetEntireFlow:
                        flow.reset(on: entity)
                    case .persistState:
                        flow.currentStepStarted = false
                    }
                    entity.components.set(flow)
                }
            }
        }
    }
}

