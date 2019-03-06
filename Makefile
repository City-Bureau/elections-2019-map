S3_BUCKET = chicago-election-2019
WARDS = 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50
COUNCIL_WARDS = 20 25 council
wards-zoom = 9
precincts-zoom = 11

.PHONY: all tiles

all: tiles

clean:
	rm -rf input/*.* output/*.* tiles

deploy:
	aws s3 cp ./tiles s3://$(S3_BUCKET)/ --recursive --acl=public-read --content-encoding=gzip --region=us-east-1
	aws s3 cp index.html s3://$(S3_BUCKET)/index.html --acl=public-read --region=us-east-1
	aws s3 cp style.json s3://$(S3_BUCKET)/style.json --acl=public-read --region=us-east-1
	aws s3 cp council.html s3://$(S3_BUCKET)/council.html --acl=public-read --region=us-east-1
	aws s3 cp style-council.json s3://$(S3_BUCKET)/style-council.json --acl=public-read --region=us-east-1
	aws s3 cp turnout.html s3://$(S3_BUCKET)/turnout.html --acl=public-read --region=us-east-1
	aws s3 cp style-turnout.json s3://$(S3_BUCKET)/style-turnout.json --acl=public-read --region=us-east-1
	aws s3 cp ./img/teaser.jpg s3://$(S3_BUCKET)/teaser.jpg --acl=public-read --region=us-east-1

tiles: output/wards-mayor.mbtiles output/wards-council.mbtiles output/precincts-mayor.mbtiles output/precincts-council.mbtiles
	mkdir -p tiles
	for f in $^; do tile-join --no-tile-size-limit --force -e ./tiles/$$(basename $$f .mbtiles) $$f; done

output/%.mbtiles: input/%.geojson
	$(eval geo=$(word 1, $(subst -, ,$*)))
	tippecanoe --simplification=10 --simplify-only-low-zooms --maximum-zoom=$($(geo)-zoom) --no-tile-stats \
	--force --detect-shared-borders --coalesce-smallest-as-needed -L $*:$< -o $@

output/council-name-map.json: input/raw-results.geojson
	cat $< | python scripts/council_prop_map.py > $@

input/wards-%.geojson: input/wards-%.csv input/wards.geojson
	mapshaper -i $(filter-out $<,$^) -filter-fields ward \
	-join $< field-types=ward:str keys=ward,ward -o $@

input/wards-%.csv: input/precincts-%.geojson
	cat $< | python scripts/combine_precincts_wards.py > $@

input/precincts-%.geojson: input/raw-results.geojson input/wards.geojson
	mapshaper -i $< -clip $(filter-out $<,$^) -o - | \
	python scripts/process_results.py --$* > $@

input/wards.geojson:
	wget -O $@ 'https://data.cityofchicago.org/api/geospatial/sp34-6z76?method=export&format=GeoJSON'

input/raw-results.geojson:
	wget -O $@ https://raw.githubusercontent.com/datamade/chicago-municipal-elections/master/data/municipal_general_2019.geojson
