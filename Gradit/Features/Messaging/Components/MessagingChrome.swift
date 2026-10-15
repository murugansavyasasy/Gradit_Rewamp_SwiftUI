//
//  MessagingChrome.swift
//  Gradit
//
//  Shared chrome for the Message menu screens, taken from the design canvas:
//  the 00 Design System › Top bar, the green switch, focusable input fields and
//  the sender-role colours used on message cards.
//

import SwiftUI

// MARK: - Top bar

/// 44 pt square back button with a 1 pt #E4E8EF border and 12 pt corners.
struct TopBarBackButton: View {
    var systemImage = "chevron.left"
    var fill: Color = Theme.Colors.white
    var accessibilityLabel: LocalizedStringKey = "Back"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink900)
                .frame(width: 44, height: 44)
                .background(fill, in: .rect(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.Colors.line))
                .contentShape(.rect)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

/// 44 pt round, borderless header icon button (search, more).
struct TopBarIconButton: View {
    let systemImage: String
    let accessibilityLabel: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink900)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }
}

/// Design top bar: 64 pt tall, 10/16 padding, back button + 18 pt title.
struct MessagingTopBar<Trailing: View>: View {
    let title: String
    var titleWeight: Font.Weight = .bold
    var background: Color = Theme.Colors.white
    var spacing: CGFloat = 12
    var trailingPadding: CGFloat = 16
    var titleLeadingPadding: CGFloat = 0
    var backIcon = "chevron.left"
    /// nil hides the back button (e.g. a tab root).
    var onBack: (() -> Void)?
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: spacing) {
            if let onBack {
                TopBarBackButton(systemImage: backIcon, action: onBack)
            }
            Text(title)
                .font(AppFont.jakarta(18, titleWeight))
                .foregroundStyle(Theme.Colors.ink900)
                .lineLimit(1)
                .padding(.leading, onBack == nil ? 0 : titleLeadingPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            trailing()
        }
        .padding(.leading, 16)
        .padding(.trailing, trailingPadding)
        .padding(.vertical, 10)
        .frame(height: 64)
        .background(background)
    }
}

extension MessagingTopBar where Trailing == EmptyView {
    init(title: String, titleWeight: Font.Weight = .bold, background: Color = Theme.Colors.white,
         backIcon: String = "chevron.left", onBack: (() -> Void)?) {
        self.init(title: title, titleWeight: titleWeight, background: background,
                  backIcon: backIcon, onBack: onBack) { EmptyView() }
    }
}

// MARK: - Switch

/// 52×32 switch: green #0F7A4A when on, #C5CBD6 when off, 26 pt white knob.
struct DesignSwitchToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) { configuration.isOn.toggle() }
        } label: {
            Capsule()
                .fill(configuration.isOn ? Theme.Colors.green600 : Theme.Colors.ink300)
                .frame(width: 52, height: 32)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle()
                        .fill(Theme.Colors.white)
                        .frame(width: 26, height: 26)
                        .padding(3)
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

// MARK: - Field chrome

extension View {
    /// White field with a 1 pt #D0D6E0 border; focused: 2 pt #2453D4 border and a 4 pt #DCE5FB ring.
    func designFieldChrome(isFocused: Bool, radius: CGFloat) -> some View {
        self
            .background(Theme.Colors.white, in: .rect(cornerRadius: radius))
            .clipShape(.rect(cornerRadius: radius))
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(isFocused ? Theme.Colors.blue600 : Theme.Colors.border,
                                  lineWidth: isFocused ? 2 : 1)
            }
            .background {
                RoundedRectangle(cornerRadius: radius + 4)
                    .fill(isFocused ? Theme.Colors.blue100 : .clear)
                    .padding(-4)
            }
            .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Swipe back

extension View {
    /// Keeps the edge-swipe "back" gesture working on screens that draw their own top bar.
    func keepsSwipeBack() -> some View {
        background(SwipeBackEnabler().frame(width: 0, height: 0))
    }
}

private struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller { Controller() }
    func updateUIViewController(_ controller: Controller, context: Context) {}

    final class Controller: UIViewController, UIGestureRecognizerDelegate {
        private weak var originalDelegate: UIGestureRecognizerDelegate?

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard let gesture = navigationController?.interactivePopGestureRecognizer,
                  gesture.delegate !== self else { return }
            originalDelegate = gesture.delegate
            gesture.delegate = self
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            if let gesture = navigationController?.interactivePopGestureRecognizer, gesture.delegate === self {
                gesture.delegate = originalDelegate
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (navigationController?.viewControllers.count ?? 0) > 1
        }
    }
}

// MARK: - Sender role colours

/// Avatar and role-pill colours per sender role (design: Principal amber, Exam Cell blue,
/// Office grey, Class teacher green). Unknown roles fall back to the name-based palette.
struct MessageRoleStyle {
    let avatarForeground: Color
    let avatarBackground: Color
    let pillForeground: Color
    let pillBackground: Color
}

extension Message {
    var roleStyle: MessageRoleStyle {
        switch senderRole?.lowercased() {
        case "principal":
            MessageRoleStyle(avatarForeground: Theme.Colors.amber800, avatarBackground: Theme.Colors.warningBackground,
                             pillForeground: Theme.Colors.amber800, pillBackground: Theme.Colors.warningBackground)
        case "exam cell":
            MessageRoleStyle(avatarForeground: Theme.Colors.blue700, avatarBackground: Theme.Colors.blue100,
                             pillForeground: Theme.Colors.blue700, pillBackground: Theme.Colors.blue50)
        case "office":
            MessageRoleStyle(avatarForeground: Theme.Colors.ink700, avatarBackground: Color(hex: 0xE9EDF3),
                             pillForeground: Theme.Colors.ink700, pillBackground: Theme.Colors.surfaceMuted)
        case "class teacher":
            MessageRoleStyle(avatarForeground: Theme.Colors.green700, avatarBackground: Theme.Colors.green100,
                             pillForeground: Theme.Colors.green700, pillBackground: Theme.Colors.green50)
        default:
            MessageRoleStyle(avatarForeground: avatarForeground, avatarBackground: avatarBackground,
                             pillForeground: avatarForeground, pillBackground: avatarBackground)
        }
    }
}
