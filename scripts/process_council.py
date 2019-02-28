import csv
import sys

from bs4 import BeautifulSoup


if __name__ == "__main__":
    columns = ["precinct", "total_votes"]
    soup = BeautifulSoup(sys.stdin, "html.parser")
    data_table = soup.select("table")[1]
    ward = data_table.select("tr:nth-of-type(1) td b")[0].text[5:]
    results = []
    for idx, row in enumerate(data_table.select("tr")[1:]):
        if idx == 0:
            for tag in row.select("td b")[2:]:
                text = tag.text
                if "%" in text:
                    columns.append(f"{columns[-1]}_pct")
                else:
                    name = tag.text.split()[-1]
                    columns.append(name.lower())
            continue
        row_data = {"ward": ward}
        is_ward = len(row.select("td b")) > 0
        for column, tag in zip(columns, row.select("td")):
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
    writer = csv.DictWriter(sys.stdout, fieldnames=["geoid", "ward"] + columns)
    writer.writeheader()
    writer.writerows(results)
