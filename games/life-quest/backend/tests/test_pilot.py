import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("school_pilot", Path(__file__).resolve().parents[1] / "pilot" / "pilot.py")
pilot = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pilot)


class PilotTests(unittest.TestCase):
    def setUp(self):
        self.workspace = tempfile.TemporaryDirectory()
        self.addCleanup(self.workspace.cleanup)
        self.path = Path(self.workspace.name)
        self.store = pilot.Store(self.path / "test.sqlite")
        self.invite = self.store.invite(True)
        self.draft = {
            "level": 2, "outcome": "success", "language": "en",
            "turns": [
                {"role": "user", "content": "I will ask if she wants the note."},
                {"role": "assistant", "content": "Good. Give her the choice."},
            ],
            "agreed": True, "version": pilot.NOTICE_VERSION,
        }

    def count(self):
        with self.store.connect() as db:
            return db.execute("SELECT COUNT(*) FROM contribution").fetchone()[0]

    def test_enrollment_alone_never_records_chat(self):
        with self.store.connect() as db:
            self.store.member(db, self.invite)
        self.assertEqual(self.count(), 0)
        with self.assertRaises(ValueError):
            self.store.invite(False)

    def test_rejects_wrong_invite_or_consent(self):
        with self.assertRaises(ValueError):
            self.store.submit("not-enrolled", self.draft)
        with self.assertRaises(ValueError):
            self.store.submit(self.invite, {**self.draft, "agreed": False})
        self.assertEqual(self.count(), 0)

    def test_rejects_possible_personal_data(self):
        self.draft["turns"][0]["content"] = "My contact is tester@example.org"
        with self.assertRaises(ValueError):
            self.store.submit(self.invite, self.draft)
        self.assertEqual(self.count(), 0)

    def test_withdrawal_is_scoped_and_removed_before_export(self):
        receipt = self.store.submit(self.invite, self.draft)
        with self.assertRaises(ValueError):
            self.store.withdraw(self.store.invite(True), receipt)
        self.assertEqual(self.store.withdraw(self.invite, receipt), "Contribution withdrawn.")
        self.assertEqual(self.count(), 0)

    def test_export_only_reviewed_and_rights_verified(self):
        receipt = self.store.submit(self.invite, self.draft)
        self.store.submit(self.invite, self.draft)
        output = self.path / "training.jsonl"
        with self.assertRaises(ValueError):
            self.store.export(output, "signed-demo", True)
        self.store.decide(receipt, True)
        with self.assertRaises(ValueError):
            self.store.export(output, "signed-demo", False)
        self.assertEqual(self.store.export(output, "signed-demo", True), 1)
        item = json.loads(output.read_text(encoding="utf8"))
        self.assertEqual(item["contribution_id"], receipt)
        self.assertNotIn("cohort_id", item)
        self.assertIn("buyer", self.store.withdraw(self.invite, receipt))
