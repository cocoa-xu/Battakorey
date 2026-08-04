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
![Battakorey](assets/Battakorey.png)

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

Open the menu bar item to see live status, capacity, electrical, adapter, and diagnostic data. The Battery Internals submenu adds per-cell voltage, learned capacity, resistance, daily charge range, gauge relearn state, controller counters, and lifetime extremes when the battery controller exposes them.

Battakorey combines macOS power-source APIs with read-only `AppleSmartBattery` IORegistry properties. It also reads the `PPBR`, `VD0R`, `ID0R`, and `PDTR` AppleSMC keys for responsive battery and input power measurements. These undocumented values vary by hardware and macOS release, so unavailable or implausible fields are omitted instead of causing the app to fail.

The additional telemetry does not require root access or disabling System Integrity Protection. The app is intentionally not sandboxed, which makes this build unsuitable for Mac App Store distribution.

### References

[WhatBattery](https://github.com/darrylmorley/whatbattery) was consulted as a
reference while researching battery telemetry exposed by macOS.

## Development

The test suite uses mocked IORegistry, power-source, adapter, and SMC payloads. It can run on CI machines without a battery:

```sh
xcodebuild -project battakorey.xcodeproj -scheme battakorey -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO test
```
