// Run: node launcher-search.test.mjs
//
// The check for the launcher's row filter. qmllint cannot see that a row fails
// to match a query, and the shell cannot be exercised headless, so the QML body
// is lifted into a class with the sibling singletons stubbed and the filter is
// asserted directly. lift.mjs does the lifting.
//
// The service calls its siblings as bare globals -- they all live in one qmldir
// module -- so the stubs go in the same way.
const state = { active: true, toggled: 0 };
const NightLightService = {
  get active() { return state.active; },
  toggle() { state.toggled++; state.active = !state.active; },
};
// Stubs that actually match, so a row-filter assertion is not drowned out by a
// stub that returns the same app for every query.
const APPS = [{ name: "Firefox", genericName: "Web Browser", icon: "firefox" }];
const AppsService = { search: (q) => APPS.filter(a => a.name.toLowerCase().includes(q.toLowerCase())), launch() {} };
const CMDS = [{ kind: "shell", category: "Shell", name: "theme-tool", command: "theme-tool" }];
const ShellService = { search: (q) => CMDS.filter(c => c.name.includes(q)), run() {} };
let ran = null;
ShellService.run = (c) => { ran = c; };

import { lift } from './lift.mjs';
import assert from 'node:assert/strict';

const root = lift('services/LauncherService.qml', { NightLightService, AppsService, ShellService });
const names = (q) => root.search(q).map(r => r.category + ':' + r.name);

// The night light is on, so the row offers to turn it off.
assert.deepStrictEqual(names(""), [
  'Reminder:Reminder',
  'Screen:Night light: Off',
  'Application:Firefox',   // an empty query shows every app
]);
assert.deepStrictEqual(names("remind"), ['Reminder:Reminder']);
assert.deepStrictEqual(names("night"), ['Screen:Night light: Off']);
// The theme rows are gone: two variants make it a toggle, and the hotkey owns it.
assert.ok(!names("").some(n => n.startsWith('Theme')), 'no theme rows');
// A query that matches nothing still gets the run-it row.
assert.deepStrictEqual(names("nonexistentword"), ['Shell:Run nonexistentword']);
// The stub command matches "theme" too; the row filter decides, not the source.
assert.deepStrictEqual(names("theme"), ['Shell:theme-tool']);
assert.deepStrictEqual(names(">theme").map(n => n.split(':')[0]), ['Shell'], '> prefix must stay command-only');
// Apps are offered for a bare query but never for the > prefix.
assert.ok(root.search('theme').every(r => r.kind !== 'app'));
assert.deepStrictEqual(root.search('>theme').map(r => r.kind), ['shell']);

root.run({ kind: 'nightlight' });
assert.strictEqual(state.toggled, 1, 'the night light row must toggle, not set a temperature');
assert.deepStrictEqual(names(""), [
  'Reminder:Reminder',
  'Screen:Night light: On',   // now off, so the row offers to turn it back on
  'Application:Firefox',
]);
root.run({ kind: 'shell', command: 'theme-tool' });
assert.strictEqual(ran, 'theme-tool');
root.run(null);
assert.strictEqual(ran, 'theme-tool', 'a null entry must be ignored');

console.log('ok — all assertions passed');
