import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var authorization: AccessibilityAuthorization
    @ObservedObject var loginItem: LoginItem

    private var strings: Localization { settings.strings }

    var body: some View {
        VStack(spacing: 0) {
            RingPreview(duration: settings.holdDuration, hint: strings.previewHint)
                .padding(.top, 22)

            Text(strings.holdSummary(settings.holdDuration))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 22)
                .padding(.top, 6)
                .padding(.bottom, 22)

            Divider()

            VStack(spacing: 16) {
                durationRow
                Divider()
                appearanceRow
                languageRow
                Divider()
                toggleRow(
                    strings.continuousQuitTitle,
                    subtitle: strings.continuousQuitSubtitle,
                    isOn: $settings.allowsContinuousQuit
                )
                toggleRow(
                    strings.pauseTitle,
                    subtitle: strings.pauseSubtitle,
                    isOn: $settings.isPaused
                )
                toggleRow(strings.launchAtLoginTitle, subtitle: nil, isOn: loginItemBinding)
                toggleRow(
                    strings.showAppIconTitle,
                    subtitle: strings.showAppIconSubtitle,
                    isOn: $settings.showsApplicationIcon
                )
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)

            Divider()

            permissionRow
                .padding(.horizontal, 22)
                .padding(.vertical, 14)
        }
        .frame(width: 380)
        .onAppear { loginItem.refresh() }
    }

    // MARK: - Rows

    private var durationRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(strings.delayTitle)
                    .font(.system(size: 13))
                Spacer()
                Text(strings.duration(settings.holdDuration))
                    .font(.system(size: 13, weight: .medium).monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Slider(
                value: $settings.holdDuration,
                in: HoldDuration.range,
                step: HoldDuration.step
            ) {
                EmptyView()
            } minimumValueLabel: {
                Text(strings.duration(HoldDuration.range.lowerBound))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            } maximumValueLabel: {
                Text(strings.duration(HoldDuration.range.upperBound))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var appearanceRow: some View {
        HStack {
            Text(strings.appearanceTitle).font(.system(size: 13))
            Spacer(minLength: 12)
            Picker("", selection: $settings.appearance) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Text(mode.title(strings)).tag(mode)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .fixedSize()
        }
    }

    private var languageRow: some View {
        HStack {
            Text(strings.languageTitle).font(.system(size: 13))
            Spacer(minLength: 12)
            Picker("", selection: $settings.language) {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    Text(language.endonym ?? strings.languageSystem).tag(language)
                }
            }
            .labelsHidden()
            .fixedSize()
        }
    }

    private func toggleRow(_ title: String, subtitle: String?, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 12)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
    }

    private var permissionRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(authorization.isTrusted ? Color.green : Color.orange)
                .frame(width: 7, height: 7)

            VStack(alignment: .leading, spacing: 2) {
                Text(
                    authorization.isTrusted
                        ? strings.accessibilityGranted
                        : strings.accessibilityRequired
                )
                .font(.system(size: 12))

                if let error = loginItem.lastError {
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            if !authorization.isTrusted {
                GlassButton(title: strings.openSystemSettings) {
                    authorization.openSystemSettings()
                }
            }
        }
    }

    private var loginItemBinding: Binding<Bool> {
        Binding(
            get: { loginItem.isEnabled },
            set: { loginItem.setEnabled($0) }
        )
    }
}

/// Uses the Liquid Glass button style where the OS provides it, and the standard
/// bordered style on earlier releases.
private struct GlassButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        if #available(macOS 26.0, *) {
            Button(title, action: action)
                .buttonStyle(.glass)
                .controlSize(.small)
        } else {
            Button(title, action: action)
                .controlSize(.small)
        }
    }
}

/// Replays the ring at the configured duration so a value can be judged by eye
/// instead of by number.
private struct RingPreview: View {
    let duration: TimeInterval
    let hint: String

    @State private var progress: Double = 0
    @State private var replayTask: Task<Void, Never>?

    var body: some View {
        RingHUD(progress: progress, icon: nil)
            .frame(width: RingMetrics.canvas, height: RingMetrics.canvas * 0.78)
            .contentShape(Rectangle())
            .onTapGesture { replay() }
            .help(hint)
            .onAppear { replay() }
            .onChange(of: duration) { _, _ in replay() }
            .onDisappear {
                replayTask?.cancel()
                replayTask = nil
            }
    }

    private func replay() {
        replayTask?.cancel()
        replayTask = Task { @MainActor in
            var reset = Transaction()
            reset.disablesAnimations = true
            withTransaction(reset) { progress = 0 }

            // One hop so the reset commits before the fill starts.
            await Task.yield()
            guard !Task.isCancelled else { return }
            withAnimation(.linear(duration: duration)) { progress = 1 }
        }
    }
}
