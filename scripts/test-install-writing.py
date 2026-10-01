#!/usr/bin/env python3
"""Check installation through its command-line interface without network access."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


NATURAL_REF = "9a78a42964096da509b8f3e011f0085a5f080151"
YOMIYASU_REF = "30ee6041c328ce21d38a7963f667e079a93d7a12"

FAKE_GIT = '''#!/usr/bin/env python3
import os
from pathlib import Path
import sys

args = sys.argv[1:]
if args[0] == "clone":
    name = Path(args[-2]).stem
    if os.environ.get("FAIL_REPO") == name:
        sys.exit(1)
    root = Path(args[-1])
    skill = root / "skills" / name
    skill.mkdir(parents=True)
    (root / "LICENSE").write_text("MIT License\\n")
    (skill / "SKILL.md").write_text(f"---\\nname: {name}\\ndescription: Test skill\\n---\\n")
    if name == "yomiyasu":
        (root / ".claude-plugin").mkdir()
        (root / ".claude-plugin/plugin.json").write_text('{"name":"yomiyasu"}')
        for folder in ("scripts", "references/domains", "assets", ".claude-plugin"):
            (skill / folder).mkdir(parents=True)
        (skill / ".claude-plugin/plugin.json").write_text('{"name":"yomiyasu"}')
        (skill / "references/gemini-syntax.md").write_text("Syntax\\n")
        for domain in ("tech", "business", "essay"):
            (skill / f"references/domains/{domain}.md").write_text(domain)
        if not os.environ.get("MISSING_LINT"):
            (skill / "scripts/yomiyasu_lint.py").write_text("print('lint ready')\\n")
elif args[0] == "-C":
    root = Path(args[1])
    if args[2] == "checkout":
        (root / ".test-ref").write_text(args[-1])
    elif args[2] == "rev-parse":
        print(os.environ.get("WRONG_REF") or (root / ".test-ref").read_text())
    else:
        sys.exit(2)
else:
    sys.exit(2)
'''


class WritingInstallationTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.profile = self.root / "profile"
        self.source = Path(__file__).resolve().parents[1]
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        git = bin_dir / "git"
        git.write_text(FAKE_GIT)
        git.chmod(0o755)
        self.environment = dict(os.environ, PATH=f"{bin_dir}:{os.environ['PATH']}")

    def install(self, **environment):
        return subprocess.run(
            ["bash", str(self.source / "scripts/install-writing.sh"), str(self.profile)],
            env=dict(self.environment, **environment), capture_output=True, text=True,
        )

    def current_files(self):
        files = {}
        for relative in (".agents/principles.md", ".agents/skills/natural-japanese/personal.txt",
                         ".agents/skills/yomiyasu/personal.txt", ".claude/skills/yomiyasu/personal.txt"):
            path = self.profile / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            content = f"current {relative}\n"
            path.write_text(content)
            files[path] = content
        return files

    def assert_kept_current_files(self, files):
        for path, content in files.items():
            self.assertEqual(path.read_text(), content)
        self.assertFalse((self.profile / ".agents/writing.md").exists())
        self.assertFalse((self.profile / ".agents/AGENTS.md").exists())
        self.assertFalse((self.profile / ".agents/backups").exists())

    def test_installs_both_shared_skills_preserves_existing_files_and_is_repeatable(self):
        files = self.current_files()
        result = self.install()
        self.assertEqual(result.returncode, 0, result.stderr)
        agents = self.profile / ".agents"
        backups_before = sorted((agents / "backups").rglob("*"))
        result = self.install()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(sorted((agents / "backups").rglob("*")), backups_before)
        for rule in ("AGENTS", "principles", "writing"):
            self.assertEqual((agents / f"{rule}.md").resolve(), self.source / f"agents/{rule}.md")
        for name, ref in (("natural-japanese", NATURAL_REF), ("yomiyasu", YOMIYASU_REF)):
            codex = agents / "skills" / name
            claude = self.profile / ".claude/skills" / name
            self.assertEqual(codex.resolve(), claude.resolve())
            upstream = agents / "vendor" / f"{name}-{ref}" / "skills" / name
            self.assertEqual((codex / "SKILL.md").read_bytes(), (upstream / "SKILL.md").read_bytes())
            self.assertEqual((upstream.parents[1] / ".test-ref").read_text(), ref)
            self.assertFalse((codex / name).exists())
        yomiyasu = agents / "skills/yomiyasu"
        self.assertFalse((yomiyasu / "SKILL.md").is_symlink())
        self.assertFalse((yomiyasu / ".claude-plugin").exists())
        self.assertFalse(any((parent / ".claude-plugin/plugin.json").exists()
                             for parent in (yomiyasu.resolve(), *yomiyasu.resolve().parents)))
        self.assertTrue((yomiyasu / "LICENSE").is_file())
        for file in ("scripts/yomiyasu_lint.py", "references/gemini-syntax.md",
                     "references/domains/tech.md", "references/domains/business.md",
                     "references/domains/essay.md"):
            self.assertTrue((yomiyasu / file).is_file(), file)
        lint = subprocess.run(["python3", str(yomiyasu / "scripts/yomiyasu_lint.py")],
                              capture_output=True, text=True)
        self.assertEqual(lint.returncode, 0, lint.stderr)
        self.assertIn("lint ready", lint.stdout)
        for path, content in files.items():
            matches = list((agents / "backups").rglob(path.name))
            self.assertEqual(sum(match.is_file() and match.read_text() == content for match in matches), 1)

    def test_second_download_failure_keeps_all_current_files(self):
        files = self.current_files()
        result = self.install(FAIL_REPO="yomiyasu")
        self.assertNotEqual(result.returncode, 0)
        self.assert_kept_current_files(files)

    def test_wrong_revision_keeps_all_current_files(self):
        files = self.current_files()
        result = self.install(WRONG_REF="wrong-revision")
        self.assertNotEqual(result.returncode, 0)
        self.assert_kept_current_files(files)

    def test_missing_linter_keeps_all_current_files(self):
        files = self.current_files()
        result = self.install(MISSING_LINT="1")
        self.assertNotEqual(result.returncode, 0)
        self.assert_kept_current_files(files)

    def test_incomplete_cached_skill_keeps_all_current_files(self):
        self.assertEqual(self.install().returncode, 0)
        cache = self.profile / f".agents/vendor/yomiyasu-{YOMIYASU_REF}"
        (cache / "skills/yomiyasu/references/domains/business.md").unlink()
        current = {p: os.readlink(p) for p in (self.profile / ".agents/writing.md",
                   self.profile / ".agents/skills/yomiyasu", self.profile / ".claude/skills/yomiyasu")}
        result = self.install()
        self.assertNotEqual(result.returncode, 0)
        for path, target in current.items():
            self.assertEqual(os.readlink(path), target)

    def test_broken_skill_link_is_backed_up_before_installation(self):
        link = self.profile / ".claude/skills/yomiyasu"
        link.parent.mkdir(parents=True)
        link.symlink_to("missing-personal-skill")
        result = self.install()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((link / "SKILL.md").is_file())
        backups = list((self.profile / ".agents/backups").rglob("yomiyasu"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(os.readlink(backups[0]), "missing-personal-skill")


if __name__ == "__main__":
    unittest.main()
