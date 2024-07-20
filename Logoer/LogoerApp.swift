//
//  LogoerApp.swift
//  Logoer
//
//  Created by apple on 2024/7/18.
//

import SwiftUI
import Sparkle
import CoreGraphics

let ud = UserDefaults.standard
var updaterController: SPUStandardUpdaterController!

@main
struct LogoerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    var body: some Scene {
        Settings {
            SettingsView().fixedSize()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        createLogo()
        CGDisplayRegisterReconfigurationCallback(displayReconfigurationCallback, nil)
        let tipID = "logoer.first-start.note"
        let never = UserDefaults.standard.object(forKey: "neverRemindMe") as? [String] ?? []
        if !never.contains(tipID) {
            let alert = createAlert(title: "Logoer Tips".local, message: "When Logoer is running, you can run it again to bring up the settings panel.".local, button1: "Don't remind me again", button2: "OK")
            if alert.runModal() == .alertFirstButtonReturn {
                UserDefaults.standard.setValue(never + [tipID], forKey: "neverRemindMe")
            }
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        CGDisplayRemoveReconfigurationCallback(displayReconfigurationCallback, nil)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        createLogo()
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14, *) {
            NSApp.mainMenu?.items.first?.submenu?.item(at: 2)?.performAction()
        }else if #available(macOS 13, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.windows.first(where: { $0.title != "logo" })?.level = .floating
        }
        return true
    }
}

func displayReconfigurationCallback(display: CGDirectDisplayID, flags: CGDisplayChangeSummaryFlags, userInfo: UnsafeMutableRawPointer?) {
    createLogo()
}

func createLogo() {
    @AppStorage("pinOnNotch") var pinOnNotch = true
    @AppStorage("logoStyle") var logoStyle = "rainbow"
    
    for w in NSApp.windows.filter({ $0.title == "logo" }) { w.close() }
    for screen in NSScreen.screens {
        let appleMenuBarHeight = screen.frame.height - screen.visibleFrame.height - (screen.visibleFrame.origin.y - screen.frame.origin.y) - 1
        let logo = NSWindow(contentRect: NSRect(x:0, y: 0, width: 20, height: 20), styleMask: [.fullSizeContentView], backing: .buffered, defer: false)
        logo.contentView = NSHostingView(rootView: ContentView())
        logo.title = "logo".local
        logo.isOpaque = false
        logo.isRestorable = false
        logo.ignoresMouseEvents = true
        logo.isReleasedWhenClosed = false
        logo.level = .statusBar
        logo.backgroundColor = .clear
        logo.collectionBehavior = [.transient]
        if screen.hasTopNotchDesign && pinOnNotch { logo.collectionBehavior = [.canJoinAllSpaces, .transient] }
        if logoStyle == "emoji" {
            logo.setFrameOrigin(NSPoint(x: 17  + screen.frame.minX, y: screen.frame.minY + screen.frame.height - appleMenuBarHeight/2 - 7.5 - 2))
        } else {
            logo.hasShadow = false
            logo.setFrameOrigin(NSPoint(x: 19  + screen.frame.minX, y: screen.frame.minY + screen.frame.height - appleMenuBarHeight/2 - 7.5))
        }
        logo.orderFront(nil)
    }
}

func createAlert(level: NSAlert.Style = .warning, title: String, message: String, button1: String, button2: String = "") -> NSAlert {
    let alert = NSAlert()
    alert.messageText = title.local
    alert.informativeText = message.local
    alert.addButton(withTitle: button1.local)
    if button2 != "" { alert.addButton(withTitle: button2.local) }
    alert.alertStyle = level
    return alert
}

extension String {
    var local: String { return NSLocalizedString(self, comment: "") }
    var deletingPathExtension: String { return (self as NSString).deletingPathExtension }
}

extension NSScreen {
    var hasTopNotchDesign: Bool {
        guard #available(macOS 12, *) else { return false }
        return safeAreaInsets.top != 0
    }
}

extension NSMenuItem {
    func performAction() {
        guard let menu else { return }
        menu.performActionForItem(at: menu.index(of: self))
    }
}
