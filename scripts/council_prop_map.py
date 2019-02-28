import json
import re
import sys

IGNORE_PROPS = [
    "WARD",
    "PRECINCT",
    "REGISTERED VOTERS",
    "BALLOTS CAST",
    "JERRY JOYCE",
    "PAUL VALLAS",
    "WILLIE L. WILSON",
    "TONI PRECKWINKLE",
    "WILLIAM M. DALEY",
    "GARRY MCCARTHY",
    "GERY CHICO",
    "SUSANA A. MENDOZA",
    "AMARA ENYIA",
    "LA SHAWN K. FORD",
    "NEAL SALES-GRIFFIN",
    "LORI LIGHTFOOT",
    "ROBERT 'BOB' FIORETTI",
    "JOHN KENNETH KOZLAR",
]


if __name__ == "__main__":
    ward_candidate_map = {}
    data = json.load(sys.stdin)
    for feat in data["features"]:
        if feat["properties"]["WARD"] in ward_candidate_map:
            continue
        ward_candidate_map[feat["properties"]["WARD"]] = {
            re.sub(r"[^a-z\s]", "", key.lower()).replace(" ", "_"): key
            for key, value in feat["properties"].items()
            if key not in IGNORE_PROPS and value is not None
        }
    json.dump(ward_candidate_map, sys.stdout)
