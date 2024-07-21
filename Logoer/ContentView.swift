//
//  ContentView.swift
//  Logoer
//
//  Created by apple on 2024/7/18.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("userColor") var userColor: Color = .green
    @AppStorage("userEmoji") var userEmoji = "🍎"
    @AppStorage("logoStyle") var logoStyle = "rainbow"
    @AppStorage("userImage") var userImage: URL = URL(fileURLWithPath: "/")
    @State private var ibattery = InternalBattery.status
    @State private var innercColor = getPowerColor(InternalBattery.status.batteryLevel)
    
    var body: some View {
        if logoStyle == "color" {
            if #available(macOS 14, *) {
                ZStack {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 16.5, weight: .black))
                        .foregroundColor(userColor)
                        .offset(x: -0.1, y: -0.2)
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
                    .offset(x: 0.5, y: -0.2)
            }
        } else if logoStyle == "battery" {
            ZStack {
                Image("Apple_Inner" + (aboveSonoma ? "" : "_old"))
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(innercColor))
                    .frame(width: 16, height: 17)
                    .mask (
                        VStack {
                            Spacer()
                            Rectangle()
                                .frame(height: ibattery.batteryLevel >= 20 ? max(4, CGFloat(ibattery.batteryLevel) / 100 * 14) : 14)
                        }
                    )
                    .onReceive(batteryTimer) {_ in
                        InternalBattery.status = getPowerState()
                        ibattery = InternalBattery.status
                        innercColor = getPowerColor(ibattery.batteryLevel)
                    }
                if ibattery.acPowered {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 7.5, weight: .black))
                        .frame(width: 16, height: 17)
                        .foregroundColor(.white)
                        .offset(y: aboveSonoma ? 2 : 1.8)
                        .shadow(color: .black, radius: 1)
                }
            }.needOffset()
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
        } else if logoStyle == "emoji" {
            Text(userEmoji)
                .font(.system(size: 15.5, weight: .black))
                .offset(y: 0.2)
        } else if logoStyle == "custom" {
            if userImage != URL(fileURLWithPath: "/") {
                if let i = NSImage(contentsOf: userImage) {
                    Image(nsImage: i)
                        .interpolation(.high)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 17)
                        .needOffset()
                }
            }
        } else {
            Image(logoStyle + (aboveSonoma ? "" : "_old"))
                .interpolation(.high)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 17)
                .needOffset()
        }
    }
}

extension View {
    func needOffset() -> some View {
        if #available(macOS 14, *) {
            return self
        } else {
            return self.offset(x: -0.5, y: -0.5)
        }
    }
}
