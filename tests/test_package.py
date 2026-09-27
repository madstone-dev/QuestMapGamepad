import importlib.util
from pathlib import Path
import tempfile
import unittest
import zipfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


class PackageTests(unittest.TestCase):
    def test_runtime_only_reproducible_and_licensed(self):
        spec = importlib.util.spec_from_file_location("package", ROOT / "tools/package.py")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as directory:
            path = module.build(directory)
            first = path.read_bytes()
            self.assertEqual(module.build(directory).read_bytes(), first)
            with zipfile.ZipFile(path) as archive:
                names = archive.namelist()
                self.assertTrue(all(n.startswith("QuestMapGamepad/") for n in names))
                self.assertIn("QuestMapGamepad/Licenses/ATT-MIT.txt", names)
                self.assertIn("QuestMapGamepad/THIRD_PARTY_NOTICES.md", names)
                self.assertFalse(any("tests/" in n or "tools/" in n or "Reference/" in n for n in names))
                ET.fromstring(archive.read("QuestMapGamepad/Bindings.xml"))


if __name__ == "__main__":
    unittest.main()
