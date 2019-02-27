S3_BUCKET = chicago-election-2019
WARDS = 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50
wards-zoom = 9
precincts-zoom = 11

.PHONY: all wards tiles

all: tiles

clean:
	rm -rf input/*.geojson output/*.mbtiles tiles

deploy:
	aws s3 cp ./tiles s3://$(S3_BUCKET)/ --recursive --acl=public-read --content-encoding=gzip --region=us-east-1
	aws s3 cp index.html s3://$(S3_BUCKET)/index.html --acl=public-read --region=us-east-1
	aws s3 cp style.json s3://$(S3_BUCKET)/style.json --acl=public-read --region=us-east-1

tiles: output/wards.mbtiles output/precincts.mbtiles
	mkdir -p tiles
	tile-join --no-tile-size-limit --force -e ./tiles/wards $<
	tile-join --no-tile-size-limit --force -e ./tiles/precincts $(filter-out $<,$^)

output/%.mbtiles: input/%.geojson
	tippecanoe --simplification=10 --simplify-only-low-zooms --maximum-zoom=$($*-zoom) --no-tile-stats \
	--force --detect-shared-borders --coalesce-smallest-as-needed -L $*:$< -o $@

input/precincts.geojson: input/results.csv
	wget -q -O - 'https://data.cityofchicago.org/api/geospatial/uvpq-qeeq?method=export&format=GeoJSON' | \
	mapshaper -i - \
	-filter-fields ward,precinct,full_text \
	-rename-fields geoid=full_text \
	-join $< field-types=geoid:str keys=geoid,geoid -o $@

input/wards.geojson: input/results.csv
	wget -q -O - 'https://data.cityofchicago.org/api/geospatial/sp34-6z76?method=export&format=GeoJSON' | \
	mapshaper -i - -filter-fields ward \
	-join $< field-types=geoid:str keys=ward,geoid -o $@

input/results.csv: $(foreach ward,$(WARDS),input/ward-$(ward).csv)
	csvstack $^ > $@

wards: $(foreach ward,$(WARDS),input/ward-$(ward).xls)

input/ward-%.csv: input/ward-%.xls
	cat $< | python3 scripts/process_export.py > $@

input/ward-%.xls:
	wget -O $@ 'https://chicagoelections.com/en/data-export.asp?election=210&race=10&ward=$*&precinct='