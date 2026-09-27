from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "addon/QuestMapGamepad"


class RuntimeTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute((ROOT / "tests/wow_mock.lua").read_text(encoding="utf-8"))
        self.ns = self.lua.table()
        for line in (ADDON / "QuestMapGamepad.toc").read_text().splitlines():
            if line and not line.startswith("#"):
                self.lua.execute((ADDON / line.replace("\\", "/")).read_text(encoding="utf-8"), "QuestMapGamepad", self.ns)
        self.g = self.lua.globals()

    def boot(self):
        self.g.emit("ADDON_LOADED", "QuestMapGamepad")

    def fixture(self, source):
        self.ns.StartDB = self.lua.eval(source)

    def pins(self):
        return list(self.ns.pins.values())

    def test_own_event_initialization(self):
        self.g.emit("ADDON_LOADED", "OtherAddon")
        self.assertIsNone(self.ns.settings)
        self.boot()
        self.assertIsNotNone(self.ns.settings)
        self.assertFalse(self.ns.window.IsShown(self.ns.window))

    def test_imported_data_validity(self):
        data = list(self.ns.StartDB.items())
        self.assertEqual(len(data), 3983)
        for id_, record in data:
            self.assertGreater(id_, 0)
            self.assertTrue(self.ns.ValidPoint(record.mapID, record.x / 100, record.y / 100))
            if record.coords:
                for point in record.coords.values():
                    self.assertTrue(self.ns.ValidPoint(point[3], point[1] / 100, point[2] / 100))

    def test_prerequisites_class_race_and_seasonal(self):
        player = self.ns.Player()
        blank = self.lua.table()
        eligible = self.ns.Eligible
        self.assertTrue(eligible(1, self.lua.eval('{minLevel=10,classes={8},races={1},requireSkill=171}'), player, blank, blank))
        for record in ('{sourceQuests={2}}', '{classes={1}}', '{races={2}}', '{faction="Horde"}', '{isYearly=true}', '{requireSkill=333}', '{minLevel=30}'):
            self.assertFalse(eligible(1, self.lua.eval(record), player, blank, blank))
        self.assertTrue(eligible(1, self.lua.eval('{sourceQuests={2}}'), player, blank, self.lua.eval('{[2]=true}')))

    def test_active_objective_turnin_and_missing_coordinates(self):
        self.fixture('{[5]={mapID=1,x=50,y=50},[6]={mapID=1,x=40,y=40}}')
        self.lua.execute('questLog={{questID=5,title="Active",level=18,ready=false},{questID=6,title="No position",level=18}};waypoints={[5]={1,0.6,0.5}}')
        self.boot(); self.g.tick(0.6)
        pins = self.pins()
        self.assertEqual(len(pins), 1)
        self.assertEqual(pins[0].kind, "objective")
        self.assertEqual(self.ns.missingActive, 1)
        self.lua.execute('questLog[1].ready=true')
        self.g.emit("QUEST_LOG_UPDATE"); self.g.tick(0.6)
        self.assertEqual(self.pins()[0].kind, "turnin")

    def test_native_pois_override_static_start(self):
        self.fixture('{[5]={mapID=1,x=50,y=50,isYearly=true}}')
        self.lua.execute('pois={[1]={{questID=5,isQuestStart=true,x=0.55,y=0.6}}}')
        self.boot(); self.g.tick(0.6)
        self.assertEqual(len(self.pins()), 1)
        self.assertEqual(self.pins()[0].source, "native")

    def test_ancestor_projection_and_invalid_map(self):
        pin = self.lua.eval('{mapID=1,x=0.5,y=0.5}')
        x, y = self.ns.Project(pin, 10)
        self.assertAlmostEqual(x, 0.4); self.assertAlmostEqual(y, 0.3)
        self.assertIsNone(self.ns.Project(pin, 999))

    def test_secret_or_failed_api_is_not_used(self):
        self.fixture('{[5]={mapID=1,x=50,y=50}}')
        self.lua.execute('pois={[1]={{questID={secret=true},x={secret=true},y=0.5}}}; C_QuestLog.GetNextWaypoint=function() error("restricted") end; questLog={{questID=6,level=18}}')
        self.boot(); self.g.tick(0.6)
        self.assertEqual(len(self.pins()), 1)
        self.assertGreater(self.ns.readErrors, 0)

    def test_gamepad_controls_and_independent_settings(self):
        self.fixture('{}'); self.boot()
        self.g.QuestMapGamepad_Toggle()
        frame = self.ns.window
        self.assertTrue(frame.IsShown(frame))
        frame.scripts.OnGamePadButtonDown(frame, "PADDDOWN")
        frame.scripts.OnGamePadButtonDown(frame, "PAD1")
        self.assertFalse(self.ns.settings.world.enabled)
        self.assertTrue(self.ns.settings.minimap.enabled)
        frame.scripts.OnGamePadButtonDown(frame, "PAD2")
        self.assertFalse(frame.IsShown(frame))

    def test_stick_navigation_and_combat_dialogue_closure(self):
        self.fixture('{}'); self.boot(); self.g.QuestMapGamepad_Toggle()
        frame = self.ns.window
        frame.scripts.OnGamePadStick(frame, "Left", 0, -1)
        frame.scripts.OnGamePadStick(frame, "Left", 0, 0)
        frame.scripts.OnGamePadButtonDown(frame, "PAD1")
        self.assertFalse(self.ns.settings.world.enabled)
        self.g.emit("GOSSIP_SHOW")
        self.assertFalse(frame.IsShown(frame))
        self.g.QuestMapGamepad_Toggle()
        self.assertFalse(frame.IsShown(frame))
        self.g.emit("GOSSIP_CLOSED"); self.g.QuestMapGamepad_Toggle()
        self.assertTrue(frame.IsShown(frame))
        self.g.combat = True; self.g.emit("PLAYER_REGEN_DISABLED")
        self.assertFalse(frame.IsShown(frame))

    def test_renderer_world_minimap_and_native_frames_untouched(self):
        self.fixture('{[5]={mapID=1,x=52,y=50}}')
        self.boot(); self.g.tick(0.6)
        self.assertEqual(len(self.ns.visiblePins), 1)
        # The strict mock raises immediately on ANY mutation of a native frame.
        self.g.WorldMapFrame.shown = False
        self.g.tick(0.2)
        groups = [f for f in self.g.frames.values() if self.lua.eval('rawget')(f, 'group')]
        self.assertGreaterEqual(len(groups), 2)

    def test_diagnostic_log_is_bounded_and_attributed(self):
        self.fixture('{}'); self.boot()
        self.g.emit("ADDON_ACTION_BLOCKED", "OtherAddon", "OtherAction")
        for _ in range(30): self.g.emit("ADDON_ACTION_BLOCKED", "QuestMapGamepad", "ExampleAction")
        before = len(self.g.messages)
        self.g.SlashCmdList.QUESTMAPGAMEPAD("log")
        self.assertEqual(len(self.g.messages) - before, 26)

    def test_gossip_to_quest_transition_does_not_release_input_guard(self):
        self.fixture('{}'); self.boot()
        self.g.emit("GOSSIP_SHOW")
        self.g.emit("QUEST_DETAIL")
        self.g.emit("GOSSIP_CLOSED")
        self.assertTrue(self.ns.dialogue)
        self.g.QuestMapGamepad_Toggle()
        self.assertFalse(self.ns.window.IsShown(self.ns.window))
        self.g.emit("QUEST_FINISHED")
        self.assertFalse(self.ns.dialogue)

    def test_combat_queues_model_refresh(self):
        self.fixture('{}'); self.boot(); self.g.tick(0.6)
        revision = self.ns.revision
        self.g.combat = True
        self.g.emit("QUEST_LOG_UPDATE"); self.g.tick(0.6)
        self.assertEqual(self.ns.revision, revision)
        self.g.combat = False
        self.g.emit("PLAYER_REGEN_ENABLED"); self.g.tick(0.6)
        self.assertGreater(self.ns.revision, revision)

    def test_swapped_confirm_and_size_bounds(self):
        self.fixture('{}'); self.boot(); self.g.QuestMapGamepad_Toggle()
        self.ns.settings.swapButtons = True
        f = self.ns.window
        f.scripts.OnGamePadButtonDown(f, "PADDDOWN")
        f.scripts.OnGamePadButtonDown(f, "PAD2")
        self.assertFalse(self.ns.settings.world.enabled)
        for _ in range(6): f.scripts.OnGamePadButtonDown(f, "PADDDOWN")
        for _ in range(30): f.scripts.OnGamePadButtonDown(f, "PADDRIGHT")
        self.assertEqual(self.ns.settings.world.size, 36)
        for _ in range(30): f.scripts.OnGamePadButtonDown(f, "PADDLEFT")
        self.assertEqual(self.ns.settings.world.size, 10)
        f.scripts.OnGamePadButtonDown(f, "PAD1")
        self.assertFalse(f.IsShown(f))

    def test_clustering_keeps_all_categories_accessible_at_same_location(self):
        points = self.lua.eval('{{x=10,y=10,pin={id=1,kind="start"}},{x=11,y=10,pin={id=2,kind="start"}},{x=11,y=10,pin={id=3,kind="turnin"}}}')
        clusters = self.ns.Cluster(points, 24)
        self.assertEqual(len(clusters), 1)
        self.assertEqual(len(clusters[1].pins), 3)
        self.assertTrue(clusters[1].mixed)


if __name__ == "__main__":
    unittest.main()
