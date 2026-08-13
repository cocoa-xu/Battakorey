import AppKit
import FlowingDayControls
import FlowingDayPreferences
import SwiftUI

struct BattakoreyAutomationPane: View {
    @ObservedObject var settings: BatteryAutomationSettings
    @State private var portText = ""
    @State private var showsAdvanced = false

    var body: some View {
        PreferencesPaneStack {
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

            if settings.mcpEnabled || settings.restEnabled {
                serverSection
                exposureSection
            }

            if settings.mcpEnabled {
                mcpSection
            }

            if settings.restEnabled {
                restSection
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
                    TextField("Port", text: $portText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .multilineTextAlignment(.trailing)
                        .frame(width: 76)
                        .onSubmit(commitPort)
                    Button(action: randomizePort) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(FlowingSoftButtonStyle())
                    .help("Randomize Port")
                    .accessibilityLabel("Randomize Port")
                }
            }

            PreferencesRowSeparator()

            PreferencesRow(
                title: "Request Limit",
                caption: "Maximum requests per minute from each client."
            ) {
                HStack(spacing: 10) {
                    Text("\(settings.requestsPerMinute) per minute")
                        .monospacedDigit()
                        .foregroundStyle(FlowingPalette.muted)
                    Stepper(
                        "Request Limit",
                        value: $settings.requestsPerMinute,
                        in: BatteryAutomationSettings.requestsPerMinuteRange
                    )
                    .labelsHidden()
                }
            }

            PreferencesRowSeparator()

            PreferencesSwitchRow(
                title: "Require Access Token",
                caption: "Require the same Bearer token for every MCP and REST request.",
                isOn: $settings.authenticationRequired
            )

            if settings.authenticationRequired {
                PreferencesRowSeparator()
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

            PreferencesRow(title: "Advanced") {
                Button(showsAdvanced ? "Hide" : "Show") {
                    showsAdvanced.toggle()
                }
                .buttonStyle(FlowingSoftButtonStyle())
            }

            if showsAdvanced {
                PreferencesRowSeparator()
                PreferencesRow(
                    title: "Listen On",
                    caption: "This Mac Only is the safest choice."
                ) {
                    Picker("Listen On", selection: $settings.networkScope) {
                        ForEach(AutomationNetworkScope.allCases) { scope in
                            Text(scope.label).tag(scope)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 180)
                }

                PreferencesRowSeparator()

                PreferencesValueRow(title: "Bind Address", value: settings.bindAddress)

                if settings.networkScope == .selectedInterface {
                    PreferencesRowSeparator()
                    PreferencesRow(title: "Network Interface") {
                        if settings.networkInterfaces.isEmpty {
                            Text("No active network interfaces")
                                .foregroundStyle(FlowingPalette.muted)
                        } else {
                            Picker("Network Interface", selection: $settings.interfaceAddress) {
                                ForEach(settings.networkInterfaces) { interface in
                                    Text(interface.label).tag(interface.address)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 220)
                        }
                    }
                }

                if settings.networkScope.exposesToNetwork {
                    PreferencesRowSeparator()
                    PreferencesRow(
                        title: "Network Warning",
                        caption: networkWarning
                    ) {
                        Image(systemName: "exclamationmark.shield")
                            .foregroundStyle(.orange)
                    }
                }
            }

            if let problem = settings.serverProblem ?? settings.securityProblem {
                PreferencesRowSeparator()
                PreferencesRow(title: "Problem", caption: problem) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
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
            PreferencesValueRow(title: "Example", value: "Query the exposed snapshot") {
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
