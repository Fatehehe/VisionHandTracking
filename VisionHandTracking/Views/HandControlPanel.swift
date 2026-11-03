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
            
            Text(appModel.handRepresentationMode.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: Bindable(appModel).showLocalAxisMode) {
                    Label("Show Local Axes", systemImage: "viewfinder")
                        .font(.subheadline.weight(.semibold))
                }
                .toggleStyle(.switch)
                
                if appModel.showLocalAxisMode {
                    Picker("Filter", selection: Bindable(appModel).localAxisMode) {
                        ForEach(LocalAxisFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    HStack(spacing: 8) {
                        Text("X: Red").foregroundStyle(.red)
                        Text("•").foregroundStyle(.secondary)
                        Text("Y: Green").foregroundStyle(.green)
                        Text("•").foregroundStyle(.secondary)
                        Text("Z: Blue").foregroundStyle(.blue)
                    }
                    .font(.caption2.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 2)
                }
            }
        }
        .padding(20)
        .frame(width: 320)
        .glassBackgroundEffect()
    }
}
