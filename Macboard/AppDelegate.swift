import SwiftUI
import Cocoa
import KeyboardShortcuts
import Settings
import Defaults
import Sparkle
import UserNotifications

let UPDATE_NOTIFICATION_IDENTIFIER = "UpdateCheck"

class AppDelegate: NSObject, NSApplicationDelegate, SPUUpdaterDelegate, SPUStandardUserDriverDelegate, UNUserNotificationCenterDelegate {
    
    @IBOutlet var updaterController: SPUStandardUpdaterController!
    
    private var statusItem: NSStatusItem!
    var popover: NSPopover!
    var didShowObserver: AnyObject?
    var didCloseObserver: AnyObject?
    var popoverFocused: Bool = false
    
    let GeneralSettingsViewController: () -> SettingsPane = {
        let paneView = Settings.Pane(
            identifier: .general,
            title: "General",
            toolbarIcon: NSImage(systemSymbolName: "gearshape", accessibilityDescription: "General Settings")!
        ) {
            GeneralSettingsView()
        }
        
        return Settings.PaneHostingController(pane: paneView)
    }
    let StorageSettingsViewController: () -> SettingsPane = {
        let paneView = Settings.Pane(
            identifier: .storage,
            title: "Storage",
            toolbarIcon: NSImage(systemSymbolName: "externaldrive", accessibilityDescription: "Storage Settings")!
        ) {
            StorageSettingsView()
        }
        
        return Settings.PaneHostingController(pane: paneView)
    }
    let KeyboardSettingsViewController: () -> SettingsPane = {
        let paneView = Settings.Pane(
            identifier: .keyboard,
            title: "Keyboard",
            toolbarIcon: NSImage(systemSymbolName: "command", accessibilityDescription: "Keyboard Settings")!
        ) {
            KeyboardSettingsView()
        }
        
        return Settings.PaneHostingController(pane: paneView)
    }
    let LANSyncSettingsViewController: () -> SettingsPane = {
        let paneView = Settings.Pane(
            identifier: .lanSync,
            title: "LAN Sync",
            toolbarIcon: NSImage(systemSymbolName: "wifi", accessibilityDescription: "LAN Sync Settings")!
        ) {
            LANSyncSettingsView()
        }
        
        return Settings.PaneHostingController(pane: paneView)
    }
    let AboutSettingsViewController: () -> SettingsPane = {
        let paneView = Settings.Pane(
            identifier: .about,
            title: "About",
            toolbarIcon: NSImage(systemSymbolName: "info.circle", accessibilityDescription: "About Macboard")!
        ) {
            AboutSettingsView()
        }
        
        return Settings.PaneHostingController(pane: paneView)
    }
    
    @MainActor func applicationDidFinishLaunching(_ notification: Notification) {
        let rootView = ClipboardItemListView(appDelegate: self).environment(\.managedObjectContext, PersistanceController.shared.container.viewContext)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusButton = statusItem.button {
            statusButton.image = NSImage(systemSymbolName: Defaults[.menubarIcon].rawValue, accessibilityDescription: "Macboard")
            statusButton.action = #selector(togglePopover)
        }
        
        KeyboardShortcuts.onKeyUp(for: .toggleMacboard) { [self] in
            self.togglePopover()
        }
        self.popover = NSPopover()
        self.popover.contentSize = NSSize(width: 700, height: 500)
        self.popover.behavior = .transient
        self.popover.contentViewController = NSHostingController(rootView: rootView)
        didCloseObserver = NotificationCenter.default.addObserver(forName: NSPopover.didCloseNotification, object: nil, queue: .main) { [weak self] _ in
            self?.popoverDidClose()
        }
        didShowObserver = NotificationCenter.default.addObserver(forName: NSPopover.didShowNotification, object: popover, queue: .main) { [weak self] _ in
            self?.popoverDidAppear()
        }
        
        UNUserNotificationCenter.current().delegate = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !self.popover.isShown {
                self.togglePopover()
            }
        }
        
        // 根据设置启动局域网同步服务
        if Defaults[.lanSyncEnabled] {
            LocalSyncServer.shared.port = Defaults[.lanSyncPort]
            LocalSyncServer.shared.start()
        }
    }
    
    func updater(_ updater: SPUUpdater, willScheduleUpdateCheckAfterDelay delay: TimeInterval) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { granted, error in
        }
    }
    
    var supportsGentleScheduledUpdateReminders: Bool {
        return true
    }
    
    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
        NSApp.setActivationPolicy(.regular)
        
        if !state.userInitiated {
            NSApp.dockTile.badgeLabel = "1"
            
            do {
                let content = UNMutableNotificationContent()
                content.title = "A new update is available"
                content.body = "Version \(update.displayVersionString) is now available"
                
                let request = UNNotificationRequest(identifier: UPDATE_NOTIFICATION_IDENTIFIER, content: content, trigger: nil)
                
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    
    func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        NSApp.dockTile.badgeLabel = ""
        
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [UPDATE_NOTIFICATION_IDENTIFIER])
    }
    
    func standardUserDriverWillFinishUpdateSession() {
        NSApp.setActivationPolicy(.accessory)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.identifier == UPDATE_NOTIFICATION_IDENTIFIER && response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            updaterController.checkForUpdates(nil)
        }
        
        completionHandler()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let didCloseObserver = didCloseObserver {
            NotificationCenter.default.removeObserver(didCloseObserver)
        }
        // 停止局域网同步服务
        LocalSyncServer.shared.stop()
    }
    
    func popoverDidAppear() {
        popoverFocused = true
    }
    
    func popoverDidClose() {
        popoverFocused = false
    }
    
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                self.popover.performClose(nil)
                NSApp.hide(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                NSApp.activate(ignoringOtherApps: true)
                
                // 如果开启了自动复制最新，则复制最新一条到系统剪贴板
                if Defaults[.autoCopyLatestOnWake] {
                    copyLatestItemToClipboard()
                }
            }
        }
    }
    
    @objc func openSettings() {
        SettingsWindowController(
            panes: [
                GeneralSettingsViewController(),
                StorageSettingsViewController(),
                KeyboardSettingsViewController(),
                LANSyncSettingsViewController(),
                AboutSettingsViewController()
            ],
            style: .toolbarItems,
            animated: true,
            hidesToolbarForSingleItem: true
        ).show()
    }
    
    /// 复制最新的剪贴板项到系统剪贴板
    private func copyLatestItemToClipboard() {
        let context = PersistanceController.shared.container.viewContext
        let fetchRequest = ClipboardItem.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \ClipboardItem.isPinned, ascending: false),
            NSSortDescriptor(keyPath: \ClipboardItem.createdAt, ascending: false)
        ]
        fetchRequest.fetchLimit = 1
        
        do {
            let items = try context.fetch(fetchRequest)
            if let latestItem = items.first {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                
                if latestItem.contentType == "Text", let content = latestItem.content {
                    pasteboard.setString(content, forType: .string)
                } else if latestItem.contentType == "Image", let imageData = latestItem.imageData {
                    if let image = NSImage(data: imageData) {
                        pasteboard.writeObjects([image])
                    }
                }
            }
        } catch {
            print("[AppDelegate] 获取最新剪贴板项失败: \(error)")
        }
    }
    
}
