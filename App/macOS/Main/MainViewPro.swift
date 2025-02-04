// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import CoreData
import PulseCore
import Combine

var isSelfDestructNeeded: Bool {
    #warning("TODO: remove when not needed")
    return Date() > Date(timeIntervalSince1970: 1646779235)
}

func printNextTimeInterval() {
    let ti = Calendar.current.date(byAdding: .init(day: 365), to: Date())?.timeIntervalSince1970
    print(ti)
}

struct SelfDestructView: View {
    let isTrial: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "flame")
                .font(.system(size: 120))
                .foregroundColor(.secondary)
            VStack(alignment: .center, spacing: 20) {
                Text("This build self-destructed")
                    .font(.title)
                
                if !isTrial {
                    Text("This is an early preview of the Pulse Pro app. It expired after 365 days in production. Please install a new build.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                    Button("Get Build") {
                        NSWorkspace.shared.open(URL(string: "https://github.com/kean/PulsePro")!)
                    }
                } else {
                    Text("The 30 day trial period has expired.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}

struct MainViewPro: View {
    @StateObject private var model = MainViewModelPro()
    @StateObject private var commands = CommandsRegistryWrapper()
    private let hasSiderbar: Bool

    init() {
        self.hasSiderbar = true
        _model = StateObject(wrappedValue: MainViewModelPro())
    }
    
    init(store: LoggerStore) {
        self.hasSiderbar = false
        _model = StateObject(wrappedValue: MainViewModelPro(store: store))
    }
    
    init(client: RemoteLoggerClient) {
        self.hasSiderbar = false
        _model = StateObject(wrappedValue: MainViewModelPro(client: client))
    }
    
    var body: some View {
        if isTrialExpired {
            SelfDestructView(isTrial: true)
        } else {
            contents
                .background(MainViewWindowAccessor(model: model, commands: commands.commands))
        }
    }
    
    @ViewBuilder
    private var contents: some View {
        if hasSiderbar {
            NavigationView {
                SidebarView(model: model)
                    .environmentObject(commands)
                MainViewRouter(details: model.details)
                    .environmentObject(commands)
            }
        } else {
            MainViewRouter(details: model.details)
                .environmentObject(commands)
        }
    }
}

// We need to be able to pass it around as StateObjct and EnvironmentObject,
// but it doesn't need to trigger view updates.
final class CommandsRegistryWrapper: ObservableObject {
    let commands = CommandsRegistry2()
}

private struct MainViewWindowAccessor: View {
    let model: MainViewModelPro
    let commands: CommandsRegistry2
    @State private var window: NSWindow?
    
    var body: some View {
        EmptyView()
            .background(WindowAccessor(window: $window))
            .onChange(of: window) {
                guard let window = $0 else { return }
                WindowManager.shared.add(commands: commands, for: window)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { notification in
                if (notification.object as? NSWindow) === window {
                    model.didCloseWindow()
                }
            }
    }
}

private struct MainViewRouter: View {
    @ObservedObject var details: MainViewDetailsViewModel
    
    var body: some View {
        if let model = details.model {
            ConsoleContainerView(model: model)
                .id(ObjectIdentifier(model))
        } else {
            AppWelcomeView(buttonOpenDocumentTapped: openDocument, openDocument: details.open)
        }
    }
}

private struct SidebarView: View {
    private var model: MainViewModelPro

    init(model: MainViewModelPro) {
        self.model = model
    }

    var body: some View {
        SiderbarViewPro(model: model, remote: .shared)
            .frame(minWidth: 150)
            .toolbar {
                ToolbarItem(placement: ToolbarItemPlacement.status) {
                    Button(action: toggleSidebar) {
                        Label("Back", systemImage: "sidebar.left")
                    }
                }
            }
    }
}

private func toggleSidebar() {
    NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
}

#if DEBUG
struct MainViewPro_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MainViewPro()
                .previewLayout(.fixed(width: 1200, height: 800))
            
            MainViewPro(store: .mock)
                .previewLayout(.fixed(width: 900, height: 400))
        }
    }
}
#endif
