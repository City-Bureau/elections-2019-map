import json
import re
import sys

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
    for feat in data["features"]:
        for candidate in MAYOR_CANDIDATES:
            feat["properties"].pop(candidate, None)
        keys = list(feat["properties"].keys())
        for key in keys:
            feat["properties"][
                re.sub(r"[^a-z\s]", "", key.lower()).replace(" ", "_")
            ] = feat["properties"].pop(key)
    json.dump(data, sys.stdout)
