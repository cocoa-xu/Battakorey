import { FdIcons } from "@flowing-day/ui";
import "@flowing-day/ui/theme.css";

import {
  automationCapabilities,
  createAutomationState,
  isAutomationEnabled,
  randomAutomationPort,
  resolveAutomationBindAddress,
  resolveAutomationEndpoint,
} from "./automation-preview.js";
import {
  defaultDownloadArchitecture,
  downloadOptions,
  resolveDownloadOption,
} from "./download-options.js";

document.documentElement.classList.add("js");

const PREFERENCES_SIZE = Object.freeze({ width: 900, height: 640 });
const PREFERENCES_INSET = Object.freeze({ horizontal: 56, vertical: 40 });
const HEADER_CONDENSE_OFFSET = 80;

const menuOptions = {
  status: [
    ["batteryLevel", "Battery Level", "Current charge percentage."],
    ["status", "Status", "Charging, full, AC, or discharging state."],
    ["powerSource", "Power Source", "AC, battery, or UPS power."],
    ["timeRemaining", "Time Remaining", "Estimated time to full or empty."],
  ],
  capacity: [
    ["currentCharge", "Current Charge", "Present charge in milliamp-hours."],
    ["fullCharge", "Full Charge", "Current usable full-charge capacity."],
    ["rawMaximum", "Raw Maximum", "Controller estimate before macOS normalization."],
    ["designCapacity", "Design Capacity", "Original factory-rated capacity."],
    ["maximumCapacity", "Maximum Capacity", "Maximum Capacity reported by System Information."],
    ["batteryCondition", "Condition", "Battery condition reported by System Information."],
    ["capacityRetention", "Raw Capacity Ratio", "Controller capacity divided by design capacity."],
    ["cycles", "Cycles", "Cycle count and rated cycle-life progress."],
  ],
  electrical: [
    ["temperature", "Temperature", "Current pack temperature."],
    ["voltage", "Voltage", "Current pack voltage."],
    ["current", "Current", "Signed charge or discharge current."],
    ["batteryPower", "Battery Flow", "Signed measured charge or discharge at the battery rail."],
    ["chargeTarget", "Controller Charge Target", "Configured charging target, not measured battery flow."],
    ["systemDraw", "Controller System Load", "Coarse system-load estimate reported by the battery controller."],
  ],
  adapter: [
    ["adapterRating", "Adapter Rating", "Advertised adapter wattage."],
    ["powerContract", "Adapter Electrical Capability", "Adapter voltage and current capability."],
    ["pdContract", "USB-C PD Contract", "Selected contract joined to an active physical USB-C port."],
  ],
  liveMeasurements: [
    ["liveInput", "Live Input", "Measured DC input power from the SMC."],
    ["dcInputRail", "DC Input Rail", "Measured DC input voltage and current."],
  ],
  processor: [
    ["cpuPower", "CPU", "Combined efficiency and performance core energy."],
    ["gpuPower", "GPU", "Graphics processor energy-model estimate."],
    ["anePower", "Neural Engine", "Apple Neural Engine activity and energy use."],
  ],
  memory: [
    ["memoryPower", "Memory", "DRAM energy-model estimate."],
    ["gpuMemoryPower", "GPU SRAM", "On-chip graphics memory energy."],
  ],
  display: [
    ["displayPower", "Built-in", "Internal display subsystem energy."],
    ["externalDisplayPower", "External", "External display pipeline energy."],
  ],
  diagnostics: [
    ["chargeInterruption", "Charging Hold", "Public temperature-related charge interruption reason."],
    ["adapterErrors", "Adapter Issues", "Insufficient power, foreign-object, or placement warnings."],
    ["publicHealthHint", "Public Health Hint", "Source-specific IOPowerSources health value."],
    ["capacityEstimated", "Estimated Capacity", "Whether the public capacity value is estimated."],
    ["batteryFailureModes", "Battery Issues", "Failure modes reported by the public power-source API."],
    ["optimizedCharging", "Optimized Charging", "Whether macOS charge protection is engaged."],
    ["lowPowerMode", "Low Power Mode", "Current system energy-saving state."],
    ["thermalPressure", "Thermal Pressure", "Public process-level thermal pressure state."],
    ["cpuPowerLimits", "CPU Power Limits", "Public CPU restrictions imposed by thermal or power constraints."],
    ["failureStatus", "Failure Status", "Permanent controller failure flags."],
    ["cellDisconnects", "Cell Disconnects", "Recorded battery cell disconnect events."],
    ["notChargingReason", "Not Charging Reason", "Raw reason flags when charging is blocked."],
    ["slowChargingReason", "Slow Charging Reason", "Raw reason flags when charging is limited."],
  ],
  cellVoltage: [
    ["cellVoltages", "Cell Voltages", "Individual cell-group voltages."],
    ["cellVoltageDelta", "Voltage Delta", "Spread between the highest and lowest cell."],
  ],
  cellCapacity: [
    ["learnedQmax", "Learned Qmax", "Controller-learned capacity per cell group."],
    ["qmaxDelta", "Qmax Delta", "Spread in learned cell capacities."],
  ],
  cellResistance: [
    ["resistance", "Resistance", "Raw learned cell resistance values."],
    ["resistanceDelta", "Resistance Delta", "Spread between resistance values."],
  ],
  gauge: [
    ["dailyChargeRange", "Daily Charge Range", "Lowest and highest state of charge today."],
    ["lastGaugeRelearn", "Last Gauge Relearn", "Cycle count at the last Qmax calibration."],
    ["dataFlashWrites", "Data Flash Writes", "Controller data-flash write counter."],
    ["rsenseOpenEvents", "Rsense Open Events", "Recorded current-sense open events."],
    ["qmaxDisqualification", "Qmax Disqualification", "Raw flags preventing capacity relearning."],
  ],
  lifetime: [
    ["lifetimeTemperatures", "Lifetime Temperatures", "Recorded minimum, average, and maximum."],
    ["packVoltageRange", "Pack Voltage Range", "Recorded lifetime voltage extremes."],
    ["peakCurrent", "Peak Charge / Discharge", "Recorded peak current in both directions."],
    ["operatingTime", "Operating Time", "Controller-reported lifetime operating hours."],
  ],
};

const menuSections = [
  {
    label: null,
    rows: [
      ["batteryLevel", "Battery", "100%"],
      ["status", "Status", "Fully Charged"],
      ["powerSource", "Power Source", "AC Power"],
      ["timeRemaining", "Time to Full", "42 min"],
    ],
  },
  {
    label: "Capacity",
    rows: [
      ["currentCharge", "Current Charge", "7,265 mAh"],
      ["fullCharge", "Full Charge", "7,553 mAh"],
      ["rawMaximum", "Raw Maximum", "7,309 mAh"],
      ["designCapacity", "Design Capacity", "8,579 mAh"],
      ["maximumCapacity", "Maximum Capacity", "88%"],
      ["batteryCondition", "Condition", "Normal"],
      ["capacityRetention", "Raw Capacity Ratio", "85.2%"],
      ["cycles", "Cycles", "104 / 1000 (10.4%)"],
    ],
  },
  {
    label: "Electrical",
    rows: [
      ["temperature", "Temperature", "30.9 °C"],
      ["voltage", "Voltage", "12.730 V"],
      ["current", "Current", "+0.000 A"],
      ["batteryPower", "Battery Flow", "+0.0 W"],
      ["chargeTarget", "Controller Charge Target", "61.0 W"],
      ["systemDraw", "Controller System Load", "46.6 W"],
    ],
  },
  {
    label: "Component Estimates",
    rows: [
      ["cpuPower", "CPU", "7.49 W"],
      ["gpuPower", "GPU", "0.39 W"],
      ["anePower", "Neural Engine", "0.00 W"],
      ["memoryPower", "Memory", "1.91 W"],
      ["gpuMemoryPower", "GPU SRAM", "0.00 W"],
      ["displayPower", "Built-in Display", "0.08 W"],
      ["externalDisplayPower", "External Displays", "0.34 W"],
    ],
  },
  {
    label: "Power Adapter",
    rows: [
      ["adapterRating", "Adapter Rating", "140 W"],
      ["powerContract", "Adapter Electrical Capability", "28.0V @ 5.0A"],
      ["pdContract", "USB-C PD Contract", "28.0V @ 5.0A"],
      ["liveInput", "Live Input", "41.7 W"],
      ["dcInputRail", "DC Input Rail", "27.75V @ 1.50A"],
    ],
  },
  {
    label: "Diagnostics",
    rows: [
      ["chargeInterruption", "Charging Hold", "None"],
      ["adapterErrors", "Adapter Issue", "None"],
      ["publicHealthHint", "Public Health Hint", "Good"],
      ["capacityEstimated", "Capacity Reading", "Measured"],
      ["batteryFailureModes", "Reported Battery Issues", "None"],
      ["optimizedCharging", "Optimized Charging", "Inactive"],
      ["lowPowerMode", "Low Power Mode", "Off"],
      ["thermalPressure", "Thermal Pressure", "Nominal"],
      ["cpuPowerLimits", "CPU Power Limits", "None"],
      ["failureStatus", "Failure Status", "0x00000000"],
      ["cellDisconnects", "Cell Disconnects", "0"],
      ["notChargingReason", "Not Charging Reason", "0x00400001"],
      ["slowChargingReason", "Slow Charging Reason", "0x00000000"],
    ],
  },
];

const internalSections = [
  {
    label: "Cells",
    rows: [
      ["cellVoltages", "Voltages", "4.244 · 4.239 · 4.242 V"],
      ["cellVoltageDelta", "Voltage Delta", "5 mV"],
      ["learnedQmax", "Learned Qmax", "7,567 · 7,531 · 7,548 mAh"],
      ["qmaxDelta", "Qmax Delta", "36 mAh"],
      ["resistance", "Resistance", "45 · 50 · 47"],
      ["resistanceDelta", "Resistance Delta", "5"],
      ["dailyChargeRange", "Daily Charge Range", "18% – 100%"],
      ["lastGaugeRelearn", "Last Gauge Relearn", "Cycle 96"],
      ["dataFlashWrites", "Data Flash Writes", "320"],
      ["rsenseOpenEvents", "Rsense Open Events", "2"],
      ["qmaxDisqualification", "Qmax Disqualification", "0x00000000"],
    ],
  },
  {
    label: "Lifetime",
    rows: [
      ["lifetimeTemperatures", "Min / Avg / Max Temp", "10.0 / 28.7 / 45.0 °C"],
      ["packVoltageRange", "Pack Voltage Range", "10.500 – 13.000 V"],
      ["peakCurrent", "Peak Charge / Discharge", "+6.000 / -9.500 A"],
      ["operatingTime", "Operating Time", "12,345 h"],
    ],
  },
];

const recommendedItemIds = new Set([
  "batteryLevel",
  "status",
  "powerSource",
  "timeRemaining",
  "currentCharge",
  "fullCharge",
  "maximumCapacity",
  "batteryCondition",
  "batteryPower",
  "cycles",
  "systemDraw",
  "adapterRating",
  "liveInput",
]);

const allItemIds = new Set(
  Object.values(menuOptions).flatMap((options) => options.map(([id]) => id)),
);

let visibleItemIds = new Set(recommendedItemIds);
let showsSectionTitles = false;
let selectedPreferencesPage = "main-menu";
let selectedDownloadArchitecture = defaultDownloadArchitecture;
const automationState = createAutomationState();

const icon = (contents) => `
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"
    stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
    ${contents}
  </svg>`;

FdIcons.register({
  "main-menu": icon('<rect x="3" y="5" width="18" height="14" rx="3"/><path d="M3 9h18"/>'),
  bolt: icon('<path d="m13 2-8 12h7l-1 8 8-12h-7l1-8Z"/>'),
  cpu: icon('<rect x="5" y="5" width="14" height="14" rx="2"/><path d="M9 1v4m6-4v4M9 19v4m6-4v4M1 9h4m14 0h4M1 15h4m14 0h4"/>'),
  waveform: icon('<path d="M3 12h4l2-7 4 14 2-7h6"/>'),
  automation: icon('<path d="M4 8.5h7m2 0h7M4 15.5h3m2 0h11"/><circle cx="12" cy="8.5" r="2"/><circle cx="8" cy="15.5" r="2"/>'),
  copy: icon('<rect x="8" y="8" width="11" height="11" rx="2"/><path d="M16 8V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h3"/>'),
  refresh: icon('<path d="M20 7v5h-5M4 17v-5h5"/><path d="M6.1 8.2A7 7 0 0 1 18.5 6L20 8M4 16l1.5 2a7 7 0 0 0 12.4-2.2"/>'),
  shield: icon('<path d="M12 3 5 6v5c0 4.4 2.8 8 7 10 4.2-2 7-5.6 7-10V6l-7-3Z"/><path d="M12 8v5m0 3h.01"/>'),
  info: icon('<circle cx="12" cy="12" r="9"/><path d="M12 11v6M12 7h.01"/>'),
});

const registerBrandIcons = async () => {
  const sources = {
    "flowing-day-ui-logo": "/flowing-day-ui-logo.svg",
    "bondry-logo": "/bondry-logo.svg",
  };
  const entries = await Promise.all(
    Object.entries(sources).map(async ([name, source]) => {
      const response = await fetch(source);
      if (!response.ok) throw new Error(`Could not load ${source}`);
      return [name, await response.text()];
    }),
  );
  FdIcons.register(Object.fromEntries(entries));
};

registerBrandIcons().catch((error) => console.error(error));

const navToggle = document.querySelector(".nav-toggle");
const navMenu = document.querySelector(".nav-menu");
const siteHeader = document.querySelector(".site-header");
const hero = document.querySelector(".hero");
const macDesktop = document.querySelector(".mac-desktop");
const menuTrigger = document.querySelector("#menu-bar-app");
const appMenu = document.querySelector("#app-menu");
const internalsPanel = document.querySelector("#internals-panel");
const internalsTrigger = document.querySelector("#open-internals");
const menuReadings = document.querySelector("#menu-readings");
const internalReadings = document.querySelector("#internal-readings");
const preferencesLayer = document.querySelector("#preferences-layer");
const preferencesMount = document.querySelector("#preferences-mount");
const preferencesWindowWrap = document.querySelector(".preferences-window-wrap");
const preferencesDragSurface = document.querySelector(
  "#preferences-drag-surface",
);
const downloadArchitectureButtons = document.querySelectorAll(
  "[data-download-architecture]",
);

let preferencesScale = 1;
let preferencesPosition = { x: 0, y: 0 };
let dragSession = null;

const selectedDownloadOption = () =>
  resolveDownloadOption(selectedDownloadArchitecture);

const updateDownloadSelection = () => {
  const option = selectedDownloadOption();
  document.querySelectorAll("[data-download-link]").forEach((link) => {
    link.href = option.url;
  });
  document.querySelectorAll("[data-download-label]").forEach((label) => {
    label.textContent = option.buttonLabel;
  });
  document
    .querySelectorAll("[data-download-architecture-label]")
    .forEach((label) => {
      label.textContent = option.label;
    });
  document.querySelectorAll("[data-download-detail]").forEach((detail) => {
    detail.textContent = option.detail;
  });
  document
    .querySelectorAll("[data-download-description]")
    .forEach((description) => {
      description.textContent = option.description;
    });
  downloadArchitectureButtons.forEach((button) => {
    button.setAttribute(
      "aria-pressed",
      String(button.dataset.downloadArchitecture === selectedDownloadArchitecture),
    );
  });
};

downloadArchitectureButtons.forEach((button) => {
  button.addEventListener("click", () => {
    selectedDownloadArchitecture = button.dataset.downloadArchitecture;
    updateDownloadSelection();
  });
});

navToggle?.addEventListener("click", () => {
  const isOpen = navToggle.getAttribute("aria-expanded") === "true";
  navToggle.setAttribute("aria-expanded", String(!isOpen));
  navMenu?.classList.toggle("is-open", !isOpen);
});

navMenu?.querySelectorAll("a").forEach((link) => {
  link.addEventListener("click", () => {
    navToggle?.setAttribute("aria-expanded", "false");
    navMenu.classList.remove("is-open");
  });
});

if (siteHeader && hero) {
  const headerObserver = new IntersectionObserver(
    ([entry]) => {
      const hasPassedHero =
        !entry.isIntersecting &&
        entry.boundingClientRect.bottom <= HEADER_CONDENSE_OFFSET;
      siteHeader.classList.toggle("is-condensed", hasPassedHero);
    },
    { rootMargin: `-${HEADER_CONDENSE_OFFSET}px 0px 0px` },
  );
  headerObserver.observe(hero);
}

const rowsWithSeparators = (rows) =>
  rows.join("<fd-separator></fd-separator>");

const switchRow = ([id, label, caption]) => `
  <fd-switch-row
    label="${label}"
    caption="${caption}"
    data-setting="${id}"
    ${visibleItemIds.has(id) ? "checked" : ""}
  ></fd-switch-row>`;

const switchSection = (label, options, footer = "") => `
  <fd-section label="${label}" ${footer ? `footer="${footer}"` : ""}>
    ${rowsWithSeparators(options.map(switchRow))}
  </fd-section>`;

const multiSelectRow = (label, caption, options) => `
  <fd-multi-select-row
    label="${label}"
    caption="${caption}"
    control-width="360"
    data-setting-group
  >
    ${options
      .map(
        ([id, optionLabel]) => `
          <fd-option
            value="${id}"
            label="${optionLabel}"
            data-setting="${id}"
            ${visibleItemIds.has(id) ? "selected" : ""}
          ></fd-option>`,
      )
      .join("")}
  </fd-multi-select-row>`;

const multiSelectSection = (label, caption, options, footer = "") => `
  <fd-section label="${label}" ${footer ? `footer="${footer}"` : ""}>
    ${multiSelectRow("Visible Readings", caption, options)}
  </fd-section>`;

const setEquals = (left, right) =>
  left.size === right.size && [...left].every((value) => right.has(value));

const selectedAttribute = (condition) => (condition ? "selected" : "");

const automationEnabled = () => isAutomationEnabled(automationState);

const automationBindAddress = () => resolveAutomationBindAddress(automationState);

const automationEndpoint = (path) =>
  resolveAutomationEndpoint(automationState, path);

const automationCopyButton = (label) => `
  <fd-icon-button
    label="${label}"
    symbol="copy"
    emphasis="soft"
    data-automation-action="requires-app"
  ></fd-icon-button>`;

const automationCapabilityRows = () =>
  rowsWithSeparators(
    automationCapabilities.map(
      ([id, label, caption]) => `
        <fd-switch-row
          label="${label}"
          caption="${caption}"
          data-automation-control="capability"
          data-capability="${id}"
          ${automationState.enabledCapabilities.has(id) ? "checked" : ""}
        ></fd-switch-row>`,
    ),
  );

const renderAutomationPage = () => `
  <fd-page
    page-id="automation"
    label="Automation"
    subtitle="Expose selected readings to local tools."
    symbol="automation"
  >
    <fd-pane-stack>
      <fd-section
        label="Automation Access"
        footer="Both interfaces are off by default. Enable only what you plan to use."
      >
        <fd-multi-select-row
          label="Interfaces"
          caption="MCP and REST can be enabled independently."
          control-width="260"
          data-automation-control="interfaces"
        >
          <fd-option
            value="mcp"
            label="MCP"
            ${selectedAttribute(automationState.interfaces.has("mcp"))}
          ></fd-option>
          <fd-option
            value="rest"
            label="REST"
            ${selectedAttribute(automationState.interfaces.has("rest"))}
          ></fd-option>
        </fd-multi-select-row>
        <fd-dependent-rows
          data-automation-dependent="preview-note"
          ${automationEnabled() ? "visible" : ""}
        >
          <fd-empty-row
            symbol="info"
            message="Preview mode: these controls are interactive, but this page does not start a local server."
          ></fd-empty-row>
        </fd-dependent-rows>
      </fd-section>

      <fd-dependent-rows
        data-automation-dependent="body"
        no-separator
        ${automationEnabled() ? "visible" : ""}
      >
        <fd-pane-stack>
          <fd-section label="Server">
            <fd-row
              label="Port"
              caption="Use an unprivileged port from 1024 through 65535."
            >
              <div slot="trailing" class="automation-actions">
                <fd-text-field
                  class="automation-port-field"
                  label="Port"
                  value="${automationState.port}"
                  data-automation-control="port"
                ></fd-text-field>
                <fd-icon-button
                  label="Randomize Port"
                  symbol="refresh"
                  emphasis="soft"
                  data-automation-action="randomize-port"
                ></fd-icon-button>
              </div>
            </fd-row>
            <fd-separator></fd-separator>
            <fd-slider-row
              label="Request Limit"
              caption="Maximum requests per minute from each client."
              min="1"
              max="120"
              step="1"
              value="${automationState.requestsPerMinute}"
              data-automation-control="request-limit"
            ></fd-slider-row>
            <fd-separator></fd-separator>
            <fd-switch-row
              label="Require Access Token"
              caption="Require a Bearer token for every MCP and REST request."
              data-automation-control="authentication"
              ${automationState.authenticationRequired ? "checked" : ""}
            ></fd-switch-row>
            <fd-dependent-rows
              data-automation-dependent="authentication"
              ${automationState.authenticationRequired ? "visible" : ""}
            >
              <fd-row
                label="Access Token"
                caption="Stored in Keychain. Regenerating it disconnects existing clients."
              >
                <div slot="trailing" class="automation-actions">
                  <span class="automation-token">••••••••••••••••</span>
                  ${automationCopyButton("Copy Access Token")}
                  <fd-icon-button
                    label="Regenerate Access Token"
                    symbol="refresh"
                    emphasis="soft"
                    data-automation-action="requires-app"
                  ></fd-icon-button>
                </div>
              </fd-row>
            </fd-dependent-rows>
            <fd-separator></fd-separator>
            <fd-value-row
              label="Status"
              value="Preview only"
            ></fd-value-row>
            <fd-separator></fd-separator>
            <fd-expandable-row
              label="Advanced"
              data-automation-control="advanced"
              ${automationState.showsAdvanced ? "expanded" : ""}
            ></fd-expandable-row>
            <fd-dependent-rows
              data-automation-dependent="advanced"
              ${automationState.showsAdvanced ? "visible" : ""}
            >
              <fd-segmented-row
                label="Listen On"
                caption="This Mac Only is the safest choice."
                control-width="320"
                value="${automationState.networkScope}"
                data-automation-control="network-scope"
              >
                <fd-option value="thisMac" label="This Mac Only"></fd-option>
                <fd-option value="allInterfaces" label="All Interfaces"></fd-option>
                <fd-option value="selectedInterface" label="One Interface"></fd-option>
              </fd-segmented-row>
              <fd-separator></fd-separator>
              <fd-value-row
                label="Bind Address"
                value="${automationBindAddress()}"
                data-automation-value="bind-address"
              ></fd-value-row>
              <fd-dependent-rows
                data-automation-dependent="network-interface"
                ${automationState.networkScope === "selectedInterface" ? "visible" : ""}
              >
                <fd-popup-row
                  label="Network Interface"
                  min-width="220"
                  value="en0"
                  data-automation-control="network-interface"
                >
                  <fd-option value="en0" label="en0 · 192.168.1.42"></fd-option>
                  <fd-option value="en1" label="en1 · 192.168.1.43"></fd-option>
                </fd-popup-row>
              </fd-dependent-rows>
              <fd-dependent-rows
                data-automation-dependent="network-warning"
                ${automationState.networkScope !== "thisMac" ? "visible" : ""}
              >
                <fd-empty-row
                  symbol="shield"
                  message="Network access uses unencrypted HTTP. Use only a trusted network."
                ></fd-empty-row>
              </fd-dependent-rows>
            </fd-dependent-rows>
          </fd-section>

          <fd-section
            label="Exposed Readings"
            footer="A reading is exposed only when it is enabled here and visible in the menu preferences."
          >
            ${automationCapabilityRows()}
          </fd-section>

          <fd-dependent-rows
            data-automation-dependent="mcp"
            no-separator
            ${automationState.interfaces.has("mcp") ? "visible" : ""}
          >
            <fd-section label="MCP Connections">
              <fd-value-row
                label="MCP Endpoint"
                value="${automationEndpoint("/mcp")}"
                data-automation-value="mcp-endpoint"
              >
                <span slot="trailing">${automationCopyButton("Copy MCP Endpoint")}</span>
              </fd-value-row>
              <fd-separator></fd-separator>
              <fd-value-row
                label="Claude Code"
                value="Streamable HTTP install command"
              >
                <span slot="trailing">${automationCopyButton("Copy Claude Code Command")}</span>
              </fd-value-row>
            </fd-section>
          </fd-dependent-rows>

          <fd-dependent-rows
            data-automation-dependent="rest"
            no-separator
            ${automationState.interfaces.has("rest") ? "visible" : ""}
          >
            <fd-section label="REST API">
              <fd-value-row
                label="Base URL"
                value="${automationEndpoint("/api/v1")}"
                data-automation-value="rest-endpoint"
              >
                <span slot="trailing">${automationCopyButton("Copy REST Base URL")}</span>
              </fd-value-row>
              <fd-separator></fd-separator>
              <fd-value-row
                label="Example"
                value="Invoke the snapshot capability"
              >
                <span slot="trailing">${automationCopyButton("Copy REST Example")}</span>
              </fd-value-row>
            </fd-section>
          </fd-dependent-rows>

          <fd-section label="Use Automation">
            <fd-button-row
              label="Run MCP and REST locally"
              caption="Install Battakorey to start the server and create secure credentials in Keychain."
              button-label="Download App"
              prominent
              data-automation-action="download"
            ></fd-button-row>
          </fd-section>
        </fd-pane-stack>
      </fd-dependent-rows>
    </fd-pane-stack>
  </fd-page>`;

const renderPreferences = () => {
  if (!preferencesMount) return;

  const usesRecommendedPreset =
    !showsSectionTitles && setEquals(visibleItemIds, recommendedItemIds);
  const usesAllPreset = showsSectionTitles && setEquals(visibleItemIds, allItemIds);

  preferencesMount.innerHTML = `
    <fd-preferences-window
      id="preferences-window"
      app-name="Battakorey"
      preferences-title="Preferences"
      page="${selectedPreferencesPage}"
    >
      <img slot="app-icon" src="/icon.png" alt="" />

      <fd-page-group label="Menu Display">
        <fd-page
          page-id="main-menu"
          label="Main Menu"
          subtitle="Choose the battery details shown at a glance."
          symbol="main-menu"
        >
          <fd-pane-stack>
            <fd-section
              label="Presets"
              footer="Presets only change menu presentation. No battery data is collected."
            >
              <fd-row
                label="Visible information"
                caption="Start focused or expose every available reading."
              >
                <div slot="trailing" class="preference-actions">
                  <fd-button
                    label="Recommended"
                    data-preset="recommended"
                    ${usesRecommendedPreset ? "prominent" : ""}
                  ></fd-button>
                  <fd-button
                    label="Show Everything"
                    data-preset="all"
                    ${usesAllPreset ? "prominent" : ""}
                  ></fd-button>
                </div>
              </fd-row>
            </fd-section>

            <fd-section label="Layout">
              <fd-switch-row
                label="Section Titles"
                caption="Show category headings such as Capacity and Electrical."
                data-setting="sectionTitles"
                ${showsSectionTitles ? "checked" : ""}
              ></fd-switch-row>
            </fd-section>

            ${switchSection("Status", menuOptions.status)}
            ${switchSection("Capacity", menuOptions.capacity)}
            ${switchSection("Electrical", menuOptions.electrical)}
          </fd-pane-stack>
        </fd-page>

        <fd-page
          page-id="charging"
          label="Power &amp; Charging"
          subtitle="Control adapter and charging diagnostics."
          symbol="bolt"
        >
          <fd-pane-stack>
            <fd-section label="Power Adapter">
              ${rowsWithSeparators([
                ...menuOptions.adapter.map(switchRow),
                multiSelectRow(
                  "Live Measurements",
                  "Choose the measured DC input values shown in the menu.",
                  menuOptions.liveMeasurements,
                ),
              ])}
            </fd-section>
            ${switchSection("Diagnostics", menuOptions.diagnostics)}
          </fd-pane-stack>
        </fd-page>
      </fd-page-group>

      <fd-page-group label="Advanced">
        <fd-page
          page-id="component-power"
          label="Component Power"
          subtitle="Choose live hardware energy counters shown in the menu."
          symbol="cpu"
        >
          <fd-pane-stack>
            ${multiSelectSection(
              "Processor",
              "Choose the CPU, GPU, and Neural Engine estimates shown in the menu.",
              menuOptions.processor,
            )}
            ${multiSelectSection(
              "Memory",
              "Choose the system memory and GPU SRAM estimates shown in the menu.",
              menuOptions.memory,
            )}
            ${multiSelectSection(
              "Display",
              "Choose the built-in and external display estimates shown in the menu.",
              menuOptions.display,
              "Component readings are sampled once per second through IOReport and disappear when a channel is unavailable.",
            )}
          </fd-pane-stack>
        </fd-page>

        <fd-page
          page-id="battery-internals"
          label="Battery Internals"
          subtitle="Choose controller data for the nested internals menu."
          symbol="waveform"
        >
          <fd-pane-stack>
            <fd-section label="Cell Measurements">
              ${rowsWithSeparators([
                multiSelectRow(
                  "Voltage",
                  "Choose the individual cell voltages and voltage spread shown in the menu.",
                  menuOptions.cellVoltage,
                ),
                multiSelectRow(
                  "Learned Capacity",
                  "Choose the learned Qmax values and capacity spread shown in the menu.",
                  menuOptions.cellCapacity,
                ),
                multiSelectRow(
                  "Resistance",
                  "Choose the learned resistance values and resistance spread shown in the menu.",
                  menuOptions.cellResistance,
                ),
              ])}
            </fd-section>
            ${switchSection("Gauge History", menuOptions.gauge)}
            ${switchSection("Lifetime", menuOptions.lifetime)}
          </fd-pane-stack>
        </fd-page>

        ${renderAutomationPage()}
      </fd-page-group>

      <fd-page-group>
        <fd-page
          page-id="about"
          label="About"
          subtitle="Version and project information."
          symbol="info"
        >
          <fd-pane-stack>
            <div class="preferences-about-intro">
              <img src="/icon.png" alt="" />
              <div>
                <strong>Battakorey</strong>
                <span>Version 2.4.0</span>
                <p>A tiny Takodachi in your menu bar with detailed Mac battery telemetry.</p>
              </div>
            </div>
            <fd-section label="Details">
              <fd-value-row
                label="Battery Data"
                value="IOPowerSources · AppleSmartBattery · AppleSMC · IOReport"
              ></fd-value-row>
              <fd-separator></fd-separator>
              <fd-value-row label="Requirements" value="macOS 13&nbsp;or&nbsp;later"></fd-value-row>
            </fd-section>
            <fd-section label="Acknowledgements">
              <fd-link-row
                symbol="flowing-day-ui-logo"
                label="FlowingDayUI"
                caption="Reusable preferences windows and macOS interface components."
                button-label="GitHub"
                href="https://github.com/cocoa-xu/flowing-day-ui"
                help="Open FlowingDayUI on GitHub"
              ></fd-link-row>
              <fd-separator></fd-separator>
              <fd-link-row
                symbol="bondry-logo"
                label="Bondry"
                caption="Secure automation runtime for MCP, REST, permissions, and audit."
                button-label="GitHub"
                href="https://github.com/bondry-dev/bondry"
                help="Open Bondry on GitHub"
              ></fd-link-row>
            </fd-section>
            <p class="preferences-copyright">Copyright © 2026 Cocoa</p>
          </fd-pane-stack>
        </fd-page>
      </fd-page-group>
    </fd-preferences-window>
    <fd-dialog
      id="automation-download-dialog"
      heading="Automation runs in Battakorey"
      message="This browser page previews the settings, but MCP and REST need the downloaded Mac app to run a local server and store credentials securely."
      symbol="automation"
      tone="accent"
      confirm-label="Download Battakorey"
      cancel-label="Keep Exploring"
    ></fd-dialog>`;

  configureAutomationControls();
};

const setAutomationDependentVisibility = (name, visible) => {
  const element = preferencesMount?.querySelector(
    `[data-automation-dependent="${name}"]`,
  );
  if (element) element.visible = visible;
};

const setAutomationValue = (name, value) => {
  const element = preferencesMount?.querySelector(
    `[data-automation-value="${name}"]`,
  );
  if (element) element.value = value;
};

const updateAutomationPresentation = () => {
  const isEnabled = automationEnabled();
  setAutomationDependentVisibility("preview-note", isEnabled);
  setAutomationDependentVisibility("body", isEnabled);
  setAutomationDependentVisibility(
    "authentication",
    automationState.authenticationRequired,
  );
  setAutomationDependentVisibility("advanced", automationState.showsAdvanced);
  setAutomationDependentVisibility(
    "network-interface",
    automationState.networkScope === "selectedInterface",
  );
  setAutomationDependentVisibility(
    "network-warning",
    automationState.networkScope !== "thisMac",
  );
  setAutomationDependentVisibility("mcp", automationState.interfaces.has("mcp"));
  setAutomationDependentVisibility("rest", automationState.interfaces.has("rest"));

  setAutomationValue("bind-address", automationBindAddress());
  setAutomationValue("mcp-endpoint", automationEndpoint("/mcp"));
  setAutomationValue("rest-endpoint", automationEndpoint("/api/v1"));
};

function configureAutomationControls() {
  const requestLimit = preferencesMount?.querySelector(
    '[data-automation-control="request-limit"]',
  );
  if (requestLimit) {
    requestLimit.format = (value) => `${Math.round(value)} per minute`;
  }
  updateAutomationPresentation();
}

const showAutomationDownloadDialog = () => {
  preferencesMount?.querySelector("#automation-download-dialog")?.showModal();
};

const handleAutomationAction = (action) => {
  switch (action) {
    case "download":
      window.location.assign(selectedDownloadOption().url);
      break;
    case "randomize-port": {
      automationState.port = randomAutomationPort(automationState.port);
      const portField = preferencesMount?.querySelector(
        '[data-automation-control="port"]',
      );
      if (portField) portField.value = String(automationState.port);
      updateAutomationPresentation();
      break;
    }
    case "requires-app":
      showAutomationDownloadDialog();
      break;
  }
};

const handleAutomationChange = (control, detail) => {
  switch (control.dataset.automationControl) {
    case "interfaces":
      automationState.interfaces = new Set(detail.values ?? []);
      break;
    case "request-limit":
      automationState.requestsPerMinute = Math.round(detail.valueAsNumber);
      break;
    case "authentication":
      automationState.authenticationRequired = detail.checked === true;
      break;
    case "advanced":
      automationState.showsAdvanced = detail.checked === true;
      break;
    case "network-scope":
      automationState.networkScope = detail.value;
      break;
    case "capability":
      if (detail.checked === true) {
        automationState.enabledCapabilities.add(control.dataset.capability);
      } else {
        automationState.enabledCapabilities.delete(control.dataset.capability);
      }
      break;
    case "port": {
      const port = Number.parseInt(detail.value, 10);
      if (port >= 1_024 && port <= 65_535) automationState.port = port;
      break;
    }
  }
  updateAutomationPresentation();
};

const renderMenuRows = (sections) => {
  const availableSections = sections
    .map((section) => ({
      ...section,
      rows: section.rows.filter(([id]) => visibleItemIds.has(id)),
    }))
    .filter((section) => section.rows.length > 0);

  if (availableSections.length === 0) {
    return '<p class="app-menu-empty">No Readings Selected</p>';
  }

  return availableSections
    .map(
      (section) => `
        <section class="app-menu-section">
          ${
            showsSectionTitles && section.label
              ? `<p class="app-menu-heading">${section.label}</p>`
              : ""
          }
          ${section.rows
            .map(
              ([, label, value]) => `
                <div class="app-menu-row">
                  <span>${label}</span>
                  <strong>${value}</strong>
                </div>`,
            )
            .join("")}
        </section>`,
    )
    .join("");
};

const hasVisibleReadings = (sections) =>
  sections.some((section) =>
    section.rows.some(([id]) => visibleItemIds.has(id)),
  );

const renderMenu = () => {
  if (menuReadings) menuReadings.innerHTML = renderMenuRows(menuSections);
  const showsInternals = hasVisibleReadings(internalSections);
  if (internalsTrigger) internalsTrigger.hidden = !showsInternals;

  if (!showsInternals) {
    if (internalsPanel) internalsPanel.hidden = true;
    internalsTrigger?.setAttribute("aria-expanded", "false");
    internalsTrigger?.classList.remove("is-active");
  }

  if (internalReadings && showsInternals) {
    internalReadings.innerHTML = renderMenuRows(internalSections);
  }
};

const updatePresetButtons = () => {
  const recommendedButton = preferencesMount?.querySelector(
    '[data-preset="recommended"]',
  );
  const allButton = preferencesMount?.querySelector('[data-preset="all"]');
  if (recommendedButton) {
    recommendedButton.prominent =
      !showsSectionTitles && setEquals(visibleItemIds, recommendedItemIds);
  }
  if (allButton) {
    allButton.prominent =
      showsSectionTitles && setEquals(visibleItemIds, allItemIds);
  }
};

const closeMenu = () => {
  if (!appMenu || !menuTrigger || !macDesktop) return;
  appMenu.hidden = true;
  menuTrigger.setAttribute("aria-expanded", "false");
  macDesktop.dataset.state = preferencesLayer?.hidden ? "idle" : "preferences";
  if (internalsPanel) internalsPanel.hidden = true;
  internalsTrigger?.setAttribute("aria-expanded", "false");
  internalsTrigger?.classList.remove("is-active");
};

const openMenu = () => {
  if (!appMenu || !menuTrigger || !macDesktop) return;
  appMenu.hidden = false;
  menuTrigger.setAttribute("aria-expanded", "true");
  macDesktop.dataset.state = "menu";
};

const openPreferences = () => {
  closeMenu();
  if (!preferencesLayer || !macDesktop) return;
  preferencesLayer.hidden = false;
  preferencesLayer.setAttribute("aria-hidden", "false");
  macDesktop.classList.add("preferences-open");
  macDesktop.dataset.state = "preferences";
};

const closePreferences = () => {
  if (!preferencesLayer || !macDesktop) return;
  preferencesLayer.hidden = true;
  preferencesLayer.setAttribute("aria-hidden", "true");
  macDesktop.classList.remove("preferences-open");
  macDesktop.dataset.state = appMenu?.hidden ? "idle" : "menu";
};

const applyPreset = (preset) => {
  if (preset === "recommended") {
    visibleItemIds = new Set(recommendedItemIds);
    showsSectionTitles = false;
  } else {
    visibleItemIds = new Set(allItemIds);
    showsSectionTitles = true;
  }
  renderMenu();
  renderPreferences();
};

menuTrigger?.addEventListener("click", () => {
  if (appMenu?.hidden) openMenu();
  else closeMenu();
});

document.querySelector("#open-preferences")?.addEventListener("click", openPreferences);
internalsTrigger?.addEventListener("click", () => {
  if (!internalsPanel) return;
  const opensInternals = internalsPanel.hidden;
  internalsPanel.hidden = !opensInternals;
  internalsTrigger.setAttribute("aria-expanded", String(opensInternals));
  internalsTrigger.classList.toggle("is-active", opensInternals);
});

preferencesMount?.addEventListener("fd-close", (event) => {
  const closesPreferences = event
    .composedPath()
    .some((element) => element.id === "preferences-window");
  if (closesPreferences) closePreferences();
});
preferencesMount?.addEventListener("fd-page-change", (event) => {
  selectedPreferencesPage = event.detail.page;
});
preferencesMount?.addEventListener("fd-activate", (event) => {
  const path = event.composedPath();
  const automationAction = path.find(
    (element) =>
      element instanceof HTMLElement && element.dataset.automationAction,
  );
  if (automationAction) {
    handleAutomationAction(automationAction.dataset.automationAction);
    return;
  }

  const presetButton = path.find(
    (element) => element instanceof HTMLElement && element.dataset.preset,
  );
  if (presetButton) applyPreset(presetButton.dataset.preset);
});
preferencesMount?.addEventListener("fd-change", (event) => {
  const path = event.composedPath();
  const automationControl = path.find(
    (element) =>
      element instanceof HTMLElement && element.dataset.automationControl,
  );
  if (automationControl) {
    handleAutomationChange(automationControl, event.detail);
    return;
  }

  const settingGroup = path.find(
    (element) =>
      element instanceof HTMLElement && element.hasAttribute("data-setting-group"),
  );

  if (settingGroup) {
    const selectedValues = new Set(event.detail.values ?? []);
    settingGroup.querySelectorAll("fd-option[data-setting]").forEach((option) => {
      if (selectedValues.has(option.dataset.setting)) {
        visibleItemIds.add(option.dataset.setting);
      } else {
        visibleItemIds.delete(option.dataset.setting);
      }
    });
  } else {
    const setting = path.find(
      (element) => element instanceof HTMLElement && element.dataset.setting,
    );
    if (!setting) return;

    if (setting.dataset.setting === "sectionTitles") {
      showsSectionTitles = event.detail.checked === true;
    } else if (event.detail.checked === true) {
      visibleItemIds.add(setting.dataset.setting);
    } else {
      visibleItemIds.delete(setting.dataset.setting);
    }
  }

  renderMenu();
  updatePresetButtons();
});
preferencesMount?.addEventListener("fd-confirm", (event) => {
  const confirmsDownload = event
    .composedPath()
    .some((element) => element.id === "automation-download-dialog");
  if (confirmsDownload) window.location.assign(selectedDownloadOption().url);
});

document.addEventListener("keydown", (event) => {
  if (event.key !== "Escape") return;
  if (appMenu && !appMenu.hidden) closeMenu();
  else if (preferencesLayer && !preferencesLayer.hidden) closePreferences();
});

const updatePreferencesScale = () => {
  if (!macDesktop || !preferencesWindowWrap) return;
  const availableWidth = macDesktop.clientWidth - PREFERENCES_INSET.horizontal;
  const availableHeight = macDesktop.clientHeight - PREFERENCES_INSET.vertical;
  preferencesScale = Math.min(
    1,
    availableWidth / PREFERENCES_SIZE.width,
    availableHeight / PREFERENCES_SIZE.height,
  );
  preferencesWindowWrap.style.setProperty(
    "--preferences-scale",
    String(preferencesScale),
  );
  updatePreferencesPosition();
};

const constrainedPreferencesPosition = (position) => {
  if (!preferencesLayer) return position;
  const horizontalLimit = Math.max(
    0,
    (preferencesLayer.clientWidth - PREFERENCES_SIZE.width * preferencesScale) / 2,
  );
  const verticalLimit = Math.max(
    0,
    (preferencesLayer.clientHeight - PREFERENCES_SIZE.height * preferencesScale) / 2,
  );
  return {
    x: Math.min(Math.max(position.x, -horizontalLimit), horizontalLimit),
    y: Math.min(Math.max(position.y, -verticalLimit), verticalLimit),
  };
};

function updatePreferencesPosition() {
  if (!preferencesWindowWrap) return;
  preferencesPosition = constrainedPreferencesPosition(preferencesPosition);
  preferencesWindowWrap.style.left = `calc(50% + ${preferencesPosition.x}px)`;
  preferencesWindowWrap.style.top = `calc(50% + ${preferencesPosition.y}px)`;
}

preferencesDragSurface?.addEventListener("pointerdown", (event) => {
  if (event.button !== 0) return;
  dragSession = {
    pointerId: event.pointerId,
    pointerX: event.clientX,
    pointerY: event.clientY,
    windowX: preferencesPosition.x,
    windowY: preferencesPosition.y,
  };
  preferencesDragSurface.setPointerCapture(event.pointerId);
  preferencesWindowWrap?.classList.add("is-dragging");
});

preferencesDragSurface?.addEventListener("pointermove", (event) => {
  if (!dragSession || dragSession.pointerId !== event.pointerId) return;
  preferencesPosition = constrainedPreferencesPosition({
    x: dragSession.windowX + event.clientX - dragSession.pointerX,
    y: dragSession.windowY + event.clientY - dragSession.pointerY,
  });
  updatePreferencesPosition();
});

const endPreferencesDrag = (event) => {
  if (!dragSession || dragSession.pointerId !== event.pointerId) return;
  preferencesDragSurface?.releasePointerCapture(event.pointerId);
  preferencesWindowWrap?.classList.remove("is-dragging");
  dragSession = null;
};

preferencesDragSurface?.addEventListener("pointerup", endPreferencesDrag);
preferencesDragSurface?.addEventListener("pointercancel", endPreferencesDrag);

const revealObserver = new IntersectionObserver(
  (entries, observer) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return;
      entry.target.classList.add("is-visible");
      observer.unobserve(entry.target);
    });
  },
  { threshold: 0.12 },
);

document
  .querySelectorAll("[data-reveal]")
  .forEach((element) => revealObserver.observe(element));

const preferencesResizeObserver = new ResizeObserver(updatePreferencesScale);
if (macDesktop) preferencesResizeObserver.observe(macDesktop);

const year = document.querySelector("#year");
if (year) year.textContent = String(new Date().getFullYear());

renderPreferences();
renderMenu();
updateDownloadSelection();
updatePreferencesScale();
