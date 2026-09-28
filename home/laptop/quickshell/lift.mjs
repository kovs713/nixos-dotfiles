// Lift a QML singleton's logic into a JS class, so it can be asserted on.
//
//   import { lift } from './lift.mjs';
//   const Svc = lift('services/Fuzzy.qml', { Core, Quickshell });
//   const fuzzy = new Svc();
//   assert.ok(fuzzy.subsequence('firefox', 'fx'));
//
// Why this exists: qmllint cannot tell that a row fails to match a query or that
// a model reconcile drops a row, and the shell cannot be exercised headless. The
// QML body is text, so it can be turned into a class with the sibling singletons
// stubbed and the logic called directly.
//
// What it handles, and nothing more:
//
//   - `pragma Singleton`, the `import` lines, the root `{ }` and `id: root`
//   - `property X name: { ... }`, `readonly property X name: [{ ... }]` and
//     `readonly property X name: <expr>` -- which in QML are bindings, and in
//     JS are getters
//   - `function name(` -> `name(`, because a class body forbids `function` as a
//     method name
//
// What it does not handle, and a test using it must not rely on: a file with
// child objects that are not declared as properties, a brace or bracket inside a
// string literal, or a commented-out block. The brace counter is a counter.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const HERE = dirname(fileURLToPath(import.meta.url));
const CONFIG = resolve(HERE, 'config');

const PROP = /^\s*(?:readonly\s+)?property\s+\w+\s+(\w+)\s*:\s*(\[?)\{\s*$/;
const SCALAR = /^\s*(?:readonly\s+)?property\s+\w+\s+(\w+)\s*:\s*(.+?)\s*$/;

function toJs(qml) {
  const lines = qml.replace(/pragma Singleton/g, '').replace(/^import .*$/gm, '').split('\n');
  const out = [];
  let depth = 0;      // depth inside the property block being converted

  for (const line of lines) {
    if (depth === 0) {
      const m = PROP.exec(line);

      if (m) {
        // `property var x: {` is a binding, and a binding is a getter. `[{` is a
        // binding too -- an array of objects -- so both openers are re-emitted
        // and the `}]` on the block's last line cancels them, after which the
        // getter's own `}` goes down.
        out.push('get ' + m[1] + '() {' + (m[2] ? ' return [{' : ''));
        // The consumed line's own openers count too: `[{` is two, and the block
        // is only closed once the `}]` on the last line has cancelled both.
        depth = 1 + m[2].length;
        continue;
      }

      // A scalar property is a binding too, so it is a getter as well. Left as a
      // bare `name: value` it would be a class field with no initialiser, which
      // is not a thing.
      const s = SCALAR.exec(line);

      if (s) {
        out.push('get ' + s[1] + '() { return ' + s[2] + '; }');
        continue;
      }

      out.push(line
        .replace(/^\s*(?:readonly\s+)?property\s+\w+\s+/, '')
        .replace(/^\s*id:\s*root\s*$/, '')
        .replace(/^(\s*)function (\w+)\(/, '$1$2(')
        .replace(/\s+$/, ''));
      continue;
    }

    // Brackets as well as braces: an array literal opened on the property line
    // has to be counted, or its `]` leaves the counter one short forever.
    for (const c of line) {
      if (c === '{' || c === '[') depth++;
      else if (c === '}' || c === ']') depth--;
    }

    if (depth === 0) {
      // The line that closed the block also carries the closers the getter has
      // to balance, so keep it verbatim and add the getter's own brace.
      out.push(line.replace(/\s+$/, ''));
      out.push('}');
      continue;
    }

    out.push(line);
  }

  return out.join('\n');
}

// Lift `config/<relative>` and return its class, already bound to the stubs.
export function lift(relative, stubs = {}) {
  const src = readFileSync(resolve(CONFIG, relative), 'utf8');
  const start = src.indexOf('QtObject {');

  if (start === -1)
    throw new Error(relative + ': expected a QtObject root to lift');

  const body = toJs(src.slice(start + 'QtObject {'.length, src.lastIndexOf('}')));
  const names = Object.keys(stubs);
  const values = names.map((n) => stubs[n]);
  const Root = new Function(...names, 'return class {\n' + body + '\n};')(...values);
  const instance = new Root();

  // `root` is the QML id, and the body calls root.foo() on itself.
  globalThis.root = instance;
  // QML resolves an unqualified sibling call against the id; a class does not, so
  // bind the methods globally too. A later test overwrites them, which is fine:
  // one lifted class at a time is all any of them need.
  for (const k of Object.getOwnPropertyNames(Object.getPrototypeOf(instance)))
    if (typeof instance[k] === 'function') globalThis[k] = (...a) => instance[k](...a);

  return instance;
}
