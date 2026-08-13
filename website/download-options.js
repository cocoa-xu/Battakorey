const latestReleaseAsset = (name) =>
  `https://github.com/cocoa-xu/Battakorey/releases/latest/download/${name}`;

export const defaultDownloadArchitecture = "arm64";

export const downloadOptions = Object.freeze({
  arm64: Object.freeze({
    label: "Apple Silicon",
    detail: "ARM64 · M-Series Macs",
    description: "Apple Silicon · ARM64 · M-Series Macs",
    buttonLabel: "Download for Apple Silicon",
    url: latestReleaseAsset("Battakorey-Apple-Silicon.dmg"),
  }),
  universal: Object.freeze({
    label: "Universal",
    detail: "Apple Silicon and Intel",
    description: "Universal for Apple Silicon and Intel",
    buttonLabel: "Download Universal",
    url: latestReleaseAsset("Battakorey-Universal.dmg"),
  }),
  intel: Object.freeze({
    label: "Intel",
    detail: "x86_64 · Intel-Based Macs",
    description: "Intel · x86_64 · Intel-Based Macs",
    buttonLabel: "Download for Intel",
    url: latestReleaseAsset("Battakorey-Intel.dmg"),
  }),
});

export const resolveDownloadOption = (architecture) =>
  downloadOptions[architecture] ?? downloadOptions[defaultDownloadArchitecture];
