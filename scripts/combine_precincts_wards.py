import csv
import json
import sys


IGNORE_PROPS = ["ward", "precinct"]


if __name__ == "__main__":
    data = json.load(sys.stdin)
    ward_data_map = {}
    for feature in data["features"]:
        ward = feature["properties"]["ward"]
        if ward not in ward_data_map:
            ward_data_map[ward] = feature["properties"]
            for prop in IGNORE_PROPS:
                ward_data_map[ward].pop(prop, None)
        else:
            for prop in feature["properties"].keys():
                if prop in IGNORE_PROPS or feature["properties"][prop] is None:
                    continue
                ward_data_map[ward][prop] += feature["properties"][prop]
    data_list = []
    for key, value in ward_data_map.items():
        data_list.append({**value, "ward": key})
    writer = csv.DictWriter(sys.stdout, list(data_list[0].keys()))
    writer.writeheader()
    writer.writerows(data_list)
