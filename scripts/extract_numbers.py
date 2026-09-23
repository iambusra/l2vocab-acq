#!/usr/bin/env python3
"""Extract the raw Apple Numbers tables to canonical CSV files.

The source files are never modified. Participant codes are retained because they
are required for longitudinal matching and random effects, but the script never
prints individual records.
"""

from __future__ import annotations

import csv
from pathlib import Path

from numbers_parser import Document


ROOT = Path(__file__).resolve().parents[1]
INTERIM = ROOT / "data" / "interim"
SOURCES = {
    "pretest": ROOT / "data" / "raw" / "pretest" / "Pretest scoressssss.numbers",
    "posttest": ROOT / "data" / "raw" / "posttest" / "post test scores .numbers",
}

RESPONSE_COLUMNS = [
    "participant_id",
    "condition",
    *[f"q{item:02d}_response" for item in range(1, 21)],
]
KEY_COLUMNS = [
    "item_pair",
    "target_word",
    "target_key",
    "grounding_word",
    "grounding_key",
    "thematic_word",
    "thematic_key",
    "control_word",
    "control_key",
]


def get_table(document: Document, sheet_name: str) -> list[list[object]]:
    sheet = next((candidate for candidate in document.sheets if candidate.name == sheet_name), None)
    if sheet is None or len(sheet.tables) != 1:
        raise ValueError(f"Expected one table on sheet {sheet_name!r}")
    return sheet.tables[0].rows(values_only=True)


def write_csv(path: Path, header: list[str], rows: list[list[object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(header)
        writer.writerows(rows)


def validate_responses(rows: list[list[object]], wave: str) -> None:
    if len(rows) != 90 or any(len(row) != 22 for row in rows):
        raise ValueError(f"{wave}: expected 90 response rows and 22 columns")

    participant_ids = [str(row[0]).strip() for row in rows]
    if len(set(participant_ids)) != 90 or any(not value for value in participant_ids):
        raise ValueError(f"{wave}: participant codes must be non-empty and unique")

    conditions = {str(row[1]).strip().lower() for row in rows}
    if conditions != {"control", "thematic", "grounding"}:
        raise ValueError(f"{wave}: unexpected condition labels")

    answers = [str(value).strip().upper() for row in rows for value in row[2:]]
    if any(value not in {"A", "B", "C", "D"} for value in answers):
        raise ValueError(f"{wave}: all responses must be A, B, C, or D")


def validate_keys(rows: list[list[object]], wave: str) -> None:
    if len(rows) != 10 or any(len(row) != 9 for row in rows):
        raise ValueError(f"{wave}: expected 10 key rows and 9 columns")
    key_values = [str(row[index]).strip().upper() for row in rows for index in (2, 4, 6, 8)]
    if any(value not in {"A", "B", "C", "D"} for value in key_values):
        raise ValueError(f"{wave}: answer keys must be A, B, C, or D")


def main() -> None:
    counts: dict[str, int] = {}
    for wave, source in SOURCES.items():
        document = Document(source)
        response_table = get_table(document, "Responses")
        key_table = get_table(document, "Keys")

        response_rows = response_table[1:]
        key_rows = key_table[1:]
        validate_responses(response_rows, wave)
        validate_keys(key_rows, wave)

        canonical_responses = [
            [
                str(row[0]).strip(),
                str(row[1]).strip().title(),
                *[str(value).strip().upper() for value in row[2:]],
            ]
            for row in response_rows
        ]
        canonical_keys = [
            [str(value).strip() for value in row]
            for row in key_rows
        ]

        write_csv(INTERIM / f"{wave}_responses.csv", RESPONSE_COLUMNS, canonical_responses)
        write_csv(INTERIM / f"{wave}_keys.csv", KEY_COLUMNS, canonical_keys)
        counts[wave] = len(canonical_responses)

    if counts["pretest"] != counts["posttest"]:
        raise ValueError("Pretest and post-test participant counts differ")
    print(f"Extracted {counts['pretest']} coded participants at each of 2 waves.")


if __name__ == "__main__":
    main()

