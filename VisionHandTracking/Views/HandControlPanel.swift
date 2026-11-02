//
//  HandControlPanel.swift
//  VisionHandTracking
//
//  Created by Fatakhillah Khaqo on 30/10/26.
//

import SwiftUI

public struct HandControlPanel: View {
    @Environment(AppModel.self) private var appModel
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            Text("Hand Representation")
                .font(.headline)
            
            Picker("Style", selection: Bindable(appModel).handRepresentationMode) {
                ForEach(HandMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.iconName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            
            // Menampilkan deskripsi singkat mode yang sedang aktif
            Text(appModel.handRepresentationMode.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(width: 320)
        .glassBackgroundEffect() // Efek kaca visionOS
    }
}
