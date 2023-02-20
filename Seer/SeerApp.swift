//
//  SeerApp.swift
//  Seer
//
//  Created by Jacob Davis on 2/2/23.
//

import SwiftUI
import SDWebImageSVGCoder

@main
struct SeerApp: App {
    
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject var appState = AppState.shared
    @StateObject var navigation = Navigation()
    
    static let defaultSize = CGSize(width: 960, height: 640)
    
    var body: some Scene {
        WindowGroup {
            #if os(macOS)
            DesktopMainView()
                .frame(minWidth: SeerApp.defaultSize.width, minHeight: SeerApp.defaultSize.height)
                .environmentObject(appState)
                .environmentObject(navigation)
                .task {
                    await appState.connectRelays()
                }
            #else
            Text("Hello iOS")
            #endif
        }
        .commands {
            CommandGroup(replacing: .newItem) {} //remove "New Item"-menu entry
        }
        .defaultSize(SeerApp.defaultSize)
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified(showsTitle: true))
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                print("👁️ Seer => Entered Background Phase")
            case .active:
                print("👁️ Seer => Entered Active Phase")
                // MACOS - Window start/not in dock
            case .inactive:
                print("👁️ Seer => Entered Inactive Phase")
                // MACOS - Window in dock
            default:
                print("👁️ Seer => Entered Unknown Phase")
            }
        }
        
        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
        #endif
    }
}

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        SDImageCodersManager.shared.addCoder(SDImageSVGCoder.shared)
        let _ = NSApplication.shared.windows.map { $0.tabbingMode = .disallowed }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
#elseif os(iOS)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        SDImageCodersManager.shared.addCoder(SDImageSVGCoder.shared)
        return true
    }
}
#endif
