//
//  SettingsView.swift
//  Logoer
//
//  Created by apple on 2024/7/19.
//

import SwiftUI
import Foundation
import ServiceManagement

struct SettingsView: View {
    @AppStorage("pinOnNotch") var pinOnNotch = true
    @AppStorage("launchAtLogin") var launchAtLogin = false
    @AppStorage("logoStyle") var logoStyle = "rainbow"
    @AppStorage("userColor") var userColor: Color = .green
    
    var body: some View {
        VStack {
            HStack {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    .onChange(of: launchAtLogin) { newValue in
                        SMLoginItemSetEnabled("com.lihaoyun6.LogoerHelper" as CFString, newValue)
                    }
                Spacer()
                Toggle("Pin to Notch Screen", isOn: $pinOnNotch)
                    .toggleStyle(.switch)
                    .onChange(of: pinOnNotch) { newValue in createLogo() }
            }
            Divider()
            HStack {
                Picker("Logo Style", selection: $logoStyle) {
                    Text("Rainbow Logo").tag("rainbow")
                    Text("Custom Color").tag("color")
                }.pickerStyle(.segmented)
                ColorPicker("", selection: $userColor)
                    .disabled(logoStyle != "color")
                    .opacity(logoStyle != "color" ? 0.5 : 1.0)
            }
            Divider()
            UpdaterSettingsView(updater: updaterController.updater)
            Button(action: {
                updaterController.updater.checkForUpdates()
            }, label: {
                Text("Check for Updates…")
            })
        }
        .fixedSize()
        .padding()
    }
}

extension NSColor {
    var rgba: (red: Double, green: Double, blue: Double, alpha: Double) {
        var r: CGFloat = .zero
        var g: CGFloat = .zero
        var b: CGFloat = .zero
        var a: CGFloat = .zero
        if let color = self.usingColorSpace(.sRGB) {
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
        }
        return (r, g, b, a)
    }
}

extension Color {
    var rgbaValues: (red: Double, green: Double, blue: Double, opacity: Double) {
        let rgba = NSColor(self).rgba
        return (rgba.red, rgba.green, rgba.blue, rgba.alpha)
    }
}

extension Color: @retroactive RawRepresentable {
    public typealias RawValue = String

    public init?(rawValue: String) {
        let components = rawValue.components(separatedBy: ",")
        let r = Double(components[0]) ?? .zero
        let g = Double(components[1]) ?? .zero
        let b = Double(components[2]) ?? .zero
        let o = Double(components[3]) ?? .zero
        self = .init(.sRGB, red: r, green: g, blue: b, opacity: o)
    }

    public var rawValue: String {
        let rgba = self.rgbaValues
        let r = String(format: "%0.8f", rgba.red)
        let g = String(format: "%0.8f", rgba.green)
        let b = String(format: "%0.8f", rgba.blue)
        let o = String(format: "%0.8f", rgba.opacity)
        return [r, g, b, o].joined(separator: ",")
    }
}
