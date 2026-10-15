//
//  EventComponents.swift
//  Gradit
//
//  Shared building blocks for the Events module: header, cover banner, chips,
//  count tabs, switches, toasts, dialogs, gallery tiles and the month grid.
//  Design: canvas › 12 Events.
//

import SwiftUI

// MARK: - Colours

extension Theme.Colors {
    static let chipGrey = Color(hex: 0xE9EDF3)
    static let ink400 = Color(hex: 0xA3ABB8)
}

extension EventCategory {
    /// Solid cover colour behind the category icon.
    var coverColor: Color {
        switch self {
        case .cultural: Theme.Colors.blue800
        case .sports: Theme.Colors.green700
        case .academic: Theme.Colors.blue700
        case .workshop: Theme.Colors.blue600
        case .parentMeeting: Theme.Colors.amber800
        case .holiday: Theme.Colors.ink500
        case .placement: Theme.Colors.green600
        case .other: Theme.Colors.ink700
        }
    }

    var chipBackground: Color {
        switch self {
        case .cultural: Theme.Colors.blue100
        case .sports, .placement: Theme.Colors.green50
        case .academic, .workshop: Theme.Colors.blue50
        case .parentMeeting: Theme.Colors.warningBackground
        case .holiday, .other: Theme.Colors.chipGrey
        }
    }

    var chipForeground: Color {
        switch self {
        case .cultural: Theme.Colors.blue800
        case .sports, .placement: Theme.Colors.green700
        case .academic, .workshop: Theme.Colors.blue700
        case .parentMeeting: Theme.Colors.amber800
        case .holiday, .other: Theme.Colors.ink700
        }
    }
}

extension EventStatus {
    var background: Color {
        switch self {
        case .upcoming: Theme.Colors.blue50
        case .ongoing: Theme.Colors.green50
        case .completed, .draft: Theme.Colors.chipGrey
        case .cancelled: Theme.Colors.errorBackground
        }
    }

    var foreground: Color {
        switch self {
        case .upcoming: Theme.Colors.blue700
        case .ongoing: Theme.Colors.green700
        case .completed, .draft: Theme.Colors.ink700
        case .cancelled: Theme.Colors.red700
        }
    }
}

extension RSVPResponse {
    var background: Color {
        switch self {
        case .going: Theme.Colors.green50
        case .maybe: Theme.Colors.warningBackground
        case .notGoing: Theme.Colors.chipGrey
        }
    }

    var foreground: Color {
        switch self {
        case .going: Theme.Colors.green700
        case .maybe: Theme.Colors.amber800
        case .notGoing: Theme.Colors.ink700
        }
    }
}

extension GalleryTint {
    var colors: [Color] {
        switch self {
        case .green: [Color(hex: 0x0B6B40), Color(hex: 0x0F7A4A)]
        case .royal: [Color(hex: 0x2453D4), Color(hex: 0x9DB1E8)]
        case .ink: [Color(hex: 0x101828), Color(hex: 0x344054)]
        case .navy: [Color(hex: 0x1B44B0), Color(hex: 0x173A9C)]
        case .amber: [Color(hex: 0x8A4E05), Color(hex: 0xE9C98F)]
        case .sand: [Color(hex: 0xE9C98F), Color(hex: 0xFDF3E1)]
        case .blue: [Color(hex: 0x173A9C), Color(hex: 0x2453D4)]
        case .sky: [Color(hex: 0x9DB1E8), Color(hex: 0xDCE5FB)]
        case .mint: [Color(hex: 0x0F7A4A), Color(hex: 0xE8F6EE)]
        }
    }

    var foreground: Color {
        switch self {
        case .sand: Theme.Colors.amber800
        case .sky: Theme.Colors.blue800
        case .mint: Theme.Colors.green700
        default: Theme.Colors.white
        }
    }
}

// MARK: - Header

/// 44 pt bordered back button + 18 pt title with an optional subtitle and trailing content.
struct EventTopBar<Trailing: View>: View {
    let title: String
    var subtitle: String?
    var backSymbol = "chevron.left"
    var backLabel: LocalizedStringKey = "Back"
    var onBack: (() -> Void)?
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 12) {
            if let onBack {
                TopBarBackButton(systemImage: backSymbol, accessibilityLabel: backLabel, action: onBack)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(AppFont.jakarta(18, .heavy))
                    .foregroundStyle(Theme.Colors.ink900)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(subtitle)
                        .font(AppFont.jakarta(12, .semibold))
                        .foregroundStyle(Theme.Colors.ink500)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            trailing()
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}

extension EventTopBar where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, backSymbol: String = "chevron.left",
         backLabel: LocalizedStringKey = "Back", onBack: (() -> Void)?) {
        self.init(title: title, subtitle: subtitle, backSymbol: backSymbol, backLabel: backLabel,
                  onBack: onBack, trailing: { EmptyView() })
    }
}

// MARK: - Cover

/// Category-coloured banner with the category icon and a caption pill.
struct EventCoverBanner: View {
    let category: EventCategory
    var caption: String?
    var height: CGFloat = 132
    var accessibilityTitle: String

    var body: some View {
        ZStack {
            category.coverColor
            Circle().fill(.white.opacity(0.12)).frame(width: height * 1.9).offset(x: height * 1.1, y: -height * 0.75)
            Circle().fill(.white.opacity(0.10)).frame(width: height * 1.3).offset(x: -height * 1.2, y: height * 0.6)
            Image(systemName: category.systemImage)
                .font(.system(size: height * 0.34, weight: .medium))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
        .overlay(alignment: .bottomLeading) {
            if let caption {
                Text(caption)
                    .font(AppFont.jakarta(11, .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.black.opacity(0.35), in: Capsule())
                    .padding(10)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Cover image: \(accessibilityTitle)"))
    }
}

// MARK: - Chips & badges

struct EventCategoryChip: View {
    let category: EventCategory

    var body: some View {
        Text(category.title)
            .font(AppFont.jakarta(12, .bold))
            .foregroundStyle(category.chipForeground)
            .padding(.horizontal, 8).padding(.vertical, 2)
            .background(category.chipBackground, in: Capsule())
    }
}

struct EventStatusPill: View {
    let text: String
    var systemImage: String?
    let foreground: Color
    let background: Color
    var border: Color?

    init(status: EventStatus) {
        text = status.title
        systemImage = status.systemImage
        foreground = status.foreground
        background = status.background
    }

    init(text: String, systemImage: String? = nil, foreground: Color, background: Color, border: Color? = nil) {
        self.text = text
        self.systemImage = systemImage
        self.foreground = foreground
        self.background = background
        self.border = border
    }

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage).font(.system(size: 10, weight: .bold))
            }
            Text(text).lineLimit(1)
        }
        .font(AppFont.jakarta(12, .bold))
        .foregroundStyle(foreground)
        .padding(.horizontal, 9).padding(.vertical, 3)
        .background(background, in: Capsule())
        .overlay {
            if let border { Capsule().strokeBorder(border, lineWidth: 1.5) }
        }
        .fixedSize()
    }
}

/// Selectable pill (Category, Venue type, Reminder chips).
struct EventChoiceChip: View {
    let title: String
    let isOn: Bool
    var showsCheck = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if showsCheck && isOn {
                    Image(systemName: "checkmark").font(.system(size: 11, weight: .heavy))
                }
                Text(title).lineLimit(1)
            }
            .font(AppFont.jakarta(13, .bold))
            .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.ink700)
            .padding(.horizontal, 14).frame(minHeight: 40)
            .background(isOn ? Theme.Colors.blue600 : Theme.Colors.white, in: Capsule())
            .overlay(Capsule().strokeBorder(isOn ? .clear : Theme.Colors.border))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
}

/// Two- or three-way segmented control drawn as a grey track with a white thumb.
struct EventSegmented<Value: Hashable>: View {
    let options: [(Value, String)]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.0) { value, label in
                let isOn = selection == value
                Button {
                    withAnimation(.easeOut(duration: 0.15)) { selection = value }
                } label: {
                    Text(label)
                        .font(AppFont.jakarta(13, isOn ? .heavy : .semibold))
                        .foregroundStyle(isOn ? Theme.Colors.blue700 : Theme.Colors.ink700)
                        .lineLimit(1).minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(isOn ? Theme.Colors.white : .clear, in: .rect(cornerRadius: 10))
                        .shadow(color: isOn ? .black.opacity(0.08) : .clear, radius: 2, y: 1)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(Theme.Colors.chipGrey, in: .rect(cornerRadius: 13))
    }
}

/// Dropdown chip used in filter rows ("Category: All ⌄"); highlighted when a filter is active.
struct EventFilterMenu<Value: Hashable>: View {
    let label: String
    let options: [(Value, String)]
    @Binding var selection: Value
    var isActive = false

    var body: some View {
        Menu {
            Picker(label, selection: $selection) {
                ForEach(options, id: \.0) { value, title in
                    Text(title).tag(value)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(label).lineLimit(1)
                Image(systemName: "chevron.down").font(.system(size: 10, weight: .bold))
            }
            .font(AppFont.jakarta(13, .bold))
            .foregroundStyle(isActive ? Theme.Colors.blue700 : Theme.Colors.ink700)
            .padding(.horizontal, 14).frame(height: 44)
            .background(isActive ? Theme.Colors.blue50 : Theme.Colors.white, in: Capsule())
            .overlay(Capsule().strokeBorder(isActive ? Theme.Colors.blue600 : Theme.Colors.border))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Count tabs

struct EventCountTab<ID: Hashable>: Identifiable {
    let id: ID
    let title: String
    let count: Int
}

/// Underlined tabs with a count bubble above each label (My events, Manage gallery, Gallery).
struct EventCountTabs<ID: Hashable>: View {
    let tabs: [EventCountTab<ID>]
    @Binding var selection: ID

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                let isOn = tab.id == selection
                Button {
                    withAnimation(.easeOut(duration: 0.15)) { selection = tab.id }
                } label: {
                    VStack(spacing: 3) {
                        Text("\(tab.count)")
                            .font(AppFont.jakarta(12, .heavy))
                            .foregroundStyle(isOn ? Theme.Colors.white : Theme.Colors.ink700)
                            .padding(.horizontal, 7).frame(minWidth: 24, minHeight: 20)
                            .background(isOn ? Theme.Colors.blue600 : Theme.Colors.chipGrey, in: Capsule())
                        Text(tab.title)
                            .font(AppFont.jakarta(13, isOn ? .heavy : .semibold))
                            .foregroundStyle(isOn ? Theme.Colors.blue700 : Theme.Colors.ink700)
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(isOn ? Theme.Colors.blue600 : .clear).frame(height: 3)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(tab.title), \(tab.count)")
                .accessibilityAddTraits(isOn ? [.isSelected] : [])
            }
        }
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.Colors.line).frame(height: 1) }
    }
}

// MARK: - Form pieces

/// White section card used by the forms.
struct EventFormCard<Content: View>: View {
    var title: String?
    var isRequired = false
    var trailing: String?
    var isError = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                HStack(spacing: 2) {
                    Text(title).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                        .accessibilityAddTraits(.isHeader)
                    if isRequired {
                        Text("*").font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.destructive)
                    }
                    Spacer(minLength: 0)
                    if let trailing {
                        Text(trailing).font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink500)
                    }
                }
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16, border: isError ? Theme.Colors.error : Theme.Colors.line, borderWidth: isError ? 2 : 1)
    }
}

/// Small field label: "Event title *".
struct EventFieldLabel: View {
    let text: String
    var isRequired = false
    var hint: String?

    var body: some View {
        HStack(spacing: 3) {
            Text(text).font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink700)
            if isRequired { Text("*").font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.destructive) }
            if let hint { Text(hint).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500) }
        }
    }
}

/// Red inline validation message.
struct EventFieldError: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "exclamationmark.circle.fill")
            .font(AppFont.jakarta(13, .semibold))
            .foregroundStyle(Theme.Colors.error)
            .accessibilityAddTraits(.isStaticText)
    }
}

/// Blue 52×32 switch from the Create event form.
struct EventSwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) { configuration.isOn.toggle() }
        } label: {
            HStack(spacing: 12) {
                configuration.label
                Spacer(minLength: 0)
                Capsule()
                    .fill(configuration.isOn ? Theme.Colors.blue600 : Theme.Colors.ink300)
                    .frame(width: 52, height: 32)
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Circle().fill(Theme.Colors.white).frame(width: 26, height: 26).padding(3)
                    }
            }
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
        }
    }
}

/// Switch row with a title and grey description.
struct EventToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink900)
                Text(subtitle).font(AppFont.jakarta(12)).foregroundStyle(Theme.Colors.ink500)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.leading)
        }
        .toggleStyle(EventSwitchStyle())
    }
}

/// Bordered button that opens a picker sheet: "📅 Sat, 24 Oct".
struct EventPickerButton: View {
    let systemImage: String
    let text: String
    var isError = false
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.Colors.blue600)
                Text(text).font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900).lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12).frame(height: 48)
            .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isError ? Theme.Colors.error : Theme.Colors.border, lineWidth: isError ? 2 : 1))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Facts

/// Icon tile + small label + bold value.
struct EventFactRow: View {
    let systemImage: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconTile(systemImage: systemImage, size: 36, radius: 10)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(AppFont.jakarta(12, .semibold)).foregroundStyle(Theme.Colors.ink500)
                Text(value).font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.ink900)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

/// "196 going / 240 invited ……… 82%" with a bar.
struct EventProgressRow: View {
    let text: String
    let percentText: String
    let fraction: Double
    var tint: Color = Theme.Colors.green600

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(text).font(AppFont.jakarta(13, .bold)).foregroundStyle(Theme.Colors.ink700)
                Spacer()
                Text(percentText).font(AppFont.jakarta(13, .heavy)).foregroundStyle(Theme.Colors.ink900)
            }
            GeometryReader { proxy in
                Capsule().fill(Theme.Colors.chipGrey)
                    .overlay(alignment: .leading) {
                        Capsule().fill(tint).frame(width: proxy.size.width * min(max(fraction, 0), 1))
                    }
            }
            .frame(height: 6)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Toast

struct EventToastMessage: Equatable {
    enum Tone { case success, danger, info }
    var text: String
    var tone: Tone = .success
}

struct EventToastView: View {
    let toast: EventToastMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon).font(.system(size: 14, weight: .bold))
            Text(toast.text).font(AppFont.jakarta(13, .semibold)).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(foreground)
        .padding(12)
        .background(background, in: .rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private var icon: String {
        switch toast.tone {
        case .success: "checkmark.circle.fill"
        case .danger: "exclamationmark.circle.fill"
        case .info: "info.circle.fill"
        }
    }

    private var foreground: Color {
        switch toast.tone {
        case .success: Theme.Colors.green700
        case .danger: Theme.Colors.red700
        case .info: Theme.Colors.blue700
        }
    }

    private var background: Color {
        switch toast.tone {
        case .success: Theme.Colors.green50
        case .danger: Theme.Colors.errorBackground
        case .info: Theme.Colors.blue50
        }
    }
}

extension View {
    /// Floating dark toast at the bottom that hides itself after ~2.6 s.
    func eventFloatingToast(_ message: Binding<String?>) -> some View {
        overlay(alignment: .bottom) {
            if let text = message.wrappedValue {
                Text(text)
                    .font(AppFont.jakarta(14, .semibold))
                    .foregroundStyle(Theme.Colors.white)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(Theme.Colors.ink900, in: .rect(cornerRadius: 12))
                    .padding(.horizontal, 16).padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task(id: text) {
                        try? await Task.sleep(for: .seconds(2.6))
                        withAnimation { message.wrappedValue = nil }
                    }
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .animation(.easeOut(duration: 0.2), value: message.wrappedValue)
    }
}

// MARK: - Dialog

/// Centred alert card over a dimmed screen (Cancel event?, Delete gallery?).
struct EventAlertCard<Extra: View>: View {
    var systemImage: String?
    var iconTint: Color = Theme.Colors.destructive
    var iconBackground: Color = Theme.Colors.errorBackground
    let title: String
    let message: String
    var cancelTitle = String(localized: "Cancel")
    let confirmTitle: String
    var confirmColor: Color = Theme.Colors.destructive
    var isWorking = false
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @ViewBuilder var extra: () -> Extra

    var body: some View {
        ZStack {
            Color(hex: 0x101828, opacity: 0.48)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 12) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(iconTint)
                        .frame(width: 52, height: 52)
                        .background(iconBackground, in: Circle())
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    .frame(maxWidth: .infinity, alignment: systemImage == nil ? .leading : .center)
                    .accessibilityAddTraits(.isHeader)
                Text(message)
                    .font(AppFont.jakarta(14)).foregroundStyle(Theme.Colors.ink700)
                    .lineSpacing(3)
                    .multilineTextAlignment(systemImage == nil ? .leading : .center)
                    .frame(maxWidth: .infinity, alignment: systemImage == nil ? .leading : .center)
                    .fixedSize(horizontal: false, vertical: true)
                extra()
                HStack(spacing: 10) {
                    Button(action: onCancel) {
                        Text(cancelTitle)
                            .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.ink700)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border))
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    Button(action: onConfirm) {
                        ZStack {
                            Text(confirmTitle).opacity(isWorking ? 0 : 1)
                            if isWorking { ProgressView().tint(Theme.Colors.white) }
                        }
                        .font(AppFont.jakarta(15, .bold)).foregroundStyle(Theme.Colors.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(confirmColor, in: .rect(cornerRadius: 14))
                        .contentShape(.rect)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .disabled(isWorking)
                }
                .padding(.top, 4)
            }
            .padding(20)
            .background(Theme.Colors.white, in: .rect(cornerRadius: 22))
            .shadow(color: Color(hex: 0x101828, opacity: 0.24), radius: 24, y: 24)
            .padding(.horizontal, 20)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
        .transition(.opacity)
    }
}

extension EventAlertCard where Extra == EmptyView {
    init(systemImage: String? = nil, iconTint: Color = Theme.Colors.destructive,
         iconBackground: Color = Theme.Colors.errorBackground, title: String, message: String,
         cancelTitle: String = String(localized: "Cancel"), confirmTitle: String,
         confirmColor: Color = Theme.Colors.destructive, isWorking: Bool = false,
         onConfirm: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.init(systemImage: systemImage, iconTint: iconTint, iconBackground: iconBackground, title: title,
                  message: message, cancelTitle: cancelTitle, confirmTitle: confirmTitle, confirmColor: confirmColor,
                  isWorking: isWorking, onConfirm: onConfirm, onCancel: onCancel, extra: { EmptyView() })
    }
}

/// Sheet header: bold title, grey subtitle, round close button.
struct EventSheetHeader: View {
    let title: String
    var subtitle: String?
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AppFont.jakarta(20, .heavy)).foregroundStyle(Theme.Colors.ink900)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(subtitle).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark").font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.Colors.ink700).frame(width: 36, height: 36)
                    .background(Theme.Colors.surfaceMuted, in: Circle())
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }
}

// MARK: - States

struct EventStateCard: View {
    let systemImage: String
    var tint: Color = Theme.Colors.blue600
    var tintBackground: Color = Theme.Colors.blue50
    let title: String
    let message: String
    var actionTitle: String?
    var actionImage: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 56, height: 56)
                .background(tintBackground, in: Circle())
                .accessibilityHidden(true)
            Text(title).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
                .multilineTextAlignment(.center)
            Text(message).font(AppFont.jakarta(13)).foregroundStyle(Theme.Colors.ink500)
                .multilineTextAlignment(.center).lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: 8) {
                        if let actionImage { Image(systemName: actionImage) }
                        Text(actionTitle)
                    }
                    .font(AppFont.jakarta(14, .bold)).foregroundStyle(Theme.Colors.white)
                    .padding(.horizontal, 20).frame(height: 44)
                    .background(Theme.Colors.blue600, in: .rect(cornerRadius: 12))
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .dashboardCard(radius: 16)
    }
}

/// Grey placeholder card shown while a list loads.
struct EventSkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            bar(width: 90, height: 22)
            bar(height: 18).padding(.trailing, 50)
            bar(height: 14).padding(.trailing, 140)
            bar(height: 34)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dashboardCard(radius: 16)
        .accessibilityHidden(true)
    }

    private func bar(width: CGFloat? = nil, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 10).fill(Theme.Colors.chipGrey)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
}

/// Bordered search field.
struct EventSearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.Colors.ink500)
            TextField(placeholder, text: $text)
                .font(AppFont.jakarta(14))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.Colors.ink300)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 12).frame(height: 48)
        .background(Theme.Colors.white, in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.border))
    }
}

/// White bottom action bar with a top hairline.
struct EventBottomBar<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(spacing: 10) { content() }
            .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 12)
            .background(Theme.Colors.white.ignoresSafeArea(edges: .bottom))
            .overlay(alignment: .top) { Rectangle().fill(Theme.Colors.line).frame(height: 1) }
    }
}

/// Outline / filled 52 pt bar buttons.
struct EventBarButton: View {
    enum Style { case outline, filled, destructive }

    let title: String
    var systemImage: String?
    var style: Style = .filled
    var isLoading = false
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                HStack(spacing: 6) {
                    if let systemImage { Image(systemName: systemImage).font(.system(size: 14, weight: .bold)) }
                    Text(title).lineLimit(1).minimumScaleFactor(0.85)
                }
                .opacity(isLoading ? 0 : 1)
                if isLoading { ProgressView().tint(style == .outline ? Theme.Colors.ink700 : Theme.Colors.white) }
            }
            .font(AppFont.jakarta(15, .bold))
            .foregroundStyle(style == .outline ? Theme.Colors.ink700 : Theme.Colors.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(background, in: .rect(cornerRadius: 14))
            .overlay {
                if style == .outline { RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.border) }
            }
            .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isLoading || !isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }

    private var background: Color {
        switch style {
        case .outline: Theme.Colors.white
        case .filled: Theme.Colors.blue600
        case .destructive: Theme.Colors.destructive
        }
    }
}

// MARK: - Gallery tile

/// Square photo / video tile: thumbnail (local image, remote URL or tinted placeholder),
/// video badge with duration and a Cover badge.
struct GalleryTileView: View {
    let item: GalleryItem
    var localImage: UIImage?
    var isCover = false
    var cornerRadius: CGFloat = 10
    var symbolSize: CGFloat = 22

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay { thumbnail }
            .clipShape(.rect(cornerRadius: cornerRadius))
            .overlay(alignment: .bottomLeading) {
                if item.kind == .video {
                    HStack(spacing: 3) {
                        Image(systemName: "play.fill").font(.system(size: 8, weight: .bold))
                        Text(item.duration ?? "").font(AppFont.jakarta(11, .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(.black.opacity(0.55), in: Capsule())
                    .padding(6)
                }
            }
            .overlay(alignment: .topLeading) {
                if isCover {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill").font(.system(size: 8, weight: .bold))
                        Text("Cover").font(AppFont.jakarta(10, .heavy))
                    }
                    .foregroundStyle(Theme.Colors.ink900)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(.white, in: Capsule())
                    .padding(6)
                }
            }
            .accessibilityElement()
            .accessibilityLabel(Text(item.accessibilityText + (isCover ? String(localized: ". Cover photo") : "")))
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let localImage {
            Image(uiImage: localImage).resizable().scaledToFill()
        } else if let url = item.thumbnailURL {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        LinearGradient(colors: item.tint.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay {
                Image(systemName: item.kind == .video ? "play.fill" : item.symbol)
                    .font(.system(size: symbolSize, weight: .medium))
                    .foregroundStyle(item.tint.foreground.opacity(0.9))
            }
    }
}

// MARK: - Month calendar

/// Month grid used by the date sheet and the receivers' calendar view.
struct EventMonthGrid: View {
    let month: Date
    let selected: Date?
    var minimumDate: Date?
    var marks: [Date: Int] = [:]
    var now: Date = .now
    let onSelect: (Date) -> Void

    private let calendar = Calendar.current

    var body: some View {
        let days = monthDays
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol).font(AppFont.jakarta(12, .bold)).foregroundStyle(Theme.Colors.ink500)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                }
            }
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = selected.map { calendar.isDate($0, inSameDayAs: day) } ?? false
        let isToday = calendar.isDate(day, inSameDayAs: now)
        let isDisabled = minimumDate.map { day < calendar.startOfDay(for: $0) } ?? false
        let count = marks[calendar.startOfDay(for: day)] ?? 0
        let isPast = day < calendar.startOfDay(for: now)
        return Button { onSelect(day) } label: {
            VStack(spacing: 0) {
                Text(EventFormat.dayOfMonth(day))
                    .font(AppFont.jakarta(15, isSelected ? .heavy : .semibold))
                if !marks.isEmpty {
                    Text(count > 0 ? "• \(count)" : " ")
                        .font(AppFont.jakarta(10, .heavy))
                        .foregroundStyle(isSelected ? Theme.Colors.white : Theme.Colors.blue600)
                }
            }
            .foregroundStyle(isSelected ? Theme.Colors.white
                             : (isDisabled ? Theme.Colors.ink300 : (isPast && !marks.isEmpty ? Theme.Colors.ink500 : Theme.Colors.ink900)))
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(isSelected ? Theme.Colors.blue600 : .clear, in: .rect(cornerRadius: 12))
            .overlay {
                if isToday && !isSelected {
                    RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.blue600, lineWidth: 2)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(accessibilityLabel(day, count: count, isToday: isToday, isDisabled: isDisabled))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func accessibilityLabel(_ day: Date, count: Int, isToday: Bool, isDisabled: Bool) -> String {
        var parts = [day.formatted(.dateTime.weekday(.wide).day().month(.wide))]
        if isToday { parts.append(String(localized: "today")) }
        if isDisabled { parts.append(String(localized: "unavailable, in the past")) }
        if !marks.isEmpty {
            parts.append(count == 0 ? String(localized: "no events")
                         : count == 1 ? String(localized: "1 event") : String(localized: "\(count) events"))
        }
        return parts.joined(separator: ", ")
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    /// Leading blanks + every day of the month.
    private var monthDays: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let count = calendar.range(of: .day, in: .month, for: month)?.count else { return [] }
        let weekday = calendar.component(.weekday, from: interval.start)
        let blanks = (weekday - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: blanks)
        for offset in 0..<count {
            days.append(calendar.date(byAdding: .day, value: offset, to: interval.start))
        }
        return days
    }
}

/// "‹ October 2026 ›" month switcher.
struct EventMonthHeader: View {
    @Binding var month: Date
    var minimumMonth: Date?

    private let calendar = Calendar.current

    var body: some View {
        HStack {
            Button { shift(-1) } label: {
                Image(systemName: "chevron.left").frame(width: 44, height: 44).contentShape(.rect)
            }
            .disabled(!canGoBack)
            .accessibilityLabel("Previous month")
            Spacer()
            Text(EventFormat.monthTitle(month)).font(AppFont.jakarta(16, .heavy)).foregroundStyle(Theme.Colors.ink900)
            Spacer()
            Button { shift(1) } label: {
                Image(systemName: "chevron.right").frame(width: 44, height: 44).contentShape(.rect)
            }
            .accessibilityLabel("Next month")
        }
        .font(.system(size: 15, weight: .bold))
        .foregroundStyle(Theme.Colors.blue600)
        .buttonStyle(.plain)
    }

    private var canGoBack: Bool {
        guard let minimumMonth else { return true }
        return !calendar.isDate(month, equalTo: minimumMonth, toGranularity: .month)
    }

    private func shift(_ value: Int) {
        if let next = calendar.date(byAdding: .month, value: value, to: month) { month = next }
    }
}

// MARK: - Flow layout

/// Wraps chips onto as many rows as needed (design: `flex-wrap: wrap; gap: 8px`).
struct EventFlowLayout: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let rows = arrange(subviews: subviews, width: width)
        let height = rows.map(\.height).reduce(0, +) + rowSpacing * CGFloat(max(rows.count - 1, 0))
        let used = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? used, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews: subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                                      anchor: .topLeading, proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + rowSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if needed > width, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}

// MARK: - Gallery cover banner

/// Wide cover with a "★ Cover · caption" pill (event detail, Manage gallery).
struct GalleryCoverBanner: View {
    let tint: GalleryTint
    let symbol: String
    var caption: String?
    var imageURL: URL?
    var localImage: UIImage?
    var height: CGFloat = 150

    var body: some View {
        ZStack {
            LinearGradient(colors: tint.colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: symbol).font(.system(size: height * 0.3, weight: .medium))
                .foregroundStyle(tint.foreground.opacity(0.9))
            if let localImage {
                Image(uiImage: localImage).resizable().scaledToFill()
            } else if let imageURL {
                AsyncImage(url: imageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.clear
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(alignment: .bottomLeading) {
            HStack(spacing: 4) {
                Image(systemName: "star.fill").font(.system(size: 9, weight: .bold))
                Text(caption.map { String(localized: "Cover · \($0)") } ?? String(localized: "Cover"))
                    .font(AppFont.jakarta(11, .bold)).lineLimit(1)
            }
            .foregroundStyle(Theme.Colors.ink900)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(.white, in: Capsule())
            .padding(10)
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Cover photo: \(caption ?? "")"))
    }
}
