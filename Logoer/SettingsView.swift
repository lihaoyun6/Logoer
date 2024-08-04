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
    @AppStorage("pinOnScreen") var pinOnScreen = false
    @AppStorage("launchAtLogin") var launchAtLogin = false
    @AppStorage("iconStroke") var iconStroke = "no"
    @AppStorage("logoStyle") var logoStyle = "rainbow"
    @AppStorage("userColor") var userColor: Color = .green
    @AppStorage("batteryColor") var batteryColor: Color = .white
    @AppStorage("userEmoji") var userEmoji = "🍎"
    @AppStorage("userImage") var userImage: URL = URL(fileURLWithPath: "/")
    @AppStorage("maskInterval") var maskInterval = 5
    @AppStorage("maskMode") var maskMode: Bool = false
    @AppStorage("shadowON") var shadowON: Bool = false
    @State private var importing = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    .onChange(of: launchAtLogin) { newValue in
                        SMLoginItemSetEnabled("com.lihaoyun6.LogoerHelper" as CFString, newValue)
                    }
                Spacer()
                Toggle("Always on Screen", isOn: $pinOnScreen)
                    .toggleStyle(.switch)
                    .onChange(of: pinOnScreen) { newValue in createLogo() }
                Spacer()
            }
            Divider()
            HStack {
                Picker("Logo Style:", selection: $logoStyle) {
                    Text("Rainbow Apple").tag("rainbow")
                    Text("Chrome Apple").tag("chrome")
                    Text("Glass Apple").tag("glass")
                    Text("Aqua Apple").tag("aqua")
                    Text("*Frontmost App Icon").tag("appicon")
                    Text("*Battery Indicator").tag("battery")
                    Text("*Custom Color").tag("color")
                    Text("*Custom Emoji").tag("emoji")
                    Text("*Custom Image").tag("custom")
                }
                .onChange(of: logoStyle) { _ in createLogo() }
                if logoStyle == "color" {
                    ColorPicker("", selection: $userColor)
                } else if logoStyle == "battery" {
                    ColorPicker("Background:", selection: $batteryColor)
                } else if logoStyle == "appicon" {
                    Picker("Stroke:", selection: $iconStroke) {
                        Text("Hidden").tag("no")
                        Text("White").tag("white")
                        Text("Black").tag("black")
                    }.fixedSize()
                } else if logoStyle == "emoji" {
                    Button("Random") { userEmoji = randomEmoji(full: maskMode) }
                    TextField("", text: $userEmoji)
                        .frame(width: 30)
                        .onChange(of: userEmoji) { newValue in
                            if newValue.count > 1 { userEmoji = String(newValue.first ?? "🍎") }
                            createLogo()
                        }
                } else if logoStyle == "custom" {
                    Button("Import…") { importing = true }
                        .fileImporter(isPresented: $importing, allowedContentTypes: [.image]) { result in
                            switch result {
                            case .success(let file):
                                let url = file.absoluteURL
                                _ = url.startAccessingSecurityScopedResource()
                                let fileManager = FileManager.default
                                let sandboxURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                                let destinationURL = sandboxURL.appendingPathComponent("user.\(url.pathExtension)")
                                do {
                                    if fileManager.fileExists(atPath: destinationURL.path) {
                                        try fileManager.removeItem(at: destinationURL)
                                    }
                                    try fileManager.copyItem(at: url, to: destinationURL)
                                    userImage = destinationURL
                                    createLogo(noCache: true)
                                } catch {
                                    print(error.localizedDescription)
                                }
                                url.stopAccessingSecurityScopedResource()
                            case .failure(let error):
                                print(error.localizedDescription)
                            }
                        }
                } else {
                    Spacer()
                }
            }.frame(height: 20)
            Divider()
            HStack {
                HStack(spacing: 2) {
                    Toggle("Auto-Mask", isOn: $maskMode)
                        .toggleStyle(.checkbox)
                        .onChange(of: maskMode) { newValue in createLogo() }
                    SWInfoButton(showOnHover: false, fillMode: true, animatePopover: true, content: "Automatically capture the color of the menu bar and cover the system default Logo.".local, primaryColor: NSColor.controlAccentColor)
                        .frame(width: 19, height: 19)
                }
                HStack(spacing: 3) {
                    Text("Refresh the mask every")
                        .foregroundColor(maskMode ? .primary : .secondary.opacity(0.5))
                    TextField("", value: $maskInterval, formatter: NumberFormatter())
                        .disabled(!maskMode)
                        .frame(width: 25)
                    Text("s")
                        .foregroundColor(maskMode ? .primary : .secondary.opacity(0.5))
                }
                Toggle("Shadow", isOn: $shadowON)
                    .toggleStyle(.checkbox)
            }.frame(height: 20)
            Divider()
            UpdaterSettingsView(updater: updaterController.updater)
            Spacer().frame(height: 10)
            HStack {
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("Logoer v\(version)").foregroundColor(.secondary.opacity(0.5))
                    Spacer()
                }
                Button(action: {
                    updaterController.updater.checkForUpdates()
                }, label: {
                    Text("Check for Updates…")
                })
                Spacer()
                Button(action: {
                    NSApp.terminate(self)
                }, label: {
                    Text("Quit Logoer")
                })
            }
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
