import json
import re
import sys

BASE_PROPS = ["WARD", "PRECINCT", "REGISTERED VOTERS", "BALLOTS CAST"]

MAYOR_CANDIDATES = [
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
    data = json.load(sys.stdin)
    if "--council" in sys.argv:
        remove_props = MAYOR_CANDIDATES
    else:
        remove_props = [
            prop
            for prop in data["features"][0]["properties"].keys()
            if prop not in BASE_PROPS + MAYOR_CANDIDATES
        ]
    for feat in data["features"]:
        for prop in remove_props:
            feat["properties"].pop(prop, None)
        keys = list(feat["properties"].keys())
        for key in keys:
            feat["properties"][
                re.sub(r"[^a-z\s]", "", key.lower()).replace(" ", "_")
            ] = feat["properties"].pop(key)
    json.dump(data, sys.stdout)
