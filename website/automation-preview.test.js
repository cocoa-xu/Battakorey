import assert from "node:assert/strict";
import test from "node:test";

import {
  automationCapabilities,
  createAutomationState,
  isAutomationEnabled,
  randomAutomationPort,
  resolveAutomationBindAddress,
  resolveAutomationEndpoint,
} from "./automation-preview.js";

test("automation preview starts with safe application defaults", () => {
  const state = createAutomationState();

  assert.equal(isAutomationEnabled(state), false);
  assert.equal(state.authenticationRequired, true);
  assert.equal(state.port, 18_761);
  assert.equal(state.requestsPerMinute, 30);
  assert.deepEqual(
    state.enabledCapabilities,
    new Set(automationCapabilities.map(([id]) => id)),
  );
});

test("automation endpoints follow the selected network scope", () => {
  const state = createAutomationState();
  state.interfaces.add("mcp");

  assert.equal(isAutomationEnabled(state), true);
  assert.equal(resolveAutomationBindAddress(state), "127.0.0.1");
  assert.equal(
    resolveAutomationEndpoint(state, "/mcp"),
    "http://127.0.0.1:18761/mcp",
  );

  state.networkScope = "allInterfaces";
  assert.equal(resolveAutomationBindAddress(state), "0.0.0.0");
  assert.equal(
    resolveAutomationEndpoint(state, "/api/v1"),
    "http://127.0.0.1:18761/api/v1",
  );

  state.networkScope = "selectedInterface";
  assert.equal(resolveAutomationBindAddress(state), "192.168.1.42");
  assert.equal(
    resolveAutomationEndpoint(state, "/mcp"),
    "http://192.168.1.42:18761/mcp",
  );
});

test("random ports stay dynamic and inside the unprivileged range", () => {
  assert.equal(randomAutomationPort(49_152, () => 0), 49_153);
  assert.equal(
    randomAutomationPort(65_535, () => 1 - Number.EPSILON),
    49_152,
  );

  const port = randomAutomationPort(18_761, () => 0.5);
  assert.ok(port >= 49_152);
  assert.ok(port <= 65_535);
});
