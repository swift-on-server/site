SHELL=/bin/bash

dev:
	toucan generate .

dist:
	toucan generate . --target live

diff:
	diff --color=always -r docs-v4 docs --exclude=api || true

watch:
	toucan watch .

serve:
	toucan serve -p 3000

opt: png jpg

png:
	find . -path ./dist -prune -o -type f -iname '*.png' -exec optipng -o7 {} \;

jpg:
	find . -path ./dist -prune -o -type f -iname '*.jp*g' | xargs jpegoptim --all-progressive '*.jpg'

cover:
	cd ./cover-image-generator/ && swift run
