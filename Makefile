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

png:
	find ./* -type f -name '*.png' -exec optipng -o7 {} \;

jpg:
	find ./* -type f -name '*.jpg' | xargs jpegoptim --all-progressive '*.jpg'
cover:
	cd ./cover-image-generator/ && swift run
