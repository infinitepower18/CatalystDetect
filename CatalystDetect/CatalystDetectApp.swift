//
//  CatalystDetectApp.swift
//  CatalystDetect
//
//  Created by Ahnaf Mahmud on 07/02/2025.
//

import SwiftUI

@main
struct CatalystDetectApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 350, minHeight: 300)
        }
        .windowResizabilityContentSize()
        .commands {
            CommandGroup(replacing: .help) {
                Button {
                    let url = "https://github.com/infinitepower18/CatalystDetect"
                    NSWorkspace.shared.open(URL(string: url)!)
                } label: {
                    Text("GitHub")
                }
            }
            CommandGroup(after: .appInfo) {
                Button {
                    let url = "https://github.com/infinitepower18/CatalystDetect/releases/latest"
                    NSWorkspace.shared.open(URL(string: url)!)
                } label: {
                    Text("Check for Updates...")
                }
            }
        }
    }
}

extension Scene {
    func windowResizabilityContentSize() -> some Scene {
        if #available(macOS 13.0, *) {
            return windowResizability(.contentSize)
        } else {
            return self
        }
    }
}
