"""Exercise real installers against an isolated destination; no Cursor login needed."""
import argparse
from datetime import datetime, timedelta
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
PARSER = argparse.ArgumentParser()
PARSER.add_argument('--installer', choices=['sh', 'pwsh', 'powershell'], required=True)
ARGS, REMAINING = PARSER.parse_known_args()


class InstallerTest(unittest.TestCase):
    def test_install_repeat_backup_and_preserve(self):
        platform = 'unix' if ARGS.installer == 'sh' else 'windows'
        expected = {
            Path('agents') / name: (REPO / 'config/common/agents' / name).read_bytes()
            for name in ['explore.md', 'plan.md', 'general-purpose.md', 'worker.md']
        }
        expected[Path('rules/delete-via-shell.mdc')] = (
            REPO / 'config' / platform / 'rules/delete-via-shell.mdc'
        ).read_bytes()

        with tempfile.TemporaryDirectory(prefix='cursor-install-test-') as temporary:
            # Spaces and Unicode exercise quoting on all platforms.
            destination = Path(temporary) / '配置 with spaces' / '.cursor'
            destination.mkdir(parents=True)
            unrelated = destination / 'cli-config.json'
            unrelated.write_bytes(b'{"sentinel":"do not change"}\n')
            extra = destination / 'agents' / 'custom.md'
            extra.parent.mkdir()
            extra.write_bytes(b'Unmanaged agent\n')
            preserved = {unrelated: unrelated.read_bytes(), extra: extra.read_bytes()}
            env = dict(os.environ, CURSOR_CONFIG_HOME=str(destination))
            if ARGS.installer == 'sh':
                command = ['sh', str(REPO / 'scripts/install.sh')]
            else:
                command = [ARGS.installer, '-NoProfile', '-NonInteractive',
                           '-ExecutionPolicy', 'Bypass', '-File',
                           str(REPO / 'scripts/install.ps1')]

            def install():
                # Deliberately invoke from outside the repo to test path resolution.
                result = subprocess.run(command, cwd=temporary, env=env,
                                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                        timeout=60)
                output = result.stdout.decode('utf-8', errors='replace')
                print(output.encode('ascii', errors='backslashreplace').decode('ascii'))
                self.assertEqual(result.returncode, 0)

            def verify():
                for relative, content in expected.items():
                    self.assertEqual((destination / relative).read_bytes(), content)
                for path, content in preserved.items():
                    self.assertEqual(path.read_bytes(), content)

            install()
            verify()
            self.assertEqual(len(list(destination.rglob('*.bak.*'))), 0)
            before = {p: p.stat().st_mtime_ns for p in destination.rglob('*') if p.is_file()}
            install()
            verify()
            self.assertEqual(before, {p: p.stat().st_mtime_ns
                                     for p in destination.rglob('*') if p.is_file()})

            changed = destination / 'agents/worker.md'
            original = b'Local customization that must be backed up\n'
            changed.write_bytes(original)
            install()
            verify()
            backups = sorted(destination.rglob('*.bak.*'))
            self.assertEqual(len(backups), 1)
            self.assertTrue(backups[0].name.startswith('worker.md.bak.'))
            self.assertEqual(backups[0].read_bytes(), original)

            # Pre-create backup names around the next invocation time. A safe
            # installer must choose a suffix instead of overwriting any of them.
            collision_sentinels = {}
            now = datetime.now()
            for offset in range(-5, 66):
                stamp = (now + timedelta(seconds=offset)).strftime('%Y%m%d%H%M%S')
                candidate = changed.with_name(f'{changed.name}.bak.{stamp}')
                if candidate.exists():
                    continue
                sentinel = f'Existing backup sentinel {offset}\n'.encode()
                candidate.write_bytes(sentinel)
                collision_sentinels[candidate] = sentinel

            second_original = b'Another local customization that must be backed up\n'
            changed.write_bytes(second_original)
            install()
            verify()
            for path, content in collision_sentinels.items():
                self.assertEqual(path.read_bytes(), content)
            backups = sorted(destination.rglob('*.bak.*'))
            self.assertEqual(len(backups), len(collision_sentinels) + 2)
            backup_contents = {backup.read_bytes() for backup in backups}
            self.assertIn(original, backup_contents)
            self.assertIn(second_original, backup_contents)

            install()
            verify()
            self.assertEqual(sorted(destination.rglob('*.bak.*')), backups)


if __name__ == '__main__':
    unittest.main(argv=[__file__] + REMAINING)
