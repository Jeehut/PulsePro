//
//  AppDelegate.swift
//  macOS
//
//  Created by Alexander Grebenyuk on 16.02.2020.
//  Copyright © 2020 kean. All rights reserved.
//

import Cocoa
import Pulse
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, AppViewModelDelegate {

    var window: NSWindow!

    let model = AppViewModel()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        model.delegate = self

        showWelcomeView()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // MARK: - App Menu

    @IBAction func openDocument(_ sender: Any) {
        self.openDocument()
    }

    func openDocument() {
        let dialog = NSOpenPanel()

        dialog.title = "Choose a .sqlite file with logs"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.canChooseDirectories = false
        dialog.canCreateDirectories = false
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes = ["sqlite"];

        #warning("TODO: open recent is not working")

        guard dialog.runModal() == NSApplication.ModalResponse.OK else {
            return // User cancelled the action
        }

        if let selectedUrl = dialog.url {
            model.openDatabase(url: selectedUrl)
        }
    }

    func showConsole(model: ConsoleViewModel) {
        let contentView = ConsoleView(model: model)

        #warning("TODO: improve preferred window/panels size")
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Console Window")
        window.contentView = NSHostingView(rootView: contentView)

        let toolbar = NSToolbar(identifier: "console.toolbar")
        toolbar.delegate = model
        window.toolbar = toolbar

        window.makeKeyAndOrderFront(nil)
    }

    func showWelcomeView() {
        let contentView = AppWelcomeView(buttonOpenDocumentTapped: { [weak self] in
            self?.openDocument()
        }).frame(minWidth: 320, minHeight: 320)

        #warning("TODO: open window not on top of the existing one")
        #warning("TODO: close welcome screen when opening a console")
        #warning("TODO: show a welcome when closing all of the windows")
        #warning("TODO: add title to each window")
        #warning("TODO: add support for tabs instead of windows")
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)

        window.makeKeyAndOrderFront(nil)
    }
}
