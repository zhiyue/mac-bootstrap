import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(sys.platform == "darwin", "bootstrap is macOS-only")
class BootstrapTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="bootstrap-test-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.bin = self.base / "bin"
        self.bin.mkdir()
        self.log = self.base / "calls"
        self.source = self.base / "checkout"
        (self.source / ".git").mkdir(parents=True)
        self.stub("xcode-select", "exit 0\n")
        self.stub("brew", '''printf '%s\\n' "$*" >> "$BOOTSTRAP_TEST_LOG"
case "$1" in
  shellenv) ;;
  --version) echo 'Homebrew fixture' ;;
  list) exit 1 ;;
  install) ;;
  *) exit 97 ;;
esac
''')
        for name in ["curl", "sudo", "git", "gh", "chezmoi"]:
            self.stub(name, f"echo forbidden-{name} >&2\nexit 98\n")
        self.env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ["PATH"],
                        BOOTSTRAP_TEST_LOG=str(self.log), DEV_SETUP_DIR=str(self.base),
                        DEV_SETUP_SOURCE=str(self.source))
        self.env.pop("DEV_SETUP_REPO", None)
        self.env.pop("DOTFILES_AGE_IDENTITY", None)

    def stub(self, name, code):
        path = self.bin / name
        path.write_text("#!/bin/bash\n" + code)
        path.chmod(0o755)

    def run_bootstrap(self):
        return subprocess.run(["bash", str(ROOT / "bootstrap.sh")], env=self.env,
                              text=True, capture_output=True)

    def test_default_only_installs_toolchain(self):
        result = self.run_bootstrap()
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.log.read_text()
        for package in ["git", "gh", "python", "age"]:
            self.assertIn("install " + package + "\n", calls)
        self.assertIn("install --cask 1password-cli\n", calls)
        self.assertNotIn("chezmoi", calls)
        self.assertIn("setup.sh", result.stdout)

    def test_opt_in_handoff_preserves_identity_and_failure(self):
        self.env["DEV_SETUP_REPO"] = "https://github.com/fixture/dotfiles.git"
        self.env["DOTFILES_AGE_IDENTITY"] = str(self.base / "local identity")
        setup = self.source / "setup.sh"
        setup.write_text('printf "%s\\n" "$@" > "$BOOTSTRAP_TEST_LOG.args"\nexit 19\n')
        result = self.run_bootstrap()
        self.assertEqual(result.returncode, 19)
        self.assertEqual(Path(str(self.log) + ".args").read_text().splitlines(),
                         ["--identity", self.env["DOTFILES_AGE_IDENTITY"]])
        self.assertNotIn("Core bootstrap done", result.stdout)
        setup.write_text('printf "%s\\n" "$@" > "$BOOTSTRAP_TEST_LOG.args"\n')
        self.assertEqual(self.run_bootstrap().returncode, 0)

    def test_old_checkout_is_not_applied(self):
        self.env["DEV_SETUP_REPO"] = "https://github.com/fixture/dotfiles.git"
        result = self.run_bootstrap()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("no setup.sh", result.stderr)


if __name__ == "__main__":
    unittest.main()
