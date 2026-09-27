"""Import only the explicitly MIT-licensed ATT-derived start records, never addon code."""
from hashlib import sha256
from pathlib import Path
from urllib.request import urlopen
import argparse

ROOT = Path(__file__).resolve().parents[1]
COMMIT = "24f1c3863488e892a75d7c4a06e19aec9b85e202"
URL = f"https://raw.githubusercontent.com/TylerAkins/forever-quest-markers/{COMMIT}/Database/ForeverQuests.lua"
SHA256 = "6f443761f958252c62d4b73df97c73d29c757b7578825873a6281fdf331d9c05"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, help="Use a previously downloaded copy (checksum still required)")
    args = parser.parse_args()
    raw = args.source.read_bytes() if args.source else urlopen(URL, timeout=60).read()
    if sha256(raw).hexdigest() != SHA256:
        raise SystemExit("Source checksum mismatch; review provenance before changing the pinned source.")
    text = raw.decode("utf-8")
    if text.count("ns.Quests = {") != 1:
        raise SystemExit("Unexpected source format")
    text = text.replace("ns.Quests = {", "ns.StartDB = {", 1)
    header = ("-- ATT-derived records, MIT. See Licenses/ATT-MIT.txt and THIRD_PARTY_NOTICES.md.\n"
              "-- Modification: namespace renamed from Quests to StartDB; records unchanged.\n"
              f"-- Redistribution source: {URL}\n")
    output = ROOT / "addon/QuestMapGamepad/Data/Starts.lua"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(header + text, encoding="utf-8", newline="\n")
    print(f"Imported MIT start records: {output.name}")


if __name__ == "__main__":
    main()
