//
//  ContentView.swift
//  Logoer
//
//  Created by apple on 2024/7/18.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("userColor") var userColor: Color = .green
    @AppStorage("logoStyle") var logoStyle = "rainbow"
    
    var body: some View {
        if logoStyle == "rainbow" {
            ZStack {
                if #available(macOS 14, *) {
                    Image("Rainbow")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 17)
                        .mask (
                            Image(systemName: "apple.logo")
                                .font(.system(size: 17, weight: .black))
                        )
                        .offset(y: -0.05)
                    Image("Rainbow")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 17)
                        .mask (
                            Image(systemName: "apple.logo")
                                .font(.system(size: 17, weight: .black))
                        )
                } else {
                    Image("Rainbow")
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
        } else if logoStyle == "color" {
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
        }
    }
}
