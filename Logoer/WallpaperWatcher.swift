//
//  ScreenWatcher.swift
//  Logoer
//
//  Created by apple on 2024/8/3.
//

import AppKit

class WallpaperObserver {
    var lastWallpaperPath: String?
    
    func checkWallpaper() {
        DispatchQueue.global(qos: .background).async {
            if let currentWallpaperPath = self.getCurrentWallpaperPath() {
                DispatchQueue.main.async {
                    self.handleWallpaperChange(newPath: currentWallpaperPath)
                }
            } else {
                print("Failed to get current wallpaper path.")
            }
        }
    }
    
    func getCurrentWallpaperPath() -> String? {
        // Get the screen with the desktop
        guard let screen = NSScreen.screens.first else {
            print("Failed to retrieve screen")
            return nil
        }
        
        // Get the desktop image URL
        if let desktopImageURL = NSWorkspace.shared.desktopImageURL(for: screen) {
            // Extract and return the path from the URL
            print(desktopImageURL.path)
            return desktopImageURL.path
        } else {
            print("Failed to retrieve desktop wallpaper URL")
            return nil
        }
    }
    
    func handleWallpaperChange(newPath: String) {
        if let lastWallpaperPath = lastWallpaperPath, newPath != lastWallpaperPath {
            print("Desktop wallpaper changed!")
            createLogo()
            // Handle the wallpaper change here
        }
        
        lastWallpaperPath = newPath
    }
}
