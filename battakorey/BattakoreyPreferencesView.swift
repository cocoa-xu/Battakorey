import AppKit
import FlowingDaySettings
import SwiftUI

private enum BattakoreyPreferencesPage: Hashable {
    case mainMenu
    case charging
    case componentPower
    case internals
    case about
}

private struct BatteryMenuOption: Identifiable {
    let id: BatteryMenuItemID
    let title: String
    let caption: String
}

private enum BattakoreyPreferencesLayout {
    static let selectionGroupWidth: CGFloat = 360
    static let selectionSpacing: CGFloat = 6
}

struct BattakoreyPreferencesRoot: View {
    @ObservedObject var model: BatteryPreferencesModel
    @State private var selection = BattakoreyPreferencesPage.mainMenu

    var body: some View {
        SettingsView(
            selection: $selection,
            configuration: SettingsViewConfiguration(
                applicationName: "Battakorey",
                settingsTitle: "Preferences",
                applicationIcon: NSApp.applicationIconImage,
                defaultAccent: SettingsAccent(
                    fill: SettingsPalette.dynamic(light: 0x8B6FC1, dark: 0xB49AE6),
                    foreground: SettingsPalette.dynamic(light: 0x654A9D, dark: 0xC8B1F1)
                )
            ),
            groups: [
                SettingsPageGroup(
                    id: "display",
                    title: "Menu Display",
                    pages: [mainMenuPage, chargingPage]
                ),
                SettingsPageGroup(
                    id: "advanced",
                    title: "Advanced",
                    pages: [componentPowerPage, internalsPage]
                ),
                SettingsPageGroup(id: "application", pages: [aboutPage])
            ]
        )
    }

    private var mainMenuPage: SettingsPage<BattakoreyPreferencesPage> {
        SettingsPage(
            id: .mainMenu,
            title: "Main Menu",
            subtitle: "Choose the battery details shown at a glance.",
            icon: .system("menubar.rectangle")
        ) {
            SettingsPaneStack {
                SettingsSection(
                    "Presets",
                    footer: "Presets only change menu presentation. No battery data is collected."
                ) {
                    SettingsRow(
                        title: "Visible information",
                        caption: "Start focused or expose every available reading."
                    ) {
                        HStack(spacing: 8) {
                            Button("Recommended", action: model.useRecommendedItems)
                                .buttonStyle(SettingsSoftButtonStyle(
                                    isProminent: model.visibility == .recommended
                                ))
                            Button("Show Everything", action: model.showAllItems)
                                .buttonStyle(SettingsSoftButtonStyle(
                                    isProminent: model.visibility == .all
                                ))
                        }
                    }
                }

                SettingsSection("Layout") {
                    SettingsSwitchRow(
                        title: "Section Titles",
                        caption: "Show category headings such as Capacity and Electrical.",
                        isOn: Binding(
                            get: { model.visibility.showsSectionTitles },
                            set: model.setShowsSectionTitles
                        )
                    )
                }

                optionSection("Status", options: Self.statusOptions)
                optionSection("Capacity", options: Self.capacityOptions)
                optionSection("Electrical", options: Self.electricalOptions)
            }
        }
    }

    private var chargingPage: SettingsPage<BattakoreyPreferencesPage> {
        SettingsPage(
            id: .charging,
            title: "Power & Charging",
            subtitle: "Control adapter and charging diagnostics.",
            icon: .system("bolt.fill")
        ) {
            SettingsPaneStack {
                SettingsSection("Power Adapter") {
                    optionRows(Self.adapterCapabilityOptions)
                    SettingsRowSeparator()
                    multiSelectRow(
                        title: "Live Measurements",
                        caption: "Choose the measured DC input values shown in the menu.",
                        options: Self.liveMeasurementOptions
                    )
                }
                optionSection("Diagnostics", options: Self.diagnosticOptions)
            }
        }
    }

    private var internalsPage: SettingsPage<BattakoreyPreferencesPage> {
        SettingsPage(
            id: .internals,
            title: "Battery Internals",
            subtitle: "Choose controller data for the nested internals menu.",
            icon: .system("waveform.path.ecg")
        ) {
            SettingsPaneStack {
                SettingsSection("Cell Measurements") {
                    multiSelectRow(
                        title: "Voltage",
                        caption: "Choose the individual cell voltages and voltage spread shown in the menu.",
                        options: Self.cellVoltageOptions
                    )
                    SettingsRowSeparator()
                    multiSelectRow(
                        title: "Learned Capacity",
                        caption: "Choose the learned Qmax values and capacity spread shown in the menu.",
                        options: Self.cellCapacityOptions
                    )
                    SettingsRowSeparator()
                    multiSelectRow(
                        title: "Resistance",
                        caption: "Choose the learned resistance values and resistance spread shown in the menu.",
                        options: Self.cellResistanceOptions
                    )
                }
                optionSection("Gauge History", options: Self.gaugeOptions)
                optionSection("Lifetime", options: Self.lifetimeOptions)
            }
        }
    }

    private var componentPowerPage: SettingsPage<BattakoreyPreferencesPage> {
        SettingsPage(
            id: .componentPower,
            title: "Component Power",
            subtitle: "Choose live hardware energy counters shown in the menu.",
            icon: .system("cpu")
        ) {
            SettingsPaneStack {
                multiSelectSection(
                    "Processor",
                    caption: "Choose the CPU, GPU, and Neural Engine estimates shown in the menu.",
                    options: Self.processorPowerOptions
                )
                multiSelectSection(
                    "Memory",
                    caption: "Choose the system memory and GPU SRAM estimates shown in the menu.",
                    options: Self.memoryPowerOptions
                )
                multiSelectSection(
                    "Display",
                    caption: "Choose the built-in and external display estimates shown in the menu.",
                    options: Self.displayPowerOptions,
                    footer: "All component readings are sampled once per second through IOReport and disappear gracefully when a channel is unavailable."
                )
            }
        }
    }

    private var aboutPage: SettingsPage<BattakoreyPreferencesPage> {
        SettingsPage(
            id: .about,
            title: "About",
            subtitle: "Version and project information.",
            icon: .system("info.circle"),
            headerIcon: .application
        ) {
            BattakoreyAboutPane(versionText: Self.versionText)
        }
    }

    private func optionSection(
        _ title: String,
        options: [BatteryMenuOption],
        footer: String? = nil
    ) -> some View {
        SettingsSection(title, footer: footer) {
            optionRows(options)
        }
    }

    private func multiSelectSection(
        _ title: String,
        caption: String,
        options: [BatteryMenuOption],
        footer: String? = nil
    ) -> some View {
        SettingsSection(title, footer: footer) {
            multiSelectRow(
                title: "Visible Readings",
                caption: caption,
                options: options
            )
        }
    }

    private func optionRows(_ options: [BatteryMenuOption]) -> some View {
        ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
            if index > 0 {
                SettingsRowSeparator()
            }
            SettingsSwitchRow(
                title: option.title,
                caption: option.caption,
                isOn: visibilityBinding(for: option.id)
            )
        }
    }

    private func multiSelectRow(
        title: String,
        caption: String,
        options: [BatteryMenuOption]
    ) -> some View {
        SettingsRow(title: title, caption: caption) {
            HStack(spacing: BattakoreyPreferencesLayout.selectionSpacing) {
                ForEach(options) { option in
                    SettingsCheckToggle(
                        option.title,
                        isOn: visibilityBinding(for: option.id)
                    )
                    .help(option.caption)
                    .accessibilityLabel(option.title)
                    .accessibilityHint(option.caption)
                }
            }
            .frame(width: BattakoreyPreferencesLayout.selectionGroupWidth)
        }
    }

    private func visibilityBinding(for id: BatteryMenuItemID) -> Binding<Bool> {
        Binding(
            get: { model.isVisible(id) },
            set: { model.setVisible($0, for: id) }
        )
    }

    private static let statusOptions = [
        BatteryMenuOption(id: .batteryLevel, title: "Battery Level", caption: "Current charge percentage."),
        BatteryMenuOption(id: .status, title: "Status", caption: "Charging, full, AC, or discharging state."),
        BatteryMenuOption(id: .powerSource, title: "Power Source", caption: "AC, battery, or UPS power."),
        BatteryMenuOption(id: .timeRemaining, title: "Time Remaining", caption: "Estimated time to full or empty.")
    ]

    private static let capacityOptions = [
        BatteryMenuOption(id: .currentCharge, title: "Current Charge", caption: "Present charge in milliamp-hours."),
        BatteryMenuOption(id: .fullCharge, title: "Full Charge", caption: "Current usable full-charge capacity."),
        BatteryMenuOption(id: .rawMaximum, title: "Raw Maximum", caption: "Controller estimate before macOS normalization."),
        BatteryMenuOption(id: .designCapacity, title: "Design Capacity", caption: "Original factory-rated capacity."),
        BatteryMenuOption(id: .maximumCapacity, title: "Maximum Capacity", caption: "Maximum Capacity reported by System Information."),
        BatteryMenuOption(id: .batteryCondition, title: "Condition", caption: "Battery condition reported by System Information."),
        BatteryMenuOption(id: .capacityRetention, title: "Raw Capacity Ratio", caption: "Controller capacity divided by design capacity; not Apple's Maximum Capacity."),
        BatteryMenuOption(id: .cycles, title: "Cycles", caption: "Cycle count and rated cycle-life progress.")
    ]

    private static let electricalOptions = [
        BatteryMenuOption(id: .temperature, title: "Temperature", caption: "Current pack temperature."),
        BatteryMenuOption(id: .voltage, title: "Voltage", caption: "Current pack voltage."),
        BatteryMenuOption(id: .current, title: "Current", caption: "Signed charge or discharge current."),
        BatteryMenuOption(id: .batteryPower, title: "Battery Flow", caption: "Signed measured charge or discharge at the battery rail."),
        BatteryMenuOption(id: .chargeTarget, title: "Controller Charge Target", caption: "Configured charging target; not a measured battery flow."),
        BatteryMenuOption(id: .systemDraw, title: "Controller System Load", caption: "Coarse system-load estimate reported by the battery controller.")
    ]

    private static let adapterCapabilityOptions = [
        BatteryMenuOption(id: .adapterRating, title: "Adapter Rating", caption: "Advertised adapter wattage."),
        BatteryMenuOption(id: .powerContract, title: "Adapter Electrical Capability", caption: "Adapter voltage and current capability; not a negotiated PD contract."),
        BatteryMenuOption(id: .pdContract, title: "USB-C PD Contract", caption: "Selected contract joined to an active physical USB-C port.")
    ]

    private static let liveMeasurementOptions = [
        BatteryMenuOption(id: .liveInput, title: "Live Input", caption: "Measured DC input power from the SMC."),
        BatteryMenuOption(id: .dcInputRail, title: "DC Input Rail", caption: "Measured DC input voltage and current.")
    ]

    private static let processorPowerOptions = [
        BatteryMenuOption(id: .cpuPower, title: "CPU", caption: "Combined efficiency and performance core energy."),
        BatteryMenuOption(id: .gpuPower, title: "GPU", caption: "Graphics processor energy-model estimate."),
        BatteryMenuOption(id: .anePower, title: "Neural Engine", caption: "Apple Neural Engine activity and energy use.")
    ]

    private static let memoryPowerOptions = [
        BatteryMenuOption(id: .memoryPower, title: "Memory", caption: "DRAM energy-model estimate."),
        BatteryMenuOption(id: .gpuMemoryPower, title: "GPU SRAM", caption: "On-chip graphics memory energy.")
    ]

    private static let displayPowerOptions = [
        BatteryMenuOption(id: .displayPower, title: "Built-in", caption: "Internal display subsystem energy."),
        BatteryMenuOption(id: .externalDisplayPower, title: "External", caption: "External display pipeline energy.")
    ]

    private static let diagnosticOptions = [
        BatteryMenuOption(id: .chargeInterruption, title: "Charging Hold", caption: "Public temperature-related charge interruption reason."),
        BatteryMenuOption(id: .adapterErrors, title: "Adapter Issues", caption: "Insufficient power, foreign-object, or placement warnings."),
        BatteryMenuOption(id: .publicHealthHint, title: "Public Health Hint", caption: "Source-specific IOPowerSources health value."),
        BatteryMenuOption(id: .capacityEstimated, title: "Estimated Capacity", caption: "Whether the public capacity value is estimated."),
        BatteryMenuOption(id: .batteryFailureModes, title: "Battery Issues", caption: "Failure modes reported by the public power-source API."),
        BatteryMenuOption(id: .optimizedCharging, title: "Optimized Charging", caption: "Whether macOS charge protection is engaged."),
        BatteryMenuOption(id: .lowPowerMode, title: "Low Power Mode", caption: "Current system energy-saving state."),
        BatteryMenuOption(id: .thermalPressure, title: "Thermal Pressure", caption: "Public process-level thermal pressure state."),
        BatteryMenuOption(id: .cpuPowerLimits, title: "CPU Power Limits", caption: "Public CPU restrictions imposed by thermal or power constraints."),
        BatteryMenuOption(id: .failureStatus, title: "Failure Status", caption: "Permanent controller failure flags."),
        BatteryMenuOption(id: .cellDisconnects, title: "Cell Disconnects", caption: "Recorded battery cell disconnect events."),
        BatteryMenuOption(id: .notChargingReason, title: "Not Charging Reason", caption: "Raw reason flags when charging is blocked."),
        BatteryMenuOption(id: .slowChargingReason, title: "Slow Charging Reason", caption: "Raw reason flags when charging is limited.")
    ]

    private static let cellVoltageOptions = [
        BatteryMenuOption(id: .cellVoltages, title: "Cell Voltages", caption: "Individual cell-group voltages."),
        BatteryMenuOption(id: .cellVoltageDelta, title: "Voltage Delta", caption: "Spread between the highest and lowest cell.")
    ]

    private static let cellCapacityOptions = [
        BatteryMenuOption(id: .learnedQmax, title: "Learned Qmax", caption: "Controller-learned capacity per cell group."),
        BatteryMenuOption(id: .qmaxDelta, title: "Qmax Delta", caption: "Spread in learned cell capacities.")
    ]

    private static let cellResistanceOptions = [
        BatteryMenuOption(id: .resistance, title: "Resistance", caption: "Raw learned cell resistance values."),
        BatteryMenuOption(id: .resistanceDelta, title: "Resistance Delta", caption: "Spread between resistance values.")
    ]

    private static let gaugeOptions = [
        BatteryMenuOption(id: .dailyChargeRange, title: "Daily Charge Range", caption: "Lowest and highest state of charge today."),
        BatteryMenuOption(id: .lastGaugeRelearn, title: "Last Gauge Relearn", caption: "Cycle count at the last Qmax calibration."),
        BatteryMenuOption(id: .dataFlashWrites, title: "Data Flash Writes", caption: "Controller data-flash write counter."),
        BatteryMenuOption(id: .rsenseOpenEvents, title: "Rsense Open Events", caption: "Recorded current-sense open events."),
        BatteryMenuOption(id: .qmaxDisqualification, title: "Qmax Disqualification", caption: "Raw flags preventing capacity relearning.")
    ]

    private static let lifetimeOptions = [
        BatteryMenuOption(id: .lifetimeTemperatures, title: "Lifetime Temperatures", caption: "Recorded minimum, average, and maximum."),
        BatteryMenuOption(id: .packVoltageRange, title: "Pack Voltage Range", caption: "Recorded lifetime voltage extremes."),
        BatteryMenuOption(id: .peakCurrent, title: "Peak Charge / Discharge", caption: "Recorded peak current in both directions."),
        BatteryMenuOption(id: .operatingTime, title: "Operating Time", caption: "Controller-reported lifetime operating hours.")
    ]

    private static var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "Unknown"
        return "Version \(version)"
    }
}

private struct BattakoreyAboutPane: View {
    @Environment(\.settingsAccent) private var accent
    @Environment(\.settingsTypography) private var typography
    let versionText: String

    var body: some View {
        SettingsPaneStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Battakorey")
                    .font(typography.contentTitle.font)
                    .foregroundStyle(SettingsPalette.ink)
                Text(versionText)
                    .font(typography.pageSubtitle.font)
                    .foregroundStyle(SettingsPalette.faint)
                Text("A tiny Takodachi in your menu bar with detailed Mac battery telemetry.")
                    .font(typography.body.font)
                    .foregroundStyle(SettingsPalette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }

            SettingsSection("Details") {
                SettingsValueRow(
                    title: "Battery Data",
                    value: "IOPowerSources · AppleSmartBattery · AppleSMC · IOReport"
                )
                SettingsRowSeparator()
                SettingsValueRow(title: "Requirements", value: "macOS 13 or later")
            }

            SettingsSection("Acknowledgements") {
                acknowledgementRow(
                    title: "FlowingDayUI",
                    caption: "Reusable preferences windows and macOS interface components.",
                    destination: Self.flowingDayURL
                )
            }

            HStack(spacing: 4) {
                Text("Copyright © 2026")
                    .foregroundStyle(SettingsPalette.faint)
                Link(destination: Self.cocoaURL) {
                    Text("Cocoa")
                        .foregroundStyle(accent.foreground)
                }
                .buttonStyle(.plain)
            }
            .font(typography.body.font)
            .padding(.leading, 4)
        }
    }

    private func acknowledgementRow(
        title: String,
        caption: String,
        destination: URL
    ) -> some View {
        SettingsRow(title: title, caption: caption) {
            Link(destination: destination) {
                Text("GitHub")
            }
            .buttonStyle(SettingsSoftButtonStyle())
            .help("Open \(title) on GitHub")
        }
    }

    private static let flowingDayURL = URL(string: "https://github.com/cocoa-xu/flowing-day-ui")!
    private static let cocoaURL = URL(string: "https://github.com/cocoa-xu")!
}

@MainActor
final class BattakoreyPreferencesWindowController {
    private let model: BatteryPreferencesModel
    private lazy var presenter = SettingsWindowPresenter(
        rootView: BattakoreyPreferencesRoot(model: model)
    )

    init(model: BatteryPreferencesModel) {
        self.model = model
    }

    func show() {
        presenter.show()
    }
}
