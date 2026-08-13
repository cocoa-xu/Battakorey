import AppKit
import FlowingDayControls
import FlowingDayPreferences
import SwiftUI

struct BattakoreyAutomationPane: View {
    @ObservedObject var settings: BatteryAutomationSettings
    @State private var portText = ""
    @State private var showsAdvanced = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PreferencesSection(
                "Automation Access",
                footer: "Both interfaces are off by default. Enable only what you plan to use."
            ) {
                PreferencesRow(
                    title: "Interfaces",
                    caption: "MCP and REST can be enabled independently."
                ) {
                    HStack(spacing: 10) {
                        PreferencesCheckToggle("MCP", isOn: $settings.mcpEnabled)
                        PreferencesCheckToggle("REST", isOn: $settings.restEnabled)
                    }
                }
            }

            FlowingDisclosureContent(isExpanded: automationEnabled) {
                VStack(alignment: .leading, spacing: 0) {
                    serverSection
                        .padding(.top, sectionSpacing)
                    exposureSection
                        .padding(.top, sectionSpacing)
                    FlowingDisclosureContent(isExpanded: settings.mcpEnabled) {
                        mcpSection
                            .padding(.top, sectionSpacing)
                    }
                    FlowingDisclosureContent(isExpanded: settings.restEnabled) {
                        restSection
                            .padding(.top, sectionSpacing)
                    }
                }
            }
        }
        .onAppear {
            portText = String(settings.port)
            settings.refreshNetworkInterfaces()
        }
    }

    private var serverSection: some View {
        PreferencesSection("Server") {
            PreferencesRow(
                title: "Port",
                caption: "Use an unprivileged port from 1024 through 65535."
            ) {
                HStack(spacing: 7) {
                    FlowingTextField(
                        "Port",
                        text: $portText,
                        onSubmit: commitPort
                    )
                    .monospacedDigit()
                    .frame(width: 88)
                    Button(action: randomizePort) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(FlowingSoftButtonStyle())
                    .help("Randomize Port")
                    .accessibilityLabel("Randomize Port")
                }
            }

            PreferencesRowSeparator()

            PreferencesSliderRow(
                title: "Request Limit",
                caption: "Maximum requests per minute from each client.",
                value: requestsPerMinute,
                in: Double(BatteryAutomationSettings.requestsPerMinuteRange.lowerBound)
                    ... Double(BatteryAutomationSettings.requestsPerMinuteRange.upperBound),
                step: 1,
                format: { "\(Int($0.rounded())) per minute" }
            )

            PreferencesRowSeparator()

            PreferencesSwitchRow(
                title: "Require Access Token",
                caption: "Require a Bearer token for every MCP and REST request.",
                isOn: $settings.authenticationRequired
            )

            PreferencesDependentRows(isVisible: settings.authenticationRequired) {
                PreferencesRow(
                    title: "Access Token",
                    caption: "Stored in Keychain. Regenerating it disconnects existing clients."
                ) {
                    HStack(spacing: 7) {
                        Text("••••••••••••••••")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(FlowingPalette.muted)
                        AutomationCopyButton(text: settings.accessToken)
                        Button(action: settings.regenerateAccessToken) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(FlowingSoftButtonStyle())
                        .help("Regenerate Token")
                        .accessibilityLabel("Regenerate Token")
                    }
                }
            }

            PreferencesRowSeparator()

            PreferencesValueRow(
                title: "Status",
                value: settings.isServerRunning
                    ? "Listening on \(settings.bindAddress):\(settings.port)"
                    : "Could Not Listen"
            )

            PreferencesRowSeparator()

            PreferencesExpandableRow(
                title: "Advanced",
                isExpanded: $showsAdvanced
            )

            PreferencesDependentRows(isVisible: showsAdvanced) {
                PreferencesSegmentedRow(
                    title: "Listen On",
                    caption: "This Mac Only is the safest choice.",
                    controlWidth: 320,
                    selection: $settings.networkScope,
                    options: AutomationNetworkScope.allCases.map {
                        FlowingSegmentOption($0, label: $0.label)
                    }
                )

                PreferencesRowSeparator()

                PreferencesValueRow(title: "Bind Address", value: settings.bindAddress)

                PreferencesDependentRows(
                    isVisible: settings.networkScope == .selectedInterface
                ) {
                    if settings.networkInterfaces.isEmpty {
                        PreferencesEmptyRow("No active network interfaces.")
                    } else {
                        PreferencesPopupRow(
                            title: "Network Interface",
                            minimumControlWidth: 220,
                            selection: $settings.interfaceAddress,
                            options: settings.networkInterfaces.map {
                                FlowingSelectOption($0.address, label: $0.label)
                            }
                        )
                    }
                }

                PreferencesDependentRows(isVisible: settings.networkScope.exposesToNetwork) {
                    PreferencesEmptyRow(
                        networkWarning,
                        symbol: "exclamationmark.shield"
                    )
                }
            }

            PreferencesDependentRows(isVisible: problem != nil) {
                if let problem {
                    PreferencesEmptyRow(
                        problem,
                        symbol: "exclamationmark.triangle"
                    )
                }
            }
        }
    }

    private var exposureSection: some View {
        PreferencesSection(
            "Exposed Readings",
            footer: "A reading is exposed only when its capability is enabled here "
                + "and its matching item is visible in the menu preferences. "
                + "Unavailable hardware readings are omitted."
        ) {
            ForEach(Array(BatteryAutomationCapability.allCases.enumerated()), id: \.element.id) {
                index, capability in
                if index > 0 {
                    PreferencesRowSeparator()
                }
                PreferencesSwitchRow(
                    title: capability.title,
                    caption: capability.description,
                    isOn: Binding(
                        get: { settings.enabledCapabilities.contains(capability) },
                        set: { isEnabled in
                            if isEnabled != settings.enabledCapabilities.contains(capability) {
                                settings.toggleCapability(capability)
                            }
                        }
                    )
                )
            }
        }
    }

    private var mcpSection: some View {
        PreferencesSection("MCP Connections") {
            PreferencesValueRow(title: "MCP Endpoint", value: settings.mcpEndpoint) {
                AutomationCopyButton(text: settings.mcpEndpoint)
            }
            PreferencesRowSeparator()
            PreferencesValueRow(
                title: "Claude Code",
                value: "Streamable HTTP install command"
            ) {
                AutomationCopyButton(text: settings.claudeInstallCommand)
            }
        }
    }

    private var restSection: some View {
        PreferencesSection("REST API") {
            PreferencesValueRow(title: "Base URL", value: settings.restEndpoint) {
                AutomationCopyButton(text: settings.restEndpoint)
            }
            PreferencesRowSeparator()
            PreferencesValueRow(title: "Example", value: "Invoke the snapshot capability") {
                AutomationCopyButton(text: settings.restExampleCommand)
            }
        }
    }

    private var networkWarning: String {
        let authentication = settings.authenticationRequired
            ? "Keep the access token private."
            : "Access token authentication is disabled."
        return "Network access uses unencrypted HTTP. Use only a trusted network. \(authentication)"
    }

    private var automationEnabled: Bool {
        settings.mcpEnabled || settings.restEnabled
    }

    private var problem: String? {
        settings.serverProblem ?? settings.securityProblem
    }

    private var requestsPerMinute: Binding<Double> {
        Binding(
            get: { Double(settings.requestsPerMinute) },
            set: { settings.requestsPerMinute = Int($0.rounded()) }
        )
    }

    private var sectionSpacing: CGFloat {
        PreferencesMetrics.standard.sectionSpacing
    }

    private func commitPort() {
        guard let port = Int(portText.trimmingCharacters(in: .whitespaces)),
              BatteryAutomationSettings.portRange.contains(port) else {
            portText = String(settings.port)
            return
        }
        settings.port = port
    }

    private func randomizePort() {
        settings.randomizePort()
        portText = String(settings.port)
    }
}

private struct AutomationCopyButton: View {
    let text: String
    @State private var copied = false

    var body: some View {
        Button(copied ? "Copied" : "Copy") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            copied = true
            Task {
                try? await Task.sleep(for: .seconds(1.4))
                copied = false
            }
        }
        .buttonStyle(FlowingSoftButtonStyle())
    }
}
