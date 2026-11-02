//
//  SnapTargetComponent.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 02/11/26.
//

import RealityKit
import ARKit
import simd

/// A component that designates an Entity as an interactive object that hand fingertips can snap to.
///
/// Features:
/// - Supports customizable required fingertips (e.g., `[.index]` for buttons, `[.thumb, .index]` for switches/latches).
/// - Defines dedicated local snap points per finger (e.g., thumb grip notch vs. index grip notch).
/// - Dual-threshold hysteresis (`snapDistance` to engage, `releaseDistance` to break) prevents jitter.
/// - Stores active snap state for decoupled systems and visual rendering.
public struct SnapTargetComponent: Component {
    /// Whether snapping is currently active on this entity.
    public var isEnabled: Bool
    
    /// The specific anatomical fingertips required to snap to this target.
    /// For example: `[.index]` for poke buttons, `[.thumb, .index]` for pinch switches.
    public var requiredFingers: Set<Finger>
    
    /// If non-nil, restricts snapping to a specific hand (left or right).
    /// If nil, either hand can snap.
    public var allowedChirality: HandAnchor.Chirality?
    
    /// Proximity threshold (in meters) within which fingertips snap to their target points.
    public var snapDistance: Float
    
    /// Distance (in meters) beyond which snapping breaks/disengages.
    /// Typically larger than `snapDistance` to provide hysteresis.
    public var releaseDistance: Float
    
    /// Specific target positions (in the entity's local coordinate space) for each finger.
    /// If a required finger has no explicit entry, it falls back to `defaultSnapPoint`.
    public var snapPoints: [Finger: SIMD3<Float>]
    
    /// Default local target point if a finger is not explicitly configured in `snapPoints`.
    public var defaultSnapPoint: SIMD3<Float>
    
    /// Optional bounding radius for fast spatial culling before evaluating individual fingers.
    public var detectionRadius: Float?
    
    // MARK: - Runtime Snap State
    
    /// Whether the target is currently snapped by a hand.
    public var isSnapped: Bool
    
    /// The hand chirality currently snapped to this target, if any.
    public var snappedHand: HandAnchor.Chirality?
    
    /// World transform of the snapped hand anchor at the exact moment snap engaged.
    public var initialHandTransform: Transform?
    
    /// Closures called when snap engages or disengages
    public var onSnapEngaged: ((HandAnchor.Chirality) -> Void)?
    public var onSnapReleased: ((HandAnchor.Chirality) -> Void)?
    
    public init(
        requiredFingers: Set<Finger> = [.index],
        allowedChirality: HandAnchor.Chirality? = nil,
        snapDistance: Float = 0.045,
        releaseDistance: Float = 0.08,
        snapPoints: [Finger: SIMD3<Float>] = [:],
        defaultSnapPoint: SIMD3<Float> = .zero,
        detectionRadius: Float? = 0.15,
        isEnabled: Bool = true,
        onSnapEngaged: ((HandAnchor.Chirality) -> Void)? = nil,
        onSnapReleased: ((HandAnchor.Chirality) -> Void)? = nil
    ) {
        self.requiredFingers = requiredFingers
        self.allowedChirality = allowedChirality
        self.snapDistance = snapDistance
        self.releaseDistance = releaseDistance
        self.snapPoints = snapPoints
        self.defaultSnapPoint = defaultSnapPoint
        self.detectionRadius = detectionRadius
        self.isEnabled = isEnabled
        self.isSnapped = false
        self.snappedHand = nil
        self.initialHandTransform = nil
        self.onSnapEngaged = onSnapEngaged
        self.onSnapReleased = onSnapReleased
    }
    
    /// Returns the local snap target point for a given finger.
    public func localSnapPoint(for finger: Finger) -> SIMD3<Float> {
        return snapPoints[finger] ?? defaultSnapPoint
    }
    
    /// Returns the world snap target point for a given finger relative to the owner entity.
    public func worldSnapPoint(for finger: Finger, entity: Entity) -> SIMD3<Float> {
        let localPoint = localSnapPoint(for: finger)
        return entity.convert(position: localPoint, to: nil)
    }
}

