//
//  HandControlPanel.swift
//  VisionHandTracking
//
//  Created by Senior Spatial Engineer on 28/10/26.
//

import SwiftUI
import ARKit

/// A modern spatial control panel providing real-time options to toggle hand representation,
/// switch representation style (Joint Spheres vs Glove), and configure fingertip surface snapping.
public struct HandControlPanel: View {
    @Environment(AppModel.self) private var appModel
    
    @State private var snappedLeft: Set<Finger> = []
    @State private var snappedRight: Set<Finger> = []
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Hand Visualization", systemImage: "hand.wave.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // Live status chip
                HStack(spacing: 6) {
                    Circle()
                        .fill(appModel.showHandRepresentation ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(appModel.showHandRepresentation ? "Active" : "Hidden")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())
            }
            
            Divider()
            
            // Section 1: Visibility Toggle
            Toggle(isOn: Bindable(appModel).showHandRepresentation) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Show Hand Representation")
                        .font(.subheadline.weight(.semibold))
                    Text("Render custom joint spheres or glove model in 3D")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.cyan)
            
            // Section 2: Representation Style Picker (only when visible)
            if appModel.showHandRepresentation {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Representation Style")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    Picker("Style", selection: Bindable(appModel).handRepresentationMode) {
                        ForEach(HandRepresentationMode.allCases) { mode in
                            Label(mode.rawValue, systemImage: mode.iconName)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            Divider()
            
            // Section 3: Fingertip Snapping Controls
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: Bindable(appModel).isFingertipSnappingEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fingertip Surface Snapping")
                            .font(.subheadline.weight(.semibold))
                        Text("Locks tips to surfaces while keeping other joints free")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.mint)
                
                if appModel.isFingertipSnappingEnabled {
                    // Live Snapped Finger Indicators
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Active Fingertip Contacts")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        HStack(spacing: 12) {
                            // Left Hand Chips
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Left Hand").font(.caption2).foregroundStyle(.secondary)
                                HStack(spacing: 4) {
                                    fingerBadge("T", isSnapped: snappedLeft.contains(.thumb))
                                    fingerBadge("I", isSnapped: snappedLeft.contains(.index))
                                    fingerBadge("M", isSnapped: snappedLeft.contains(.middle))
                                    fingerBadge("R", isSnapped: snappedLeft.contains(.ring))
                                    fingerBadge("L", isSnapped: snappedLeft.contains(.little))
                                }
                            }
                            
                            Spacer()
                            
                            // Right Hand Chips
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Right Hand").font(.caption2).foregroundStyle(.secondary)
                                HStack(spacing: 4) {
                                    fingerBadge("T", isSnapped: snappedRight.contains(.thumb))
                                    fingerBadge("I", isSnapped: snappedRight.contains(.index))
                                    fingerBadge("M", isSnapped: snappedRight.contains(.middle))
                                    fingerBadge("R", isSnapped: snappedRight.contains(.ring))
                                    fingerBadge("L", isSnapped: snappedRight.contains(.little))
                                }
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(20)
        .frame(width: 380)
        .task {
            while !Task.isCancelled {
                snappedLeft = FingertipSnappingService.shared.activeSnappedFingers(for: .left)
                snappedRight = FingertipSnappingService.shared.activeSnappedFingers(for: .right)
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func fingerBadge(_ label: String, isSnapped: Bool) -> some View {
        Text(label)
            .font(.caption2.bold())
            .frame(width: 24, height: 24)
            .background(
                isSnapped ?
                    Color.mint :
                    Color.white.opacity(0.1),
                in: Circle()
            )
            .foregroundStyle(isSnapped ? Color.black : Color.secondary)
            .shadow(color: isSnapped ? Color.mint.opacity(0.6) : .clear, radius: 4)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isSnapped)
    }
}
