//
//  LogoerApp.swift
//  Logoer
//
//  Created by apple on 2024/7/18.
//

import SwiftUI
import Sparkle
import CoreGraphics
import SDWebImageSwiftUI

let ud = UserDefaults.standard
var deviceType = "Mac"
var maskLock = false
var aboveSonoma = false
var aboveSequoia = false
var dataModel = DataModel()
var appIcon = getIcon(app: NSWorkspace.shared.frontmostApplication)
var updaterController: SPUStandardUpdaterController!
var maskTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
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
    @AppStorage("logoStyle") var logoStyle = "rainbow"
    @AppStorage("maskInterval") var maskInterval = 5
    @AppStorage("maskMode") var maskMode: Bool = false
    let th = DispatchQueue.global(qos: .background)
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        th.async {
            while true {
                Thread.sleep(forTimeInterval: TimeInterval(self.maskInterval))
                if self.maskMode {
                    DispatchQueue.main.async {
                        if !maskLock { refeshMask() } else { maskLock = false }
                    }
                }
            }
        }
        th.async {
            while true {
                Thread.sleep(forTimeInterval: 0.5)
                DispatchQueue.main.async { getFullScreens() }
            }
        }
        th.async {
            while true {
                Thread.sleep(forTimeInterval: 2)
                DispatchQueue.main.async { dataModel.battery = getPowerState() }
            }
        }
        deviceType = getMacDeviceType()
        if #available(macOS 14, *) { aboveSonoma = true }
        if #available(macOS 15, *) { aboveSequoia = true }
        if maskMode { refeshMask() }
        createLogo()
        CGDisplayRegisterReconfigurationCallback(displayReconfigurationCallback, nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(didActivateApplication(_:)), name: NSWorkspace.didActivateApplicationNotification, object: nil)
        tips(id: "logoer.first-start.note", text: "When Logoer is running, you can run it again to bring up the settings panel.")
        tips(id: "logoer.full-screen.note", text: "Enabling \"Visible in Full Screen Mode\" will keep the logo visible in full screen mode.")
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        CGDisplayRemoveReconfigurationCallback(displayReconfigurationCallback, nil)
        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.didActivateApplicationNotification, object: nil)
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
    
    @objc func didActivateApplication(_ notification: Notification) {
        if logoStyle == "appicon",
           let userInfo = notification.userInfo,
           let app = userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            appIcon = getIcon(app: app)
            createLogo()
        }
    }
}

func getIcon(app: NSRunningApplication?) -> NSImage {
    if let app = app, let path = app.bundleURL?.path {
        if let rep = NSWorkspace.shared.icon(forFile: path)
            .bestRepresentation(for: NSRect(x: 0, y: 0, width: 128, height: 128), context: nil, hints: nil) {
            let icon = NSImage(size: rep.size)
            icon.addRepresentation(rep)
            return icon
        } else {
            return NSWorkspace.shared.icon(forFile: path)
        }
    }
    return NSImage.appiconBack
}

func displayReconfigurationCallback(display: CGDirectDisplayID, flags: CGDisplayChangeSummaryFlags, userInfo: UnsafeMutableRawPointer?) {
    createLogo()
}

func refeshMask() {
    @AppStorage("maskMode") var maskMode: Bool = false
    var masks = [maskImage]()
    let screens = NSScreen.screens
    for index in screens.indices {
        let screen = screens[index]
        let origin = getOrigin(of: screen, in: screens)
        let maskURL = getMaskURL(index: index)
        if maskMode {
            _ = process(path: "/usr/sbin/screencapture", arguments: ["-x", "-R", "\(origin.x),\(origin.y),4,4", maskURL.path])
            if let image = NSImage(contentsOf: maskURL) {
                masks.append(maskImage(url: maskURL, image: image))
            }
        }
    }
    dataModel.masks = masks
}

func createLogo(noCache: Bool = false, reMask: Bool = false) {
    @AppStorage("maskMode") var maskMode: Bool = false
    @AppStorage("logoStyle") var logoStyle = "rainbow"
    
    for w in NSApp.windows.filter({ $0.title == "logo" }) { w.close() }
    
    if noCache {
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk()
    }
    
    let screens = NSScreen.screens
    for index in screens.indices {
        let screen = screens[index]
        let maskURL = getMaskURL(index: index)
        let origin = getOrigin(of: screen, in: screens)
        // 暂未使用的特性
        if maskMode && reMask {
            maskLock = true
            _ = process(path: "/usr/sbin/screencapture", arguments: ["-x", "-R", "\(origin.x),\(origin.y),4,4", maskURL.path])
        }
        let appleMenuBarHeight = screen.frame.height - screen.visibleFrame.height - (screen.visibleFrame.origin.y - screen.frame.origin.y) - 1
        let logo = NSWindow(contentRect: NSRect(x:0, y: 0, width: 24, height: 24), styleMask: [.fullSizeContentView], backing: .buffered, defer: false)
        logo.contentView = NSHostingView(rootView: ContentView(model: dataModel, screen: screen, maskURL: maskURL))
        logo.title = "logo".local
        logo.isOpaque = false
        logo.hasShadow = false
        logo.isRestorable = false
        logo.ignoresMouseEvents = true
        logo.isReleasedWhenClosed = false
        logo.level = .statusBar
        logo.backgroundColor = .clear
        logo.collectionBehavior = [.canJoinAllSpaces, .transient]
        //if pinOnScreen { logo.collectionBehavior = [.canJoinAllSpaces, .transient] }
        logo.setFrameOrigin(NSPoint(x: 15 + screen.frame.minX, y: screen.frame.minY + screen.frame.height - appleMenuBarHeight/2 - 12))
        logo.orderFront(nil)
    }
}

func getFullScreens() {
    var screenList = [NSRect]()
    if let windows = CGWindowListCopyWindowInfo([.excludeDesktopElements, .optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] {
        for window in windows {
            if getOwner(window) == "SystemUIServer" { continue }
            if let level = window[kCGWindowLayer as String] as? Int { if level != 0 { continue } }
            if let bounds = window[kCGWindowBounds as String] as? [String: CGFloat] {
                let windowRect = CGRect(x: bounds["X"] ?? 0, y: bounds["Y"] ?? 0, width: bounds["Width"] ?? 0, height: bounds["Height"] ?? 0)
                for screen in NSScreen.screens {
                    if windowRect.equalTo(screen.frame) { screenList.append(screen.frame) }
                }
            }
        }
    }
    if screenList != dataModel.fullScreens {
        if screenList.count < dataModel.fullScreens.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                maskLock = true
                refeshMask()
            }
        }
        dataModel.fullScreens = screenList
    }
}

func getOwner(_ w: [String: Any]) -> String {
    let name = w["kCGWindowOwnerName"] as? String ?? ""
    if name.contains("pid=") {
        guard let pid = w["kCGWindowOwnerPID"] as? Int else { return "" }
        for app in NSWorkspace.shared.runningApplications {
            if let name = app.localizedName, app.processIdentifier == pid {
                return name
            }
        }
    }
    return name
}

func getOrigin(of screen: NSScreen, in screens: [NSScreen]) -> NSPoint {
    if !screen.isMainScreen {
        if let mainScreen = screens.first(where: { $0.isMainScreen }) {
            let fullScreenRect = screens.reduce(NSRect.zero) { (result, screen) -> NSRect in result.union(screen.frame) }
            let screenFrame = screen.frame
            let mainScreenFrame = mainScreen.frame
            let originOffset = fullScreenRect.size.height
            let convertedMainOrigin = CGPoint(x: mainScreenFrame.origin.x, y: originOffset - mainScreenFrame.origin.y - mainScreenFrame.size.height)
            let convertedOrigin = CGPoint(x: screenFrame.origin.x, y: originOffset - screenFrame.origin.y - screenFrame.size.height)
            return NSPoint(x: convertedOrigin.x, y: convertedOrigin.y - convertedMainOrigin.y)
        }
    }
    return NSPoint(x: 0, y: 0)
}

func getMaskURL(index: Int) -> URL {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("mask\(index).png")
}

func tips(id: String, text: String) {
    let never = UserDefaults.standard.object(forKey: "neverRemindMe") as? [String] ?? []
    if !never.contains(id) {
        let alert = createAlert(title: "Logoer Tips".local, message: text.local, button1: "Don't remind me again", button2: "OK")
        if alert.runModal() == .alertFirstButtonReturn { UserDefaults.standard.setValue(never + [id], forKey: "neverRemindMe") }
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

func getMacDeviceType() -> String {
    guard let result = process(path: "/usr/sbin/system_profiler", arguments: ["SPHardwareDataType", "-json"]) else { return "Mac" }
    if let json = try? JSONSerialization.jsonObject(with: Data(result.utf8), options: []) as? [String: Any],
       let SPHardwareDataTypeRaw = json["SPHardwareDataType"] as? [Any],
       let SPHardwareDataType = SPHardwareDataTypeRaw[0] as? [String: Any],
       let model = SPHardwareDataType["machine_name"] as? String{
        return model
    }
    return "Mac"
}

public func process(path: String, arguments: [String], timeout: Double = 0) -> String? {
    let task = Process()
    task.launchPath = path
    task.arguments = arguments
    task.standardError = Pipe()
    
    let outputPipe = Pipe()
    defer { outputPipe.fileHandleForReading.closeFile() }
    task.standardOutput = outputPipe
    
    if timeout != 0 {
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(timeout)) {
            if task.isRunning { task.terminate() }
        }
    }
    
    do {
        try task.run()
    } catch let error {
        print("\(error.localizedDescription)")
        return nil
    }
    
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(decoding: outputData, as: UTF8.self)
    
    if output.isEmpty { return nil }
    
    return output.trimmingCharacters(in: .newlines)
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
    var displayID: CGDirectDisplayID? {
        return deviceDescription[NSDeviceDescriptionKey(rawValue: "NSScreenNumber")] as? CGDirectDisplayID
    }
    var isMainScreen: Bool {
        guard let id = self.displayID else { return false }
        return (CGDisplayIsMain(id) == 1)
    }
}

extension NSMenuItem {
    func performAction() {
        guard let menu else { return }
        menu.performActionForItem(at: menu.index(of: self))
    }
}

func randomEmoji(full: Bool = false) -> String {
    let characters = Array(full ? "😀😃😄😁😆😅😂🤣🥲🥹☺️😊😇🙂🙃😉😌😍🥰😘😗😙😚😋😛😝😜🤪🤨🧐🤓😎🥸🤩🥳🙂‍↕️😏😒🙂‍↔️😞😔😟😕🙁☹️😣😖😫😩🥺😢😭😮‍💨😤😠😡🤬🤯😳🥵🥶😱😨😰😥😓🫣🤗🫡🤔🫢🤭🤫🤥😶😶‍🌫️😐😑😬🫨🫠🙄😯😦😧😮😲🥱😴🤤😪😵😵‍💫🫥🤐🥴🤢🤮🤧😷🤒🤕🤑🤠😈👿👹👺🤡💩👻💀☠️👽👾🤖🎃😺😸😹😻😼😽🙀😿😾👋🤚🖐✋🖖👌🤌🤏✌️🤞🫰🤟🤘🤙🫵🫱🫲🫸🫷🫳🫴👈👉👆🖕👇☝️👍👎✊👊🤛🤜👏🫶🙌👐🤲🤝🙏✍️💅🤳💪🦾🦵🦿🦶👣👂🦻👃🫀🫁🧠🦷🦴👀👁👅👄🫦💋🩸👶👧🧒👦👩🧑👨👩‍🦱🧑‍🦱👨‍🦱👩‍🦰🧑‍🦰👨‍🦰👱‍♀️👱👱‍♂️👩‍🦳🧑‍🦳👨‍🦳👩‍🦲🧑‍🦲👨‍🦲🧔‍♀️🧔🧔‍♂️👵🧓👴👲👳‍♀️👳👳‍♂️🧕👮‍♀️👮👮‍♂️👷‍♀️👷👷‍♂️💂‍♀️💂💂‍♂️🕵️‍♀️🕵️🕵️‍♂️👩‍⚕️🧑‍⚕️👨‍⚕️👩‍🌾🧑‍🌾👨‍🌾👩‍🍳🧑‍🍳👨‍🍳👩‍🎓🧑‍🎓👨‍🎓👩‍🎤🧑‍🎤👨‍🎤👩‍🏫🧑‍🏫👨‍🏫👩‍🏭🧑‍🏭👨‍🏭👩‍💻🧑‍💻👨‍💻👩‍💼🧑‍💼👨‍💼👩‍🔧🧑‍🔧👨‍🔧👩‍🔬🧑‍🔬👨‍🔬👩‍🎨🧑‍🎨👨‍🎨👩‍🚒🧑‍🚒👨‍🚒👩‍✈️🧑‍✈️👨‍✈️👩‍🚀🧑‍🚀👨‍🚀👩‍⚖️🧑‍⚖️👨‍⚖️👰‍♀️👰👰‍♂️🤵‍♀️🤵🤵‍♂️👸🫅🤴🥷🦸‍♀️🦸🦸‍♂️🦹‍♀️🦹🦹‍♂️🤶🧑‍🎄🎅🧙‍♀️🧙🧙‍♂️🧝‍♀️🧝🧝‍♂️🧛‍♀️🧛🧛‍♂️🧟‍♀️🧟🧟‍♂️🧞‍♀️🧞🧞‍♂️🧜‍♀️🧜🧜‍♂️🧚‍♀️🧚🧚‍♂️🧌👼🤰🫄🫃🤱👩‍🍼🧑‍🍼👨‍🍼🙇‍♀️🙇🙇‍♂️💁‍♀️💁💁‍♂️🙅‍♀️🙅🙅‍♂️🙆‍♀️🙆🙆‍♂️🙋‍♀️🙋🙋‍♂️🧏‍♀️🧏🧏‍♂️🤦‍♀️🤦🤦‍♂️🤷‍♀️🤷🤷‍♂️🙎‍♀️🙎🙎‍♂️🙍‍♀️🙍🙍‍♂️💇‍♀️💇💇‍♂️💆‍♀️💆💆‍♂️🧖‍♀️🧖🧖‍♂️💅🤳💃🕺👯‍♀️👯👯‍♂️🕴👩‍🦽👩‍🦽‍➡️🧑‍🦽🧑‍🦽‍➡️👨‍🦽👨‍🦽‍➡️👩‍🦼👩‍🦼‍➡️🧑‍🦼🧑‍🦼‍➡️👨‍🦼👨‍🦼‍➡️🚶‍♀️🚶‍♀️‍➡️🚶🚶‍➡️🚶‍♂️🚶‍♂️‍➡️👩‍🦯👩‍🦯‍➡️🧑‍🦯🧑‍🦯‍➡️👨‍🦯👨‍🦯‍➡️🧎‍♀️🧎‍♀️‍➡️🧎🧎‍➡️🧎‍♂️🧎‍♂️‍➡️🏃‍♀️🏃‍♀️‍➡️🏃🏃‍➡️🏃‍♂️🏃‍♂️‍➡️🧍‍♀️🧍🧍‍♂️👭🧑‍🤝‍🧑👬👫👩‍❤️‍👩💑👨‍❤️‍👨👩‍❤️‍👨👩‍❤️‍💋‍👩💏👨‍❤️‍💋‍👨👩‍❤️‍💋‍👨👪👨‍👩‍👦👨‍👩‍👧👨‍👩‍👧‍👦👨‍👩‍👦‍👦👨‍👩‍👧‍👧👨‍👨‍👦👨‍👨‍👧👨‍👨‍👧‍👦👨‍👨‍👦‍👦👨‍👨‍👧‍👧👩‍👩‍👦👩‍👩‍👧👩‍👩‍👧‍👦👩‍👩‍👦‍👦👩‍👩‍👧‍👧👨‍👦👨‍👦‍👦👨‍👧👨‍👧‍👦👨‍👧‍👧👩‍👦👩‍👦‍👦👩‍👧👩‍👧‍👦👩‍👧‍👧🧑‍🧑‍🧒🧑‍🧑‍🧒‍🧒🧑‍🧒🧑‍🧒‍🧒🗣👤👥🫂🧳🌂☂️🧵🪡🪢🪭🧶👓🕶🥽🥼🦺👔👕👖🧣🧤🧥🧦👗👘🥻🩴🩱🩲🩳👙👚👛👜👝🎒👞👟🥾🥿👠👡🩰👢👑👒🎩🎓🧢⛑🪖💄💍💼🐶🐱🐭🐹🐰🦊🐻🐼🐻‍❄️🐨🐯🦁🐮🐷🐽🐸🐵🙈🙉🙊🐒🐔🐧🐦🐦‍⬛🐤🐣🐥🦆🦅🦉🦇🐺🐗🐴🦄🐝🪱🐛🦋🐌🐞🐜🪰🪲🪳🦟🦗🕷🕸🦂🐢🐍🦎🦖🦕🐙🦑🦐🦞🦀🪼🪸🐡🐠🐟🐬🐳🐋🦈🐊🐅🐆🦓🫏🦍🦧🦣🐘🦛🦏🐪🐫🦒🦘🦬🐃🐂🐄🐎🐖🐏🐑🦙🐐🦌🫎🐕🐩🦮🐕‍🦺🐈🐈‍⬛🪽🪶🐓🦃🦤🦚🦜🦢🪿🦩🕊🐇🦝🦨🦡🦫🦦🦥🐁🐀🐿🦔🐾🐉🐲🐦‍🔥🌵🎄🌲🌳🌴🪹🪺🪵🌱🌿☘️🍀🎍🪴🎋🍃🍂🍁🍄🍄‍🟫🐚🪨🌾💐🌷🪷🌹🥀🌺🌸🪻🌼🌻🌞🌝🌛🌜🌚🌕🌖🌗🌘🌑🌒🌓🌔🌙🌎🌍🌏🪐💫⭐️🌟✨⚡️☄️💥🔥🌪🌈☀️🌤⛅️🌥☁️🌦🌧⛈🌩🌨❄️☃️⛄️🌬💨💧💦🫧☔️☂️🌊🍏🍎🍐🍊🍋🍋‍🟩🍌🍉🍇🍓🫐🍈🍒🍑🥭🍍🥥🥝🍅🍆🥑🥦🫛🥬🥒🌶🫑🌽🥕🫒🧄🧅🫚🥔🍠🫘🥐🥯🍞🥖🥨🧀🥚🍳🧈🥞🧇🥓🥩🍗🍖🦴🌭🍔🍟🍕🫓🥪🥙🧆🌮🌯🫔🥗🥘🫕🥫🍝🍜🍲🍛🍣🍱🥟🦪🍤🍙🍚🍘🍥🥠🥮🍢🍡🍧🍨🍦🥧🧁🍰🎂🍮🍭🍬🍫🍿🍩🍪🌰🥜🍯🥛🍼🫖☕️🍵🧃🥤🧋🫙🍶🍺🍻🥂🍷🫗🥃🍸🍹🧉🍾🧊🥄🍴🍽🥣🥡🥢🧂⚽️🏀🏈⚾️🥎🎾🏐🏉🥏🎱🪀🏓🏸🏒🏑🥍🏏🪃🥅⛳️🪁🏹🎣🤿🥊🥋🎽🛹🛼🛷⛸🥌🎿⛷🏂🪂🏋️‍♀️🏋️🏋️‍♂️🤼‍♀️🤼🤼‍♂️🤸‍♀️🤸🤸‍♂️⛹️‍♀️⛹️⛹️‍♂️🤺🤾‍♀️🤾🤾‍♂️🏌️‍♀️🏌️🏌️‍♂️🏇🧘‍♀️🧘🧘‍♂️🏄‍♀️🏄🏄‍♂️🏊‍♀️🏊🏊‍♂️🤽‍♀️🤽🤽‍♂️🚣‍♀️🚣🚣‍♂️🧗‍♀️🧗🧗‍♂️🚵‍♀️🚵🚵‍♂️🚴‍♀️🚴🚴‍♂️🏆🥇🥈🥉🏅🎖🏵🎗🎫🎟🎪🤹🤹‍♂️🤹‍♀️🎭🩰🎨🎬🎤🎧🎼🎹🥁🪘🪇🎷🎺🪗🎸🪕🎻🪈🎲♟🎯🎳🎮🎰🧩🚗🚕🚙🚌🚎🏎🚓🚑🚒🚐🛻🚚🚛🚜🦯🦽🦼🛴🚲🛵🏍🛺🚨🚔🚍🚘🚖🛞🚡🚠🚟🚃🚋🚞🚝🚄🚅🚈🚂🚆🚇🚊🚉✈️🛫🛬🛩💺🛰🚀🛸🚁🛶⛵️🚤🛥🛳⛴🚢⚓️🛟🪝⛽️🚧🚦🚥🚏🗺🗿🗽🗼🏰🏯🏟🎡🎢🛝🎠⛲️⛱🏖🏝🏜🌋⛰🏔🗻🏕⛺️🛖🏠🏡🏘🏚🏗🏭🏢🏬🏣🏤🏥🏦🏨🏪🏫🏩💒🏛⛪️🕌🕍🛕🕋⛩🛤🛣🗾🎑🏞🌅🌄🌠🎇🎆🌇🌆🏙🌃🌌🌉🌁⌚️📱📲💻⌨️🖥🖨🖱🖲🕹🗜💽💾💿📀📼📷📸📹🎥📽🎞📞☎️📟📠📺📻🎙🎚🎛🧭⏱⏲⏰🕰⌛️⏳📡🔋🪫🔌💡🔦🕯🪔🧯🛢🛍️💸💵💴💶💷🪙💰💳💎⚖️🪮🪜🧰🪛🔧🔨⚒🛠⛏🪚🔩⚙️🪤🧱⛓⛓️‍💥🧲🔫💣🧨🪓🔪🗡⚔️🛡🚬⚰️🪦⚱️🏺🔮📿🧿🪬💈⚗️🔭🔬🕳🩹🩺🩻🩼💊💉🩸🧬🦠🧫🧪🌡🧹🪠🧺🧻🚽🚰🚿🛁🛀🧼🪥🪒🧽🪣🧴🛎🔑🗝🚪🪑🛋🛏🛌🧸🪆🖼🪞🪟🛍🛒🎁🎈🎏🎀🪄🪅🎊🎉🪩🎎🏮🎐🧧✉️📩📨📧💌📥📤📦🏷🪧📪📫📬📭📮📯📜📃📄📑🧾📊📈📉🗒🗓📆📅🗑🪪📇🗃🗳🗄📋📁📂🗂🗞📰📓📔📒📕📗📘📙📚📖🔖🧷🔗📎🖇📐📏🧮📌📍✂️🖊🖋✒️🖌🖍📝✏️🔍🔎🔏🔐🔒🔓❤️🩷🧡💛💚💙🩵💜🖤🩶🤍🤎❤️‍🔥❤️‍🩹💔❣️💕💞💓💗💖💘💝💟☮️✝️☪️🪯🕉☸️✡️🔯🕎☯️☦️🛐⛎♈️♉️♊️♋️♌️♍️♎️♏️♐️♑️♒️♓️🆔⚛️🉑☢️☣️📴📳🈶🈚️🈸🈺🈷️✴️🆚💮🉐㊙️㊗️🈴🈵🈹🈲🅰️🅱️🆎🆑🅾️🆘❌⭕️🛑⛔️📛🚫💯💢♨️🚷🚯🚳🚱🔞📵🚭❗️❕❓❔‼️⁉️🔅🔆〽️⚠️🚸🔱⚜️🔰♻️✅🈯️💹❇️✳️❎🌐💠Ⓜ️🌀💤🏧🚾♿️🅿️🛗🈳🈂️🛂🛃🛄🛅🚹🚺🚼⚧🚻🚮🎦🛜📶🈁🔣ℹ️🔤🔡🔠🆖🆗🆙🆒🆕🆓0️⃣1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣8️⃣9️⃣🔟🔢#️⃣*️⃣⏏️▶️◀️🔼🔽➡️⬅️⬆️⬇️↗️↘️↙️↖️↕️↔️↪️↩️⤴️⤵️🔀🔁🔂🔄🔃🎵🎶➕➖➗✖️🟰♾💲💱™️©️®️〰️➰➿🔚🔙🔛🔝🔜✔️☑️🔘🔴🟠🟡🟢🔵🟣⚫️⚪️🟤🔺🔻🔸🔹🔶🔷🔳🔲▪️▫️◾️◽️◼️◻️🟥🟧🟨🟩🟦🟪⬛️⬜️🟫🔈🔇🔉🔊🔔🔕📣📢👁‍🗨💬💭🗯♠️♣️♥️♦️🃏🎴🀄️🕐🕑🕒🕓🕔🕕🕖🕗🕘🕙🕚🕛🕜🕝🕞🕟🕠🕡🕢🕣🕤🕥🕦🕧" : "😀😃😄😁😆😅😂🤣🥲🥹☺️😊😇🙂🙃😉😌😍🥰😘😗😙😚😋😛😝😜🤪🤨🧐🤓😎🥸🤩🥳🙂‍↕️😏😒🙂‍↔️😞😔😟😕🙁☹️😣😖😫😩🥺😢😭😮‍💨😤😠😡🤬🤯😳🥵🥶😱😨😰😥😓🫣🤗🤔🫢🤭🤫🤥😶😶‍🌫️😐😑😬🫨🫠🙄😯😦😧😮😲🥱😴🤤😪😵😵‍💫🤐🥴🤢🤮🤧😷🤒🤕🤑🤠😈👿🤡👽🤖🎃👹🌞🌝🌚🌕🌖🌗🌘🌑🌒🌓🌔🌎🌍🌏🌼🌺🌸🐵🦧🪨🍏🍎🍑🫑🍞🍔🍟🍚🍘🍥🧁🍱🍩🍪🌰🥡⚽️🏀🏈⚾️🥎🎾🏐🎱🎲🏵🎹🎰🚌🚑🚛🚞🚨🚔🚍🚖🚆🗺🗾🎑🏞🌅🌄🌠🎇🎆🌇🌆🏙🌃🌌🌉🌁🏨🏪🏩🏛🏠🏚🏢🏬🏣🏤🏥🏦⌚️💻🖲💽💾💿📀🎛🧭📺📟☎️⏰🕰🩻🔮🧿🪙🛎🖼🎁📦🪩📜📄📑🧾📊📈📉🗒🗓📆📅🗄📋📰📓📔📒📕📗📘📙📚📝💟☮️✝️☪️🪯🕉☸️✡️🔯🕎☯️☦️🛐⛎♈️♉️♊️♋️♌️♍️♎️♏️♐️♑️♒️♓️🆔⚛️🉑☢️☣️📴📳🈶🈚️🈸🈺🈷️✴️🆚💮🉐㊙️㊗️🈴🈵🈹🈲🅰️🅱️🆎🆑🅾️🆘🛑⛔️🚷🚯🚳🚱🔞📵🚭✅🈯️💹❇️✳️❎🌐Ⓜ️🏧🚾♿️🅿️🛗🈳🈂️🛂🛃🛄🛅🚹🚺🚼🚻🚮🎦🛜📶🈁🔣ℹ️🔤🔡🔠🆖🆗🆙🆒🆕🆓0️⃣1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣8️⃣9️⃣🔟🔢#️⃣*️⃣⏏️▶️⏩⏪⏫⏬◀️🔼🔽➡️⬅️⬆️⬇️↗️↘️↙️↖️↕️↔️↪️↩️⤴️⤵️🔀🔁🔂🔄🔃☑️🔘🔴🟠🟡🟢🔵🟣⚫️⚪️🟤🔳🔲🟥🟧🟨🟩🟦🟪⬛️⬜️🟫🕐🕑🕒🕓🕔🕕🕖🕗🕘🕙🕚🕛🕜🕝🕞🕟🕠🕡🕢🕣🕤🕥🕦🕧")
    if let randomString = characters.shuffled().first { return String(randomString) }
    return "🍎"
}
