<div align="center">
    <img src="assets/icon.png" width="256" height="256">
    <h1>Battakorey</h1>
    <p>
        <b>Wah! Battakorey for Takodachi!</b>
  </p>
    <br>
    <br>
    <br>
</div>


# Battakorey

Recommended Settings:

![Battakorey](assets/Battakorey-Recommended.png)

All possible stats:

![Battakorey-All](assets/Battakorey-All.png)

Preferences:

![Battakorey-Preferences](assets/preferences.png)

Requires macOS 13 or later.

The purple colour and the face of the tako indicates the remaining percentage of your battakorey.

#### 70%-100%

![Happy](assets/happy.png)

#### 40%-70%

![Normal](assets/normal.png)

#### 20%-40%

![Hungry](assets/hungry.png)

#### 0%-20%

![Starving](assets/starving.png)

#### In charging

While in charging, there will be Tako's favourite tentacle beside it!

![Battakorey-Charging](assets/Battakorey-Charging.png)

## Battery data

Open the menu bar item to see live status, capacity, electrical, adapter, and diagnostic data. Preferences controls every optional row, while the Battery Internals submenu adds per-cell voltage, learned capacity, resistance, daily charge range, gauge relearn state, controller counters, and lifetime extremes when the battery controller exposes them.

Battakorey combines macOS power-source APIs with read-only `AppleSmartBattery` IORegistry properties. It also reads the `PPBR`, `VD0R`, `ID0R`, and `PDTR` AppleSMC keys for responsive battery and input power measurements. The optional Component Power section samples CPU, GPU, Neural Engine, memory, and display energy through IOReport.

AppleSMC and IOReport are undocumented interfaces that vary by hardware and macOS release. IOReport is loaded at runtime, and unavailable channels or implausible values are omitted instead of causing the app to fail.

On desktop Macs without a built-in battery, Battakorey keeps system and input-power telemetry available while omitting battery-only values reported as zero by the hardware registry. If a confirmed MacBook does not report its expected battery, the menu shows a warning that can be disabled in Preferences.

The additional telemetry does not require root access or disabling System Integrity Protection. The app is intentionally not sandboxed, which makes this build unsuitable for Mac App Store distribution.

## Automation

Battakorey can expose its current readings to local tools through MCP and a
versioned REST API. Both interfaces are disabled by default and can be enabled
independently under **Preferences > Automation**. Bearer token authentication is
enabled by default, and the token is stored in Keychain. Authentication can be
disabled explicitly when a trusted local setup does not need it.

The server listens on `127.0.0.1:18761` by default. Preferences also provides a
random private port, per-client request limits, token regeneration, and advanced
network binding. Network access uses unencrypted HTTP and should only be enabled
on a trusted network.

MCP uses Streamable HTTP at:

```text
http://127.0.0.1:18761/mcp
```

REST resources are available below `http://127.0.0.1:18761/api/v1`:

- `GET /api/v1` describes the API and currently exposed capabilities.
- `GET /api/v1/snapshot` returns every exposed reading.
- `GET /api/v1/capabilities` describes the exposed capability groups.
- `GET /api/v1/readings/{capability}` returns one capability group.

Every reading has a stable identifier, a machine-readable value and unit when
available, and the same formatted value shown in Battakorey. Exposure is the
intersection of the items enabled in the menu preferences and the capability
groups enabled in Automation, so enabling the server never bypasses the user's
existing visibility choices.

### References

[WhatBattery](https://github.com/darrylmorley/whatbattery) was consulted as a
reference while researching battery telemetry exposed by macOS.

## Development

Install XcodeGen and generate the Xcode project before building:

```sh
brew install xcodegen
./scripts/generate-project.sh
```

For a stable local code signature, copy `.battakorey-signing.example` to
`.battakorey-signing.local` and select a team and signing identity available in
your login keychain. The local file and generated Xcode project are ignored by
Git. Explicit `DEVELOPMENT_TEAM` and `CODE_SIGN_IDENTITY` environment variables
take precedence, allowing CI to inject signing credentials.

The test suite uses mocked IORegistry, power-source, adapter, SMC, and IOReport
payloads. It can run on CI machines without a battery:

```sh
./scripts/generate-project.sh
xcodebuild -project battakorey.xcodeproj -scheme battakorey -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO test
```
