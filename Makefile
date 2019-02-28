S3_BUCKET = chicago-election-2019
WARDS = 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50
COUNCIL_WARDS = 20 25 council
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
	aws s3 cp council.html s3://$(S3_BUCKET)/council.html --acl=public-read --region=us-east-1
	aws s3 cp style-council.json s3://$(S3_BUCKET)/style-council.json --acl=public-read --region=us-east-1
	aws s3 cp ./council s3://$(S3_BUCKET)/council --recursive --acl=public-read --region=us-east-1

tiles: output/wards.mbtiles output/precincts.mbtiles $(foreach ward,$(COUNCIL_WARDS),output/wards-$(ward).mbtiles output/precincts-$(ward).mbtiles)
	mkdir -p tiles
	for f in $^; do tile-join --no-tile-size-limit --force -e ./tiles/$$(basename $$f .mbtiles) $$f; done

output/%.mbtiles: input/%.geojson
	$(eval geo=$(word 1, $(subst -, ,$*)))
	tippecanoe --simplification=10 --simplify-only-low-zooms --maximum-zoom=$($(geo)-zoom) --no-tile-stats \
	--force --detect-shared-borders --coalesce-smallest-as-needed -L $*:$< -o $@

output/council-name-map.json: input/raw-precincts-council.geojson
	cat $< | python scripts/council_prop_map.py > $@

input/precincts-%.geojson: input/council-ward-%.csv
	wget -q -O - 'https://data.cityofchicago.org/api/geospatial/uvpq-qeeq?method=export&format=GeoJSON' | \
	mapshaper -i - \
	-filter-fields ward,precinct,full_text \
	-rename-fields geoid=full_text \
	-join $< field-types=geoid:str keys=geoid,geoid calc='COUNT = count()' \
	-filter 'COUNT > 0' -o $@

input/wards-%.geojson: input/council-ward-%.csv
	wget -q -O - 'https://data.cityofchicago.org/api/geospatial/sp34-6z76?method=export&format=GeoJSON' | \
	mapshaper -i - -filter-fields ward \
	-join $< field-types=geoid:str keys=ward,geoid calc='COUNT = count()' \
	-filter 'COUNT > 0' -o $@

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


input/wards-council.geojson: input/wards-council.csv
	wget -q -O - 'https://data.cityofchicago.org/api/geospatial/sp34-6z76?method=export&format=GeoJSON' | \
	mapshaper -i - -filter-fields ward \
	-join $< field-types=ward:str keys=ward,ward -o $@

input/wards-council.csv: input/precincts-council.geojson 
	cat $< | python scripts/combine_precincts_wards.py > $@

input/precincts-council.geojson: input/raw-precincts-council.geojson
	cat $< | python scripts/process_council_results.py > $@

input/raw-precincts-council.geojson:
	wget -O $@ https://raw.githubusercontent.com/datamade/chicago-municipal-elections/master/data/municipal_general_2019.geojson


council: $(foreach ward,$(WARDS),input/council-ward-$(ward).xls)

wards: $(foreach ward,$(WARDS),input/ward-$(ward).xls)

input/council-ward-%.csv: input/council-ward-%.xls
	cat $< | python3 scripts/process_council.py > $@

input/council-ward-%.xls:
	$(eval race_num=$(shell expr 12 + $*))
	wget -O $@ 'https://chicagoelections.com/en/data-export.asp?election=210&race=$(race_num)'

input/ward-%.csv: input/ward-%.xls
	cat $< | python3 scripts/process_export.py > $@

input/ward-%.xls:
	wget -O $@ 'https://chicagoelections.com/en/data-export.asp?election=210&race=10&ward=$*&precinct='
