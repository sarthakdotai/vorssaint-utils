// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

/// What is happening now, the latest notification, and every page one click
/// away. Cards read what the closed island already shows for each activity.
struct NotchHomeView: View {
    @ObservedObject var service: NotchService
    let size: CGSize
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var notifications = NotchNotificationService.shared
    private var text: NotchStrings { FeatureStrings.notch(l10n.language) }

    var body: some View {
        VStack(spacing: NotchLayout.rowSpacing) {
            cards
                .frame(height: NotchLayout.homeCardHeight)
            if service.homeShowsNotice, let latest = notifications.items.first {
                NotchHomeNotice(item: latest, service: service)
                    .frame(height: NotchLayout.homeNoticeHeight)
                    .transition(.opacity)
            }
            NotchHomeDock(service: service)
                .frame(height: NotchLayout.homeDockHeight)
        }
        .frame(width: size.width, alignment: .top)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder private var cards: some View {
        let live = NotchHomeSupport.cards(service.compactActivities, width: size.width)
        if live.isEmpty {
            HStack(spacing: 10) {
                Image(systemName: "moon.stars")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                VStack(alignment: .leading, spacing: 2) {
                    Text(text.homeQuiet).font(.system(size: 13, weight: .semibold))
                    Text(text.homeQuietHint).font(.system(size: 11)).foregroundStyle(.secondary)
                        .lineLimit(1).minimumScaleFactor(0.85)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .modifier(NotchControlSurface(cornerRadius: 18, interactive: false))
            .accessibilityElement(children: .combine)
        } else {
            HStack(spacing: NotchLayout.rowSpacing) {
                ForEach(live) { activity in
                    NotchHomeCard(activity: activity) { service.select(activity.module) }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
}

/// One live activity: its page's mark and name, and the reading the closed
/// island gives it. A click opens the page, as the closed strip does.
private struct NotchHomeCard: View {
    let activity: NotchCompactActivity
    let open: () -> Void
    @ObservedObject private var l10n = L10n.shared

    var body: some View {
        let title = activity.title(l10n.language)
        Button(action: open) {
            VStack(alignment: .leading, spacing: 5) {
                Label(title, systemImage: activity.symbol)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                NotchHomeReading(activity: activity)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .modifier(NotchControlSurface(cornerRadius: 18))
        }
        .buttonStyle(NotchButtonStyle(cornerRadius: 18))
        .accessibilityLabel(title)
        .accessibilityHint(FeatureStrings.notch(l10n.language).open)
        .accessibilityIdentifier("notch.home.\(activity.rawValue)")
    }
}

/// Each reading observes only its own source, so a ticking timer redraws
/// one line rather than the page.
private struct NotchHomeReading: View {
    let activity: NotchCompactActivity

    var body: some View {
        switch activity {
        case .music: MusicReading()
        case .timer: TimerReading()
        case .downloads: DownloadReading()
        case .agents: AgentsReading()
        case .calendar: CalendarReading()
        case .watch: WatchReading()
        case .keepAwake: KeepAwakeReading()
        }
    }

    private struct MusicReading: View {
        @ObservedObject private var music = NotchMusicService.shared
        @ObservedObject private var l10n = L10n.shared
        var body: some View {
            let track = music.playback?.track
            Text([track?.title, track?.artist].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: " · ")
                    .nonEmpty ?? FeatureStrings.radialMenu(l10n.language).mediaNowPlaying)
        }
    }

    private struct TimerReading: View {
        @ObservedObject private var timer = NotchTimerService.shared
        @ObservedObject private var l10n = L10n.shared
        var body: some View {
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                Text(NotchTimerSupport.compactText(for: timer.session, at: timer.now,
                                                   locale: Locale(identifier: l10n.language.rawValue)))
            }
        }
    }

    private struct DownloadReading: View {
        @ObservedObject private var downloads = NotchDownloadService.shared
        @ObservedObject private var l10n = L10n.shared
        var body: some View {
            let item = downloads.items.first { $0.active && !$0.completed }
            HStack(spacing: 6) {
                Text(item?.name ?? FeatureStrings.notchFiles(l10n.language).downloadsTitle)
                if let fraction = item?.fraction {
                    Text(fraction.formatted(NotchDownloadSupport.percentFormat(l10n.language)))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private struct AgentsReading: View {
        @ObservedObject private var agents = AgentUsageService.shared
        var body: some View {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(NotchAgentSupport.stripReading(agents.snapshot, readout: NotchAgentSupport.readout(),
                                                   display: NotchAgentSupport.limitDisplay(),
                                                   focus: NotchAgentSupport.limitFocus(), now: context.date))
            }
        }
    }

    private struct CalendarReading: View {
        @ObservedObject private var calendar = NotchCalendarService.shared
        @ObservedObject private var l10n = L10n.shared
        var body: some View {
            if let countdown = calendar.countdown {
                HStack(spacing: 6) {
                    Text(NotchCapsuleLayout.calendarTitle(countdown, language: l10n.language))
                    Text(NotchCalendarSupport.timeText(countdown, locale: l10n.language.formattingLocale()))
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(FeatureStrings.notchCalendar(l10n.language).title)
            }
        }
    }

    private struct WatchReading: View {
        @ObservedObject private var watch = NotchWatchService.shared
        @ObservedObject private var l10n = L10n.shared
        var body: some View {
            Text(watch.headline.nonEmpty ?? FeatureStrings.notchWatch(l10n.language).title)
        }
    }

    private struct KeepAwakeReading: View {
        @ObservedObject private var keepAwake = KeepAwakeManager.shared
        @ObservedObject private var l10n = L10n.shared
        var body: some View {
            if let end = keepAwake.endDate {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(NotchKeepAwakeSupport.compactText(until: end, now: context.date,
                                                           locale: Locale(identifier: l10n.language.rawValue)))
                }
            } else {
                Text(Strings.localized(l10n.language).keepAwakeTitle)
            }
        }
    }
}

/// The latest mirrored notification on one line; a click opens the
/// Notifications page, where it can be answered or opened in its app.
private struct NotchHomeNotice: View {
    let item: NotchSystemNotification
    let service: NotchService
    @ObservedObject private var l10n = L10n.shared

    var body: some View {
        let strings = FeatureStrings.notchNotifications(l10n.language)
        HStack(spacing: 8) {
            Button { service.open(.notifications) } label: {
                HStack(spacing: 8) {
                    NotchNotificationAppIcon(app: item.content.app, size: 16)
                    Text(item.content.compactTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                        .layoutPriority(1)
                    Text(item.content.compactDetail)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.leading, 10)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.content.accessibilityText)
            .accessibilityHint(strings.open)
            NotchIconButton(symbol: "xmark", title: strings.dismiss) {
                NotchNotificationService.shared.dismiss(item.id)
            }
            .padding(.trailing, 3)
        }
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
    }
}

/// Every enabled page as a labelled tile, as the sections gallery draws them,
/// on one row that scrolls sideways when the pages outnumber the room.
private struct NotchHomeDock: View {
    @ObservedObject var service: NotchService
    @ObservedObject private var l10n = L10n.shared
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: NotchLayout.sectionSpacing) {
                ForEach(NotchHomeSupport.dock(service.modules)) { module in
                    tile(module)
                }
            }
        }
        .scrollIndicators(.never)
    }

    private func tile(_ module: NotchModule) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        let title = module.title(l10n.language)
        return Button { service.select(module) } label: {
            VStack(spacing: 5) {
                Image(systemName: module.symbol)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(module.galleryTint)
                    .frame(height: 19)
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 4)
            .frame(width: NotchLayout.homeDockTileWidth, height: NotchLayout.homeDockHeight)
            .background(.white.opacity(0.045), in: shape)
            .overlay { shape.strokeBorder(.white.opacity(contrast == .increased ? 0.4 : 0.04), lineWidth: 1) }
            .contentShape(shape)
        }
        .buttonStyle(NotchButtonStyle(cornerRadius: 14, lifts: false))
        .accessibilityLabel(title)
        .accessibilityIdentifier("notch.home.dock.\(module.rawValue)")
        .help(title + "  ⌥⌘" + module.shortcutKey.uppercased())
    }

}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
