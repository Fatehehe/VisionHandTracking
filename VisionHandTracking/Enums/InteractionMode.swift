//
//  InteractionMode.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 03/11/26.
//

public enum InteractionMode: String, Sendable, CaseIterable, Equatable {
    case pull = "Pull"
    case push = "Push"
    case slide = "Slide"
    case rotate = "Rotate"
    case switchLever = "Switch"
}
