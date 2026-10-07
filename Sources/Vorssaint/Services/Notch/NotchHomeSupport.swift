// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

/// Home is Controls with smart cards: the player and the levels each hold a
/// second face a swipe away, and the face that matters now comes first.
enum NotchHomeSupport {
    enum Face: Equatable {
        case music, agents, levels, calendar, files
    }

    /// The player, then the agents. A turn in progress with nothing playing
    /// puts the agents first.
    static func leftFaces(agents: Bool, musicPlaying: Bool, agentsWorking: Bool) -> [Face] {
        guard agents else { return [.music] }
        return agentsWorking && !musicPlaying ? [.agents, .music] : [.music, .agents]
    }

    /// The levels, then the calendar. Files sent to the island lead, since
    /// they are what the island was just given, unless an event is about to
    /// start or under way, which leads before anything else.
    static func rightFaces(calendar: Bool, eventSoon: Bool, files: Bool = false) -> [Face] {
        var faces: [Face] = [.levels]
        if calendar { faces.append(.calendar) }
        if files { faces.insert(.files, at: 0) }
        if calendar, eventSoon {
            faces.removeAll { $0 == .calendar }
            faces.insert(.calendar, at: 0)
        }
        return faces
    }

    /// A place on Home's row of shortcuts.
    enum Slot: Hashable, Identifiable {
        case control(NotchControlItem)
        /// The tool last opened from the Tools page, by its raw value.
        case tool(String)
        /// The Tools page itself, until a tool has been opened from it.
        case tools

        var id: String {
            switch self {
            case .control(let item): return "control." + item.rawValue
            case .tool(let raw): return "tool." + raw
            case .tools: return "tools"
            }
        }
    }

    /// Tools that Controls already offers as a shortcut of its own.
    static let toolShortcuts: [String: NotchControlItem] = [
        "keepAwake": .keepAwake, "micMute": .microphone, "screenshot": .screenshot,
        "screenRecorder": .recording, "scratchpad": .scratchpad,
    ]
    static let recentToolLimit = 6

    /// Most recent first, each tool once.
    static func remember(_ tool: String, in history: [String]) -> [String] {
        Array(([tool] + history.filter { $0 != tool }).prefix(recentToolLimit))
    }

    /// The most recent tool still available that the row does not already
    /// show as a shortcut.
    static func recentTool(_ history: [String], shortcuts: [NotchControlItem],
                           available: (String) -> Bool) -> String? {
        history.first { tool in
            available(tool) && !(toolShortcuts[tool].map(shortcuts.contains) ?? false)
        }
    }

    /// Controls' shortcuts, with the timer's place given to the last tool
    /// opened, or to the Tools page before any; the timer stays a page away.
    /// Without the Tools page the timer's place is simply left out.
    static func rail(controls: [NotchControlItem], recentTool: String?, toolsPage: Bool) -> [Slot] {
        let shortcuts = controls.filter { !$0.isLevel && $0 != .music }
        var slots = shortcuts.filter { $0 != .timer }.map(Slot.control)
        guard toolsPage else { return slots }
        let slot = recentTool.map(Slot.tool) ?? .tools
        let index = shortcuts.firstIndex(of: .timer).map { min($0, slots.count) } ?? slots.count
        slots.insert(slot, at: index)
        return slots
    }

    /// Home and Controls stand in for each other: a link to the one hidden
    /// opens the other rather than nothing.
    static func page(_ module: NotchModule, in modules: [NotchModule]) -> NotchModule? {
        if modules.contains(module) { return module }
        switch module {
        case .home where modules.contains(.controls): return .controls
        case .controls where modules.contains(.home): return .home
        default: return nil
        }
    }
}
