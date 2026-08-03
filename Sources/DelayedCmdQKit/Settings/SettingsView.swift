import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var authorization: AccessibilityAuthorization
    @ObservedObject var loginItem: LoginItem

    var body: some View {
        VStack(spacing: 0) {
            RingPreview(duration: settings.holdDuration)
                .padding(.top, 22)

            Text("\(HoldDuration.text(settings.holdDuration)) 동안 ⌘Q를 누르고 있으면 앱이 종료됩니다")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.top, 6)
                .padding(.bottom, 22)

            Divider()

            VStack(spacing: 16) {
                durationRow
                Divider()
                toggleRow(
                    "연속 종료 허용",
                    subtitle: "계속 누르고 있으면 다음 앱도 이어서 종료합니다",
                    isOn: $settings.allowsContinuousQuit
                )
                toggleRow("일시 중지", subtitle: "⌘Q를 원래대로 되돌립니다", isOn: $settings.isPaused)
                toggleRow("로그인 시 실행", subtitle: nil, isOn: loginItemBinding)
                toggleRow("앱 아이콘 표시", subtitle: "원 가운데에 종료될 앱을 보여줍니다", isOn: $settings.showsApplicationIcon)
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
                Text("지연 시간")
                    .font(.system(size: 13))
                Spacer()
                Text(HoldDuration.text(settings.holdDuration))
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
                Text(HoldDuration.text(HoldDuration.range.lowerBound))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            } maximumValueLabel: {
                Text(HoldDuration.text(HoldDuration.range.upperBound))
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
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
                Text(authorization.isTrusted ? "손쉬운 사용 권한 허용됨" : "손쉬운 사용 권한 필요")
                    .font(.system(size: 12))
                if let error = loginItem.lastError {
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if !authorization.isTrusted {
                Button("설정 열기") { authorization.openSystemSettings() }
                    .controlSize(.small)
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

/// Replays the ring at the configured duration so a value can be judged by eye
/// instead of by number.
private struct RingPreview: View {
    let duration: TimeInterval

    @State private var progress: Double = 0
    @State private var replayTask: Task<Void, Never>?

    var body: some View {
        RingHUD(progress: progress, icon: nil)
            .frame(width: RingMetrics.canvas, height: RingMetrics.canvas * 0.78)
            .contentShape(Rectangle())
            .onTapGesture { replay() }
            .help("클릭하면 미리 봅니다")
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
