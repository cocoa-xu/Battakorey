export const automationCapabilities = Object.freeze([
  ["status", "Status", "Current charge, charging state, power source, and time remaining."],
  ["capacity", "Capacity", "Charge capacity, battery health, and cycle information."],
  ["electrical", "Electrical", "Battery voltage, current, temperature, and power flow."],
  ["power-adapter", "Power Adapter", "Adapter capability, negotiated contracts, and live input readings."],
  ["component-power", "Component Power", "CPU, GPU, memory, and display power estimates."],
  ["diagnostics", "Diagnostics", "Charging, thermal, health, and controller diagnostics."],
  ["battery-internals", "Battery Internals", "Cell, gauge history, and lifetime controller readings."],
]);

export const createAutomationState = () => ({
  interfaces: new Set(),
  port: 18_761,
  requestsPerMinute: 30,
  authenticationRequired: true,
  enabledCapabilities: new Set(automationCapabilities.map(([id]) => id)),
  showsAdvanced: false,
  networkScope: "thisMac",
});

export const isAutomationEnabled = (state) => state.interfaces.size > 0;

export const resolveAutomationBindAddress = (state) => {
  switch (state.networkScope) {
    case "allInterfaces":
      return "0.0.0.0";
    case "selectedInterface":
      return "192.168.1.42";
    default:
      return "127.0.0.1";
  }
};

export const resolveAutomationEndpoint = (state, path) => {
  const host =
    state.networkScope === "selectedInterface"
      ? resolveAutomationBindAddress(state)
      : "127.0.0.1";
  return `http://${host}:${state.port}${path}`;
};

export const randomAutomationPort = (currentPort, random = Math.random) => {
  const minimum = 49_152;
  const maximum = 65_535;
  const candidate = Math.floor(random() * (maximum - minimum + 1)) + minimum;
  if (candidate !== currentPort) return candidate;
  return candidate === maximum ? minimum : candidate + 1;
};
