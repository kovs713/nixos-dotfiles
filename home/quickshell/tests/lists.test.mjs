import { execFile } from 'node:child_process';
import { copyFile, mkdir, mkdtemp, readFile, realpath, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { promisify } from 'node:util';
import test from 'node:test';

const exec = promisify(execFile);

for (const variant of ['black', 'white']) {
    test(`QML list interactions (${variant})`, async () => {
        const dir = await mkdtemp(join(process.env.TMPDIR || tmpdir(), 'list-test-'));
        try {
            const core = join(dir, 'config/core');
            await mkdir(core, { recursive: true });
            await mkdir(join(dir, 'config/modules'));
            await mkdir(join(dir, 'tests'));
            const scheme = await readFile(new URL(`../../themed/schemes/${variant}.nix`, import.meta.url), 'utf8');
            const color = base => '#' + scheme.match(new RegExp(`${base} = "([0-9a-fA-F]+)"`))[1];
            const data = { mode: variant === 'black' ? 'dark' : 'light', colors: {
                background: color('base00'), surface: color('base01'), surfaceHover: color('base02'),
            } };
            // Quickshell plugins are embedded in qs; isolate rendering from its services.
            const theme = (await readFile(new URL('../config/core/Theme.qml', import.meta.url), 'utf8'))
                .replace('import Quickshell.Io', '')
                .replace(/    property var themeFile:[\s\S]*?(?=    readonly property var fonts)/, `    readonly property var data: (${JSON.stringify(data)})\n\n`);
            await writeFile(join(core, 'Theme.qml'), theme);
            const types = ['ListItem', 'ListRow', 'ResultsView', 'Icons'];
            for (const name of types)
                await copyFile(new URL(`../config/core/${name}.qml`, import.meta.url), join(core, `${name}.qml`));
            await writeFile(join(core, 'qmldir'), ['singleton Theme 1.0 Theme.qml', ...types.map(name => `${name === 'Icons' ? 'singleton ' : ''}${name} 1.0 ${name}.qml`)].join('\n'));
            await copyFile(new URL('tst_lists.qml', import.meta.url), join(dir, 'tests/tst_lists.qml'));
            await copyFile(new URL('../config/modules/ClipboardTextPreview.qml', import.meta.url), join(dir, 'config/modules/ClipboardTextPreview.qml'));
            await copyFile(new URL('tst_clipboard_preview.qml', import.meta.url), join(dir, 'tests/tst_clipboard_preview.qml'));
            await copyFile(new URL('../config/modules/NotesEditor.qml', import.meta.url), join(dir, 'config/modules/NotesEditor.qml'));
            await copyFile(new URL('tst_notes_editor.qml', import.meta.url), join(dir, 'tests/tst_notes_editor.qml'));
            const { stdout: lintPath } = await exec('sh', ['-c', 'command -v qmllint']);
            const imports = join(dirname(await realpath(lintPath.trim())), '../lib/qt-6/qml');
            const { stdout } = await exec('qmltestrunner', ['-input', join(dir, 'tests')], {
                env: { ...process.env, QT_QPA_PLATFORM: 'offscreen', QML2_IMPORT_PATH: imports },
            });
            console.log(stdout);
        } finally {
            await rm(dir, { recursive: true, force: true });
        }
    });
}
