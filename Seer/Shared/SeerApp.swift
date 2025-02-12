//
//  SeerApp.swift
//  Seer
//
//  Created by Jacob Davis on 3/26/24.
//

import SwiftUI
import SwiftData
import Nostr
import NostrClient

@main
struct SeerApp: App {
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            OwnerAccount.self,
            Relay.self,
            PublicKeyMetadata.self,
            ChatMessage.self,
            Group.self,
            GroupMember.self,
            GroupAdmin.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @StateObject var appState = AppState.shared
    
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#elseif os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif
    
    @Environment(\.scenePhase) var scenePhase
    
    @StateObject var nostrClient = NostrClient()
    
    static let defaultSize = CGSize(width: 960, height: 640)
    
    var body: some Scene {
        WindowGroup {
#if os(macOS)
            MacOSRootView()
                .environmentObject(appState)
                .task {
                    //appState.modelContainer = PreviewData.container
                    appState.modelContainer = sharedModelContainer
                    await appState.initialSetup()
                    await appState.connectAllNip29Relays()
                    await appState.connectAllMetadataRelays()
                }
#else
            RootView()
                .environmentObject(appState)
                .task {
                    appState.modelContainer = sharedModelContainer
                    appState.connectAllNip29Relays()
                    appState.connectAllMetadataRelays()
                }
#endif
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(SeerApp.defaultSize)
#if os(macOS)
        .windowStyle(.automatic)
        .windowToolbarStyle(.unifiedCompact)
#endif
        .onChange(of: scenePhase, { oldPhase, newPhase in
            switch newPhase {
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
        })
        
#if os(macOS)
        Settings {
            MacOSSettingsView()
                .modelContainer(sharedModelContainer)
                .environmentObject(appState)
        }
#endif
        
    }
    
}

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        //SDImageCodersManager.shared.addCoder(SDImageSVGCoder.shared)
        
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
        //SDImageCodersManager.shared.addCoder(SDImageSVGCoder.shared)
        return true
    }
}
#endif
