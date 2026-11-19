"""Local, explicitly opt-in collection. The public game server never imports this."""
import argparse
from contextlib import contextmanager
import hashlib
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import re
import secrets
import sqlite3
from urllib.parse import urlsplit

HERE = Path(__file__).resolve().parent
NOTICE_VERSION = "pilot-training-2026-11-v1"
ORIGIN = "http://127.0.0.1:8773"
PRIVATE_PATTERNS = (
    re.compile(r'https?://|www\.|\b\S+@\S+\.\S+\b', re.I),
    re.compile(r'(?:\d[ .()+-]*){7,}'),
    re.compile(r'\b(?:my (?:real )?name is|school address|home address|phone number|password)\b', re.I),
)
CONSENT = (
    "I am an enrolled adult tester. I choose to submit this previewed fictional scene for possible "
    "commercial licensing to AI companies for training and evaluation. This is optional. "
    "I can withdraw a queued contribution with my invitation and receipt. After licensing, a withdrawal "
    "will be logged and sent to the buyer under its contract. Copies already used to train a model may "
    "not be removable. I confirm the preview has no personal details."
)


def token_hash(token):
    return hashlib.sha256(token.encode()).hexdigest()


class Store:
    def __init__(self, path):
        self.path = path
        path.parent.mkdir(parents=True, exist_ok=True)
        with self.connect() as db:
            db.executescript("""
                CREATE TABLE IF NOT EXISTS invitations (
                    digest TEXT PRIMARY KEY, cohort_id TEXT UNIQUE NOT NULL, active INTEGER NOT NULL DEFAULT 1
                );
                CREATE TABLE IF NOT EXISTS consent (
                    receipt TEXT PRIMARY KEY, cohort_id TEXT NOT NULL, version TEXT NOT NULL,
                    received_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
                );
                CREATE TABLE IF NOT EXISTS contribution (
                    receipt TEXT PRIMARY KEY, payload TEXT NOT NULL, state TEXT NOT NULL DEFAULT 'queued',
                    agreement TEXT DEFAULT NULL
                );
            """)

    @contextmanager
    def connect(self):
        db = sqlite3.connect(self.path)
        try:
            with db:
                yield db
        finally:
            db.close()

    def invite(self, adult_verified):
        if not adult_verified:
            raise ValueError("An operator must verify the participant is an adult before issuing a code.")
        code = secrets.token_urlsafe(32)
        with self.connect() as db:
            db.execute("INSERT INTO invitations(digest,cohort_id) VALUES(?,?)",
                       (token_hash(code), secrets.token_hex(16)))
        return code

    def member(self, db, token):
        if not isinstance(token, str) or len(token) != 43:
            raise ValueError("An active adult tester invitation is required.")
        row = db.execute("SELECT cohort_id FROM invitations WHERE digest=? AND active=1",
                         (token_hash(token),)).fetchone()
        if not row:
            raise ValueError("An active adult tester invitation is required.")
        return row[0]

    def submit(self, token, draft):
        if draft.get("agreed") is not True or draft.get("version") != NOTICE_VERSION:
            raise ValueError("Review the current consent and confirm that you want to submit.")
        payload = validate_draft(draft)
        receipt = secrets.token_hex(16)
        with self.connect() as db:
            cohort_id = self.member(db, token)
            db.execute("INSERT INTO consent(receipt,cohort_id,version) VALUES(?,?,?)",
                       (receipt, cohort_id, NOTICE_VERSION))
            db.execute("INSERT INTO contribution(receipt,payload) VALUES(?,?)",
                       (receipt, json.dumps(payload, ensure_ascii=False)))
        return receipt

    def withdraw(self, token, receipt):
        with self.connect() as db:
            owner = self.member(db, token)
            row = db.execute("""SELECT state,agreement FROM contribution JOIN consent USING(receipt)
                               WHERE receipt=? AND cohort_id=?""", (receipt, owner)).fetchone()
            if not row:
                raise ValueError("No contribution matched that invitation and receipt.")
            state, agreement = row
            if agreement:
                db.execute("UPDATE contribution SET state='notify_buyer', payload='{}' WHERE receipt=?", (receipt,))
                return "Withdrawal recorded. Operator must notify the buyer and record follow-through."
            db.execute("DELETE FROM contribution WHERE receipt=?", (receipt,))
            db.execute("DELETE FROM consent WHERE receipt=?", (receipt,))
            return "Contribution withdrawn."

    def decide(self, receipt, approved):
        with self.connect() as db:
            cursor = db.execute("UPDATE contribution SET state=?, payload=CASE WHEN ? THEN payload ELSE '{}' END WHERE receipt=? AND state='queued'",
                                ("approved" if approved else "rejected", bool(approved), receipt))
            if cursor.rowcount != 1:
                raise ValueError("Only queued contributions can be approved or rejected.")

    def export(self, path, agreement, rights_verified):
        if not rights_verified or not re.fullmatch(r'[A-Za-z0-9_-]{3,80}', agreement or ''):
            raise ValueError("Export requires a signed agreement reference and verification of both sides’ training rights.")
        with self.connect() as db:
            db.execute("BEGIN IMMEDIATE")
            if path.exists():
                raise ValueError("Choose a fresh export path.")
            rows = db.execute("""SELECT receipt,payload,version FROM contribution JOIN consent USING(receipt)
                                 WHERE state='approved' AND agreement IS NULL ORDER BY receipt""").fetchall()
            if not rows:
                raise ValueError("No reviewed and unlicensed contributions are available.")
            # Reserve before writing so a failed or interrupted export never silently
            # releases this batch again. Recover a failed batch out of band.
            db.executemany("UPDATE contribution SET state='export_reserved',agreement=? WHERE receipt=?",
                           [(agreement, row[0]) for row in rows])
        with path.open("x", encoding="utf-8", newline="\n") as output:
            for receipt, payload, version in rows:
                item = {"contribution_id": receipt, **json.loads(payload), "consent_version": version}
                output.write(json.dumps(item, ensure_ascii=False) + "\n")
        with self.connect() as db:
            db.executemany("UPDATE contribution SET state='licensed' WHERE receipt=? AND state='export_reserved'",
                           [(row[0],) for row in rows])
        return len(rows)


def validate_draft(draft):
    level, outcome, language = (draft.get(key) for key in ("level", "outcome", "language"))
    if type(level) is not int or not 0 <= level < 3 or outcome not in ("success", "failure"):
        raise ValueError("Choose a valid school mission and result.")
    if language not in ("ta", "ta-Latn", "en"):
        raise ValueError("Identify the fictional conversation language.")
    raw = draft.get("turns")
    if not isinstance(raw, list) or not 2 <= len(raw) <= 9:
        raise ValueError("Submit a conversation with at least one tester message and one Qwen reply.")
    turns = []
    for turn in raw:
        role = turn.get("role") if isinstance(turn, dict) else None
        content = turn.get("content") if isinstance(turn, dict) else None
        if role not in ("user", "assistant") or not isinstance(content, str) or not 1 <= len(content.strip()) <= 1200:
            raise ValueError("Each turn must be short text from the tester or Sundaram.")
        if any(pattern.search(content) for pattern in PRIVATE_PATTERNS):
            raise ValueError("The preview may contain personal details. Remove them or discard the contribution.")
        turns.append({"role": role, "content": content.strip()})
    if not any(turn["role"] == "user" for turn in turns) or raw[-1]["role"] != "assistant":
        raise ValueError("Include a completed test exchange.")
    return {"level": level, "outcome": outcome, "speaker": "sundaram", "language": language,
            "source": "consented_adult_playtest", "turns": turns}


def serve(store, directory):
    directory = directory.resolve()
    if not (directory / "index.html").is_file() or not any(
        (directory / f"game-v{version}.pck").is_file() for version in (7, 8, 9)
    ):
        raise ValueError("Point the pilot at a built school preview (v7, v8 or v9).")

    class PilotHandler(SimpleHTTPRequestHandler):
        def __init__(self, *args):
            super().__init__(*args, directory=str(directory))

        def log_message(self, *_args):
            pass

        def reply(self, status, data):
            raw = json.dumps(data, ensure_ascii=False).encode()
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(raw)))
            self.end_headers()
            self.wfile.write(raw)

        def do_GET(self):
            if self.headers.get("Host") != "127.0.0.1:8773":
                return self.reply(403, {"error": "Use the local pilot address."})
            route = urlsplit(self.path).path
            if route in ("/", "/index.html"):
                html = (directory / "index.html").read_text(encoding="utf-8")
                script = '<script src="/pilot-review.js"></script>'
                raw = html.replace("</body>", script + "</body>").encode()
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Cache-Control", "no-store")
                self.send_header("Content-Length", str(len(raw)))
                self.end_headers()
                self.wfile.write(raw)
            elif route == "/pilot-review.js":
                raw = (HERE / "review.js").read_bytes()
                self.send_response(200)
                self.send_header("Content-Type", "application/javascript")
                self.send_header("Cache-Control", "no-store")
                self.send_header("Content-Length", str(len(raw)))
                self.end_headers()
                self.wfile.write(raw)
            elif re.fullmatch(r"/(?:game-v[789]\.[A-Za-z0-9.]+|chat\.(?:js|css)|cover-v2\.png|CinzelDecorative-Bold\.ttf)", route):
                super().do_GET()
            else:
                self.reply(404, {"error": "Not found."})

        def do_POST(self):
            if self.headers.get("Origin") != ORIGIN or self.headers.get("Host") != "127.0.0.1:8773":
                return self.reply(403, {"error": "Only the local pilot can submit."})
            try:
                route = urlsplit(self.path).path
                token = self.headers.get("Authorization", "").removeprefix("Bearer ")
                size = int(self.headers.get("Content-Length", "0"))
                if not 0 < size <= 24000:
                    raise ValueError("Invalid request size.")
                body = json.loads(self.rfile.read(size))
                if not isinstance(body, dict):
                    raise ValueError("Expected a JSON object.")
                if route == "/pilot/enroll":
                    with store.connect() as db:
                        store.member(db, token)
                    return self.reply(200, {"notice": CONSENT, "version": NOTICE_VERSION})
                if route == "/pilot/submit":
                    return self.reply(201, {"receipt": store.submit(token, body)})
                if route == "/pilot/withdraw":
                    return self.reply(200, {"message": store.withdraw(token, body.get("receipt"))})
                return self.reply(404, {"error": "Not found."})
            except (ValueError, TypeError) as error:
                self.reply(400, {"error": str(error)})
    with ThreadingHTTPServer(("127.0.0.1", 8773), PilotHandler) as server:
        print("Adult tester pilot at http://127.0.0.1:8773. Keep this port local to the PC.", flush=True)
        server.serve_forever()


def main():
    cli = argparse.ArgumentParser()
    cli.add_argument("--database", required=True, type=Path, help="Private SQLite path outside browser assets and outside Git.")
    sub = cli.add_subparsers(dest="command", required=True)
    sub.add_parser("invite").add_argument("--adult-verified", action="store_true")
    sub.add_parser("serve").add_argument("directory", type=Path)
    sub.add_parser("review")
    for command in ("approve", "reject"):
        sub.add_parser(command).add_argument("receipt")
    export_args = sub.add_parser("export")
    export_args.add_argument("output", type=Path)
    export_args.add_argument("--agreement", required=True)
    export_args.add_argument("--rights-verified", action="store_true")
    args = cli.parse_args()
    db_path = args.database.expanduser().resolve()
    if "build" in db_path.parts or ".git" in db_path.parts or not db_path.suffix == ".sqlite":
        cli.error("Store a .sqlite database in a private directory outside browser build and .git paths.")
    try:
        store = Store(db_path)
        if args.command == "serve":
            serve(store, args.directory)
        elif args.command == "invite":
            print(store.invite(args.adult_verified))
        elif args.command == "review":
            with store.connect() as db:
                rows = db.execute("SELECT receipt,state,agreement,payload FROM contribution WHERE state IN ('queued','notify_buyer','export_reserved') ORDER BY receipt")
                for item in rows:
                    print(json.dumps(dict(zip(("receipt","state","agreement","payload"),item)), ensure_ascii=False))
        elif args.command in ("approve", "reject"):
            store.decide(args.receipt, args.command == "approve")
        elif args.command == "export":
            print("Exported", store.export(args.output, args.agreement, args.rights_verified), "reviewed contributions.")
    except (ValueError, OSError) as error:
        cli.error(str(error))


if __name__ == "__main__":
    main()
