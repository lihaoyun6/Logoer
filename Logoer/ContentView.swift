//
//  ContentView.swift
//  Logoer
//
//  Created by apple on 2024/7/18.
//

import SwiftUI
import SDWebImageSwiftUI

struct maskImage {
    let url: URL
    let image: NSImage
}

class DataModel: ObservableObject {
    @Published var fullScreens = [NSRect]()
    @Published var masks = [maskImage]()
    @Published var appIcon = getIcon(app: NSWorkspace.shared.frontmostApplication)
    @Published var battery = getPowerState()
}

struct ContentView: View {
    @AppStorage("pinOnScreen") var pinOnScreen = false
    @AppStorage("maskMode") var maskMode = false
    @AppStorage("shadowON") var shadowON = false
    @AppStorage("userColor") var userColor: Color = .green
    @AppStorage("batteryColor") var batteryColor: Color = .white
    @AppStorage("userEmoji") var userEmoji = "🍎"
    @AppStorage("iconStroke") var iconStroke = "no"
    @AppStorage("logoStyle") var logoStyle = "rainbow"
    @AppStorage("userImage") var userImage: URL = URL(fileURLWithPath: "/")
    @ObservedObject var model: DataModel
    var screen: NSScreen!
    var maskURL: URL!
    
    var body: some View {
        ZStack {
            //Color.clear
            if let image = model.masks.first(where: { $0.url == maskURL })?.image, maskMode  {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 24, height: screen.hasTopNotchDesign ? 23 : 24)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    .offset(y: screen.hasTopNotchDesign ? -0.5 : 0)
                    .opacity(model.fullScreens.contains(screen.frame) ? 0 : 1)
            }
            ZStack {
                if logoStyle == "color" {
                    if #available(macOS 14, *) {
                        ZStack {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 16.5, weight: .black))
                                .foregroundColor(userColor)
                                .offset(x: -0.1, y: -0.2)
                                .shadow(color: Color.black.opacity(shadowON ? 0.3 : 0.0), radius: 1.5, y: 1.5)
                            Image(systemName: "apple.logo")
                                .font(.system(size: 16.5, weight: .black))
                                .foregroundColor(userColor)
                                .offset(y: -0.2)
                            Image(systemName: "apple.logo")
                                .font(.system(size: 16.5, weight: .black))
                                .foregroundColor(userColor)
                                .offset(x: -0.1, y: -0.1)
                            Image(systemName: "apple.logo")
                                .font(.system(size: 16.5, weight: .black))
                                .foregroundColor(userColor)
                                .offset(y: -0.1)
                        }.frame(width: 16, height: 17)
                    } else {
                        Image("Apple")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 17)
                            .foregroundColor(userColor)
                            .offset(x: -0.5, y: -0.5)
                            .shadow(color: Color.black.opacity(shadowON ? 0.3 : 0.0), radius: 1.5, y: 1.5)
                    }
                } else if logoStyle == "battery" {
                    ZStack {
                        if #available(macOS 14, *) {
                            ZStack {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 16.5, weight: .black))
                                    .foregroundColor(batteryColor)
                                    .shadow(color: Color.black.opacity(shadowON ? 0.3 : 0.0), radius: 1.5, y: 1.5)
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 16.5, weight: .black))
                                    .foregroundColor(batteryColor)
                                    .offset(x: -0.1)
                            }.frame(width: 16, height: 17)
                        } else {
                            Image("Apple")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 17)
                                .foregroundColor(batteryColor)
                                .shadow(color: Color.black.opacity(shadowON ? 0.3 : 0.0), radius: 1.5, y: 1.5)
                        }
                        ZStack {
                            ZStack {
                                if #available(macOS 14, *) {
                                    Image("Apple_Inner_old")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(Color(model.battery.levelColor))
                                        .frame(width: 16, height: 17)
                                        .offset(x: 0.3)
                                }
                                Image("Apple_Inner_old")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(Color(model.battery.levelColor))
                                    .frame(width: 16, height: 17)
                                    
                            }
                            .mask (
                                VStack {
                                    Spacer()
                                    Rectangle()
                                        .frame(height: model.battery.batteryLevel >= 20 ? max(4, CGFloat(model.battery.batteryLevel) / 100 * 14) : 14)
                                }
                            )
                            if model.battery.acPowered {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 7.5, weight: .black))
                                    .frame(width: 16, height: 17)
                                    .foregroundColor(.white)
                                    .offset(y: aboveSonoma ? 2 : 1.8)
                                    .shadow(color: .black, radius: 1)
                            }
                        }.needOffset(x: 0, y: -0.5)
                    }.offset(y: aboveSonoma ? -0.5 : 0)
                    .needOffset(x: -0.5, y: -0.5)
                } else if logoStyle == "rainbow" {
                    ZStack {
                        if #available(macOS 14, *) {
                            Image("rainbow")
                                .interpolation(.high)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 17)
                                .mask (
                                    ZStack {
                                        Image(systemName: "apple.logo")
                                            .font(.system(size: 17, weight: .black))
                                        Image(systemName: "apple.logo")
                                            .font(.system(size: 17, weight: .black))
                                            .offset(y: -0.05)
                                    }
                                )
                        } else {
                            Image("rainbow")
                                .interpolation(.high)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 17)
                                .mask (
                                    Image("Apple")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 17)
                                )
                                .offset(x: -0.5, y: -0.1)
                        }
                    }
                    .needOffset(x: 0, y: -0.5)
                    .shadow(color: Color.black.opacity(shadowON ? 0.3 : 0.0), radius: 1.5, y: 1.5)
                } else if logoStyle == "emoji" {
                    if maskMode {
                        Text(userEmoji).font(.system(size: 15))
                            .offset(y: screen.hasTopNotchDesign ? 1 : -0.5)
                            .shadow(color: Color.black.opacity(shadowON ? 0.3 : 0.0), radius: 1.5, y: 1.5)
                    } else {
                        Text(userEmoji)
                            .font(.system(size: 15.5))
                            .offset(x: 0.5)
                            .needOffset(x: 0, y: -0.5)
                            .shadow(color: Color.black.opacity(shadowON ? 0.2 : 0.0), radius: 1.5, y: 1.5)
                    }
                } else if logoStyle == "appicon" {
                    let color: Color = (iconStroke != "no") ? (iconStroke == "white" ? .white : .black) : .clear
                    Image(nsImage: dataModel.appIcon)
                        .interpolation(.high)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .shadow(color: color, radius: 0, x: 0.5)
                        .shadow(color: color, radius: 0, x: -0.5)
                        .shadow(color: color, radius: 0, y: 0.3)
                        .shadow(color: color, radius: 0, y: -0.5)
                        .offset(y: screen.hasTopNotchDesign ? 0.5 : -0.5)
                        .needOffset(x: -0.5, y: -0.5)
                        .shadow(color: Color.black.opacity(shadowON ? 0.3 : 0.0), radius: 1.5, y: 1.5)
                } else if logoStyle == "custom" {
                    ZStack {
                        if userImage != URL(fileURLWithPath: "/") {
                            if userImage.pathExtension == "gif" {
                                WebImage(url: userImage)
                                    .interpolation(.high)
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                if let i = NSImage(contentsOf: userImage) {
                                    Image(nsImage: i)
                                        .interpolation(.high)
                                        .resizable()
                                        .scaledToFit()
                                }
                            }
                        }
                    }
                    .frame(width: 18, height: 18)
                    .offset(y: screen.hasTopNotchDesign ? 0.5 : -0.5)
                    .needOffset(x: -0.5, y: -0.5)
                    .shadow(color: Color.black.opacity(shadowON ? 0.3 : 0.0), radius: 1.5, y: 1.5)
                } else {
                    Image(logoStyle + (aboveSonoma ? "" : "_old"))
                        .interpolation(.high)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 17)
                        .needOffset(x: -0.5, y: -0.5)
                        .shadow(color: Color.black.opacity(shadowON ? 0.3 : 0.0), radius: 1.5, y: 1.5)
                }
            }.offset(y: screen.hasTopNotchDesign ? -1.5 : 0)
        }
        .opacity((model.fullScreens.contains(screen.frame) && !pinOnScreen) ? 0 : 1)
        .frame(width: 24, height: 24)
    }
}

extension View {
    func needOffset(x: CGFloat, y: CGFloat) -> some View {
        if #available(macOS 14, *) {
            return self
        } else {
            return self.offset(x: x, y: y)
        }
    }
}
