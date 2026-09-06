#!/usr/bin/env python3
"""Check installation through its command-line interface without network access."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


class WritingInstallationTest(unittest.TestCase):
    def test_installs_shared_rules_preserves_existing_files_and_is_repeatable(self):
        source = Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            destination = root / "profile"
            agents = destination / ".agents"
            agents.mkdir(parents=True)
            old_principles = agents / "principles.md"
            old_principles.write_text("existing personal principles\n")
            old_skill = agents / "skills/natural-japanese"
            old_skill.mkdir(parents=True)
            (old_skill / "personal.txt").write_text("keep my changes\n")

            # GitHub is the only substituted boundary; the installer does real file I/O.
            bin_dir = root / "bin"
            bin_dir.mkdir()
            git = bin_dir / "git"
            git.write_text('''#!/bin/bash
set -eu
if [ "$1" = clone ]; then
  for destination; do :; done
  mkdir -p "$destination/skills/natural-japanese"
  printf '%s\\n' '---' 'name: natural-japanese' 'description: Test skill' '---' > "$destination/skills/natural-japanese/SKILL.md"
elif [ "$3" = rev-parse ]; then
  printf '%s\\n' 9a78a42964096da509b8f3e011f0085a5f080151
fi
''')
            git.chmod(0o755)
            environment = dict(os.environ, PATH=f"{bin_dir}:{os.environ['PATH']}")
            command = ["bash", str(source / "scripts/install-writing.sh"), str(destination)]
            for _ in range(2):
                subprocess.run(command, env=environment, check=True, capture_output=True, text=True)
            self.assertEqual(old_principles.resolve(), source / "agents/principles.md")
            self.assertEqual((agents / "writing.md").resolve(), source / "agents/writing.md")
            codex_skill = agents / "skills/natural-japanese"
            claude_skill = destination / ".claude/skills/natural-japanese"
            self.assertEqual(codex_skill.resolve(), claude_skill.resolve())
            self.assertTrue((codex_skill / "SKILL.md").is_file())
            self.assertFalse((codex_skill / "natural-japanese").exists())
            backups = list((agents / "backups").rglob("principles.md"))
            self.assertEqual(len(backups), 1)
            self.assertEqual(backups[0].read_text(), "existing personal principles\n")
            personal_files = list((agents / "backups").rglob("personal.txt"))
            self.assertEqual(len(personal_files), 1)
            self.assertEqual(personal_files[0].read_text(), "keep my changes\n")

    def test_download_failure_keeps_current_rules(self):
        source = Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            agents = root / "profile/.agents"
            agents.mkdir(parents=True)
            (agents / "principles.md").write_text("current rules\n")
            bin_dir = root / "bin"
            bin_dir.mkdir()
            git = bin_dir / "git"
            git.write_text("#!/bin/sh\nexit 1\n")
            git.chmod(0o755)
            environment = dict(os.environ, PATH=f"{bin_dir}:{os.environ['PATH']}")
            result = subprocess.run(["bash", str(source / "scripts/install-writing.sh"), str(root / "profile")], env=environment, capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual((agents / "principles.md").read_text(), "current rules\n")
            self.assertFalse((agents / "writing.md").exists())


if __name__ == "__main__":
    unittest.main()
