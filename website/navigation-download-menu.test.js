import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const html = readFileSync(new URL("index.html", import.meta.url), "utf8");
const main = readFileSync(new URL("main.js", import.meta.url), "utf8");
const styles = readFileSync(new URL("styles.css", import.meta.url), "utf8");

test("the navigation download menu links every published architecture", () => {
  assert.match(html, /data-download-trigger/);
  assert.match(html, /role="menu"[^>]*inert[^>]*data-download-panel/);
  assert.equal(html.match(/role="menuitem"/g)?.length, 3);
  assert.match(html, /Battakorey-Apple-Silicon\.dmg/);
  assert.match(html, /Battakorey-Universal\.dmg/);
  assert.match(html, /Battakorey-Intel\.dmg/);
});

test("the navigation download menu supports pointer and keyboard dismissal", () => {
  assert.match(main, /event\.key === "Escape"/);
  assert.match(main, /event\.key !== "ArrowDown"/);
  assert.match(main, /\["ArrowDown", "ArrowUp", "Home", "End"\]/);
  assert.match(main, /document\.addEventListener\("pointerdown"/);
  assert.match(main, /downloadMenu\?\.addEventListener\("focusout"/);
  assert.match(
    main,
    /downloadTrigger\?\.setAttribute\("aria-expanded", String\(open\)\)/,
  );
  assert.match(main, /downloadPanel\?\.toggleAttribute\("inert", !open\)/);
});

test("the navigation download menu uses the Battakorey accent", () => {
  assert.match(
    styles,
    /\.nav-menu \.download-menu a:hover,[\s\S]*color: var\(--purple-800\);[\s\S]*background: var\(--purple-100\);/,
  );
});
