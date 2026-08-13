import assert from "node:assert/strict";
import test from "node:test";

import {
  defaultDownloadArchitecture,
  downloadOptions,
  resolveDownloadOption,
} from "./download-options.js";

test("downloads default to the Apple Silicon build", () => {
  assert.equal(defaultDownloadArchitecture, "arm64");
  assert.equal(resolveDownloadOption("unknown"), downloadOptions.arm64);
});

test("each architecture resolves to its published disk image", () => {
  assert.equal(
    downloadOptions.universal.url,
    "https://github.com/cocoa-xu/Battakorey/releases/latest/download/Battakorey-Universal.dmg",
  );
  assert.equal(
    downloadOptions.arm64.url,
    "https://github.com/cocoa-xu/Battakorey/releases/latest/download/Battakorey-Apple-Silicon.dmg",
  );
  assert.equal(
    downloadOptions.intel.url,
    "https://github.com/cocoa-xu/Battakorey/releases/latest/download/Battakorey-Intel.dmg",
  );
});
