from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "addon" / "QuestMapGamepad"


class CoreTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.ns = self.lua.table()
        self.lua.execute((ADDON / "Core.lua").read_text(encoding="utf-8"), "QuestMapGamepad", self.ns)
        self.settings = self.ns.NormalizeSettings(None)

    def pin(self, **values):
        return self.lua.table_from(values)

    def test_surface_settings_are_independent(self):
        self.settings.world.start = False
        pin = self.pin(kind="start")
        self.assertFalse(self.ns.ShouldShow(pin, self.settings, "world"))
        self.assertTrue(self.ns.ShouldShow(pin, self.settings, "minimap"))

    def test_completed_and_repeatable_filters(self):
        self.assertFalse(self.ns.ShouldShow(self.pin(kind="start", completed=True), self.settings, "world"))
        repeatable = self.pin(kind="start", completed=True, repeatable=True)
        self.assertTrue(self.ns.ShouldShow(repeatable, self.settings, "world"))
        self.settings.world.repeatable = False
        self.assertFalse(self.ns.ShouldShow(repeatable, self.settings, "world"))

    def test_low_level_and_unknown_pins(self):
        self.assertFalse(self.ns.ShouldShow(self.pin(kind="start", lowLevel=True), self.settings, "world"))
        self.assertFalse(self.ns.ShouldShow(self.pin(kind="unknown"), self.settings, "world"))
        self.assertFalse(self.ns.ShouldShow(self.pin(kind="start"), self.settings, "unknown"))

    def test_saved_settings_are_normalized(self):
        raw = self.lua.eval('{world={size=999,start=false},minimap="broken"}')
        clean = self.ns.NormalizeSettings(raw)
        self.assertEqual(clean.world.size, 36)
        self.assertFalse(clean.world.start)
        self.assertEqual(clean.minimap.size, 18)
        self.assertEqual(self.ns.NormalizeSettings(False).version, 1)

    def test_minimap_rotation_and_edge_clipping(self):
        import math
        self.assertEqual(self.ns.MinimapOffset(50, 0, 100, 200, 200, 0, False, 10), (50, 0))
        x, y = self.ns.MinimapOffset(-50, 0, 100, 200, 200, math.pi / 2, True, 10)
        self.assertAlmostEqual(x, 0)
        self.assertAlmostEqual(y, 50)
        self.assertIsNone(self.ns.MinimapOffset(100, 0, 100, 200, 200, 0, False, 10))

    def test_master_toggle_overrides_categories(self):
        self.settings.world.enabled = False
        self.assertFalse(self.ns.ShouldShow(self.pin(kind="objective"), self.settings, "world"))


if __name__ == "__main__":
    unittest.main()
