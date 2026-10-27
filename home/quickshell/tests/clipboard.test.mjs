import assert from 'node:assert/strict';
import { execFile } from 'node:child_process';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import vm from 'node:vm';
import { promisify } from 'node:util';
import test from 'node:test';

const exec = promisify(execFile);
const source = await readFile(new URL('../config/services/ClipboardService.qml', import.meta.url), 'utf8');
const method = name => {
    const start = source.indexOf(`    function ${name}(`);
    assert.ok(start >= 0, `Missing QML function ${name}`);
    return source.slice(start, source.indexOf('\n    }', start) + 6);
};
const methods = ['shellQuote', 'promote'].map(method).join('\n');

function previewContext() {
    const root = {
        previewKey: '', previewText: '', previewSource: '', previewUrls: {}, decodingKey: '',
        textPreviewId: '', previewProcess: {}, textPreviewProcess: { running: false, command: [] },
    };
    const context = vm.createContext({
        root,
        textPreviewProcess: root.textPreviewProcess,
        previewProcess: root.previewProcess,
        textOutput: { text: '' },
        Qt: { callLater: callback => callback() },
        Core: { Util: { restart() {} } },
    });
    const process = source.slice(source.indexOf('readonly property Process textPreviewProcess:'));
    const exited = process.match(/onExited: \{([\s\S]*?)\n        \}/)[1];
    vm.runInContext(['shellQuote', 'startTextPreview', 'loadPreview'].map(method).join('\n') + `
        function finishPreview(text) {
            textPreviewProcess.running = false;
            textOutput.text = text;
            ${exited}
        }
    `, context);
    root.startTextPreview = context.startTextPreview;
    return context;
}

test('text preview decodes beyond the list snippet and caps the payload', async () => {
    const dir = await mkdtemp(join(process.env.TMPDIR || tmpdir(), 'clipboard-preview-'));
    try {
        const fullText = "Full text with 'quotes'\n".repeat(5000);
        await writeFile(join(dir, 'text'), fullText);
        await writeFile(join(dir, 'cliphist'), '#!/bin/sh\n[ "$1" = decode ] && [ "$2" = 42 ] && cat "$TEST_DIR/text"\n', { mode: 0o755 });
        const context = previewContext();
        context.loadPreview({ id: '42', image: false, text: 'truncated snippet' });
        const command = context.textPreviewProcess.command;
        const { stdout } = await exec(command[0], command.slice(1), {
            env: { ...process.env, PATH: `${dir}:${process.env.PATH}`, TEST_DIR: dir },
        });
        context.finishPreview(stdout);
        assert.equal(context.root.previewText, fullText.slice(0, 65536));
        assert.equal(context.root.previewKey, '42.text');
    } finally {
        await rm(dir, { recursive: true, force: true });
    }
});

test('rapid selection discards stale text and decodes only the latest pending entry', () => {
    const context = previewContext();
    context.loadPreview({ id: '1', image: false });
    context.loadPreview({ id: '2', image: false });
    context.loadPreview({ id: '3', image: false });
    assert.equal(context.textPreviewProcess.command[4], '1');
    context.finishPreview('stale text');
    assert.equal(context.root.previewText, '');
    assert.equal(context.textPreviewProcess.command[4], '3');
    context.finishPreview('latest text');
    assert.equal(context.root.previewText, 'latest text');
});

test('image and empty selections never display an old text preview', () => {
    const context = previewContext();
    context.loadPreview({ id: '1', image: false });
    context.root.previewUrls['2.png'] = 'file:///cached-image.png';
    context.loadPreview({ id: '2', image: true, ext: 'png' });
    context.finishPreview('old text');
    assert.equal(context.root.previewText, '');
    assert.equal(context.root.previewSource, 'file:///cached-image.png');
    assert.equal(context.textPreviewProcess.running, false);
    context.loadPreview(null);
    assert.equal(context.root.previewKey, '');
});

test('Enter and click only select an entry', async () => {
    const ui = await readFile(new URL('../config/modules/Clipboard.qml', import.meta.url), 'utf8');
    const accepted = ui.match(/onAccepted: \{([\s\S]*?)\n    \}/)[1];
    const activated = ui.match(/onActivated: \{([\s\S]*?)\n                        \}/)[1];
    const entries = [{ raw: 'latest' }, { raw: 'older' }];
    const selected = [];
    let dismissed = 0;
    const context = vm.createContext({
        results: entries,
        selectedIndex: 0,
        row: { index: 1 },
        Services: { ClipboardService: { promote: item => selected.push(item) } },
        clipboard: {
            dismiss() { dismissed++; },
            set selectedIndex(index) { context.selectedIndex = index; },
            accepted() { context.accept(); },
        },
    });
    vm.runInContext(`function accept() {${accepted}}\nfunction activate() {${activated}}`, context);
    context.accept();
    context.activate();
    assert.deepEqual(selected, entries);
    assert.equal(dismissed, 2);
});

for (const failure of ['', 'cliphist', 'wl-copy']) {
    test(failure ? `${failure} failure never inserts into the focused input` : 'selection updates clipboard without inserting into the focused input', async () => {
        const dir = await mkdtemp(join(process.env.TMPDIR || tmpdir(), 'clipboard-test-'));
        try {
            await writeFile(join(dir, 'clipboard'), 'old top entry');
            const scripts = {
                cliphist: `sleep 0.2\n${failure === 'cliphist' ? 'exit 1' : 'cat'}`,
                'wl-copy': failure === 'wl-copy' ? 'cat > /dev/null; exit 1' : 'cat > "$TEST_DIR/next" && mv "$TEST_DIR/next" "$TEST_DIR/clipboard"',
                wtype: 'cat "$TEST_DIR/clipboard" > "$TEST_DIR/pasted"',
            };
            for (const [name, script] of Object.entries(scripts))
                await writeFile(join(dir, name), `#!/bin/sh\n${script}\n`, { mode: 0o755 });

            const pending = [];
            const run = command => pending.push(exec(command[0], command.slice(1), {
                env: { ...process.env, PATH: `${dir}:${process.env.PATH}`, TEST_DIR: dir },
            }).catch(() => {}));
            const context = vm.createContext({
                Quickshell: { execDetached: run },
                refresh() {},
            });
            vm.runInContext(methods, context);
            const selected = "42\tolder 'selected' entry";
            context.promote({ raw: selected });
            await Promise.all(pending);

            await assert.rejects(readFile(join(dir, 'pasted')), { code: 'ENOENT' });
            if (!failure)
                assert.equal(await readFile(join(dir, 'clipboard'), 'utf8'), `${selected}\n`);
        } finally {
            await rm(dir, { recursive: true, force: true });
        }
    });
}
