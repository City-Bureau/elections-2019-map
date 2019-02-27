import csv
import sys

from bs4 import BeautifulSoup

COLUMNS = [
    "precinct",
    "total_votes",
    "joyce",
    "joyce_pct",
    "vallas",
    "vallas_pct",
    "wilson",
    "wilson_pct",
    "preckwinkle",
    "preckwinkle_pct",
    "daley",
    "daley_pct",
    "mccarthy",
    "mccarthy_pct",
    "chico",
    "chico_pct",
    "mendoza",
    "mendoza_pct",
    "enyia",
    "enyia_pct",
    "ford",
    "ford_pct",
    "salesgriffin",
    "salesgriffin_pct",
    "lightfoot",
    "lightfoot_pct",
    "fioretti",
    "fioretti_pct",
    "kozlar",
    "kozlar_pct",
]


if __name__ == "__main__":
    soup = BeautifulSoup(sys.stdin, "html.parser")
    ward = soup.select("tr:nth-of-type(1) td b")[0].text[5:]
    results = []
    for row in soup.select("tr")[2:]:
        row_data = {"ward": ward}
        is_ward = len(row.select("td b")) > 0
        for column, tag in zip(COLUMNS, row.select("td")):
            tag_data = tag.text
            if column == "precinct":
                if is_ward:
                    row_data["geoid"] = ward
                    row_data["precinct"] = ""
                else:
                    row_data["geoid"] = f"{ward.zfill(2)}{tag_data.zfill(3)}"
                    row_data["precinct"] = tag_data
            else:
                row_data[column] = (
                    float(tag_data[:-1])
                    if "%" in tag_data
                    else int(tag_data.replace(",", ""))
                )
        results.append(row_data)
    writer = csv.DictWriter(sys.stdout, fieldnames=["geoid", "ward"] + COLUMNS)
    writer.writeheader()
    writer.writerows(results)
