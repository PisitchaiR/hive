import AppKit
import SwiftUI

/// ⌘P command palette — fuzzy-search workspaces, tabs, and agents.
struct QuickOpenView: View {
    @Bindable var store: WorkspaceStore
    @State private var query: String = ""
    @State private var selectedIndex: Int = 0
    @FocusState private var queryFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { dismiss() }
            panel
        }
        .onAppear {
            query = ""
            selectedIndex = 0
            queryFocused = true
        }
    }

    private var panel: some View {
        VStack(spacing: 0) {
            TextField("Search workspaces, tabs, agents…", text: $query)
                .textFieldStyle(.plain)
                .font(Theme.display(14, weight: .medium))
                .foregroundStyle(Theme.chromeForeground)
                .focused($queryFocused)
                .padding(.horizontal, Theme.space4)
                .padding(.vertical, Theme.space3)
                .onChange(of: query) { _, _ in selectedIndex = 0 }
                .onSubmit(activateSelected)

            Rectangle().fill(Theme.chromeHairline).frame(height: 1)

            resultsList
        }
        .frame(width: 580, height: 420)
        .background(Theme.chromeBackground)
        .bracketBorder()
        .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 12)
        .background(KeyEventCatcher(
            onMoveDown: { move(by: 1) },
            onMoveUp: { move(by: -1) },
            onSubmit: activateSelected,
            onCancel: dismiss
        ))
    }

    @ViewBuilder
    private var resultsList: some View {
        let items = filteredItems
        if items.isEmpty {
            VStack {
                Spacer()
                Text("No results")
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.chromeMuted)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                            QuickOpenResultRow(item: item, isSelected: idx == selectedIndex)
                                .id(idx)
                                .onTapGesture { activate(item) }
                        }
                    }
                }
                .onChange(of: selectedIndex) { _, new in
                    withAnimation(.linear(duration: 0.08)) {
                        proxy.scrollTo(new, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Items

    private var allItems: [QuickOpenItem] {
        var out: [QuickOpenItem] = []
        for workspace in store.workspaces {
            out.append(.workspace(workspace))
            for pane in workspace.root.allPanes {
                for tab in pane.tabs {
                    out.append(.tab(session: tab, workspace: workspace))
                }
            }
        }
        for agent in AgentTemplate.visibleOrdered(model: HiveSettingsModel.shared) {
            out.append(.agent(agent))
        }
        return out
    }

    private var filteredItems: [QuickOpenItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return allItems }
        return allItems.filter { $0.searchText.lowercased().contains(q) }
    }

    private func move(by delta: Int) {
        let items = filteredItems
        guard !items.isEmpty else { return }
        let next = (selectedIndex + delta) % items.count
        selectedIndex = next < 0 ? next + items.count : next
    }

    private func activateSelected() {
        let items = filteredItems
        guard items.indices.contains(selectedIndex) else { return }
        activate(items[selectedIndex])
    }

    private func activate(_ item: QuickOpenItem) {
        switch item {
        case .workspace(let ws):
            store.activateWorkspace(ws)
        case .tab(let session, let ws):
            store.activateWorkspace(ws)
            store.activateTab(session, in: ws)
        case .agent(let template):
            if let workspace = store.active {
                let pane = workspace.activePane
                store.addTab(in: workspace, pane: pane, template: template)
            }
        }
        dismiss()
    }

    private func dismiss() {
        store.isQuickOpenVisible = false
    }
}

@MainActor
enum QuickOpenItem: @MainActor Identifiable {
    case workspace(Workspace)
    case tab(session: Session, workspace: Workspace)
    case agent(AgentTemplate)

    var id: String {
        switch self {
        case .workspace(let ws): return "ws:\(ws.id.uuidString)"
        case .tab(let s, _): return "tab:\(s.id.uuidString)"
        case .agent(let a): return "agent:\(a.id)"
        }
    }

    var searchText: String {
        switch self {
        case .workspace(let ws):
            return "\(ws.title) \(ws.workingDirectory.path)"
        case .tab(let s, let ws):
            return "\(s.title) \(ws.title) \(s.currentDirectory.path) \(s.agent.title)"
        case .agent(let a):
            return a.title
        }
    }
}

private struct QuickOpenResultRow: View {
    let item: QuickOpenItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: Theme.space3) {
            icon
                .frame(width: 16, height: 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(primaryText)
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.chromeForeground)
                    .lineLimit(1)
                if let secondary = secondaryText {
                    Text(secondary)
                        .font(Theme.mono(10.5))
                        .foregroundStyle(Theme.chromeMuted)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            Text(kindLabel)
                .font(Theme.mono(10))
                .foregroundStyle(Theme.chromeFaint)
        }
        .padding(.horizontal, Theme.space4)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Theme.chromeActive : Color.clear)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var icon: some View {
        switch item {
        case .workspace:
            Image(systemName: "folder")
                .font(.system(size: 11))
                .foregroundStyle(Theme.chromeMuted)
        case .tab(let session, _):
            AgentIconView(asset: session.agent.iconAsset, fallbackSymbol: session.agent.symbol, size: 14)
        case .agent(let a):
            AgentIconView(asset: a.iconAsset, fallbackSymbol: a.symbol, size: 14)
        }
    }

    private var primaryText: String {
        switch item {
        case .workspace(let ws): return ws.title
        case .tab(let s, _): return s.title
        case .agent(let a): return a.title
        }
    }

    private var secondaryText: String? {
        switch item {
        case .workspace(let ws): return ws.workingDirectory.path
        case .tab(let s, let ws): return "\(ws.title) — \(s.currentDirectory.path)"
        case .agent: return nil
        }
    }

    private var kindLabel: String {
        switch item {
        case .workspace: return "workspace"
        case .tab: return "tab"
        case .agent: return "new tab"
        }
    }
}

/// Invisible NSView that catches ↑ / ↓ / ↩ / ⎋ regardless of which subview has
/// focus. SwiftUI's `.onSubmit` covers the TextField only, and `.keyboardShortcut`
/// modifiers don't compose well with arrow keys, so we drop down to AppKit.
private struct KeyEventCatcher: NSViewRepresentable {
    let onMoveDown: () -> Void
    let onMoveUp: () -> Void
    let onSubmit: () -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyCatcherView()
        view.onMoveDown = onMoveDown
        view.onMoveUp = onMoveUp
        view.onSubmit = onSubmit
        view.onCancel = onCancel
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let v = nsView as? KeyCatcherView else { return }
        v.onMoveDown = onMoveDown
        v.onMoveUp = onMoveUp
        v.onSubmit = onSubmit
        v.onCancel = onCancel
    }

    private final class KeyCatcherView: NSView {
        var onMoveDown: (() -> Void)?
        var onMoveUp: (() -> Void)?
        var onSubmit: (() -> Void)?
        var onCancel: (() -> Void)?
        private var monitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let monitor { NSEvent.removeMonitor(monitor); self.monitor = nil }
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, self.window === event.window else { return event }
                switch event.keyCode {
                case 125: self.onMoveDown?(); return nil   // ↓
                case 126: self.onMoveUp?(); return nil     // ↑
                case 36, 76: self.onSubmit?(); return nil  // ↩ / numpad ↩
                case 53: self.onCancel?(); return nil      // ⎋
                default: return event
                }
            }
        }

        override func removeFromSuperview() {
            if let monitor { NSEvent.removeMonitor(monitor); self.monitor = nil }
            super.removeFromSuperview()
        }
    }
}
