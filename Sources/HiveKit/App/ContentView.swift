import AppKit
import SwiftUI

struct ContentView: View {
    @Bindable var store: WorkspaceStore

    var body: some View {
        VStack(spacing: 0) {
            topStrip
            Rectangle().fill(Theme.chromeHairline).frame(height: 1)
            HStack(spacing: 0) {
                if store.sidebarMode != .hidden {
                    SidebarView(store: store)
                    Rectangle().fill(Theme.chromeHairline).frame(width: 1)
                }
                mainPane
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transaction { $0.animation = nil }
                switch store.rightPanel {
                case .fileBrowser:
                    Rectangle().fill(Theme.chromeHairline).frame(width: 1)
                    FileBrowserPanel(store: store)
                        .frame(width: 260)
                case .gitChanges:
                    if let session = store.active?.activeSession {
                        Rectangle().fill(Theme.chromeHairline).frame(width: 1)
                        GitChangesPanel(session: session, store: store)
                            .frame(width: 320)
                    }
                case .hidden:
                    EmptyView()
                }
            }
        }
        .background(chromeBackground)
        .ignoresSafeArea(.all)
    }

    /// Top 32pt strip. `window.isMovable = false` is set globally, so this
    /// `WindowDragHandle` is the only place AppKit allows window dragging.
    private var topStrip: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 82).allowsHitTesting(false)
            HoverableIconButton(
                systemName: "sidebar.left",
                fontSize: 12,
                size: 28,
                help: sidebarTooltip
            ) {
                withAnimation(Theme.chromeTransition) {
                    store.setSidebarMode(store.sidebarMode.next)
                }
            }
            WindowDragHandle()
            if let session = store.active?.activeSession,
               session.gitStatus.branch != nil, session.gitStatus.filesChanged > 0 {
                HoverableIconButton(
                    systemName: "arrow.triangle.branch",
                    fontSize: 12,
                    size: 28,
                    help: store.rightPanel == .gitChanges ? "Hide git changes" : "Show git changes"
                ) {
                    withAnimation(Theme.chromeTransition) {
                        store.rightPanel = store.rightPanel == .gitChanges ? .hidden : .gitChanges
                    }
                }
            }
            HoverableIconButton(
                systemName: "sidebar.trailing",
                fontSize: 12,
                size: 28,
                help: store.rightPanel == .fileBrowser ? "Hide file browser" : "Show file browser"
            ) {
                withAnimation(Theme.chromeTransition) {
                    store.rightPanel = store.rightPanel == .fileBrowser ? .hidden : .fileBrowser
                }
            }
            .padding(.trailing, Theme.space2)
        }
        .frame(height: 32)
    }

    @ViewBuilder
    private var mainPane: some View {
        if let workspace = store.active {
            PaneTreeView(node: workspace.root, workspace: workspace, store: store)
                .id(workspace.id)
        } else {
            Color.clear
        }
    }

    private var chromeBackground: Color {
        let color = store.active?.activeSession?.engine.backgroundColor ?? Theme.terminalSurface
        return Color(nsColor: color)
    }

    private var sidebarTooltip: String {
        switch store.sidebarMode {
        case .full: return "Compact sidebar"
        case .compact: return "Hide sidebar"
        case .hidden: return "Show sidebar"
        }
    }
}
