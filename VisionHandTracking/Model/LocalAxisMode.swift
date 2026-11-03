//
//  LocalAxisConfig.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 02/11/26.
//

import Foundation
import os

/// Filter option for selecting which components display their local coordinate axes.
public enum LocalAxisFilter: String, CaseIterable, Identifiable, Sendable {
    public var id: String { rawValue }
    
    case all = "All"
    case elements = "Elements"
    case fingertips = "Fingertips"
    case hands = "Hands"
}
