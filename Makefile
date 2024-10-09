SHELL=/bin/bash

# brew install optipng jpegoptim

dev:
	toucan generate ./src ./docs --base-url http://localhost:3000/

dist:
	toucan generate ./src ./docs

watch:
	toucan watch ./src ./docs --base-url http://localhost:3000/

serve:
	toucan serve ./docs -p 3000

png:
	find ./src/* -type f -name '*.png' -exec optipng -o7 {} \;

jpg:
	find ./src/* -type f -name '*.jpg' | xargs jpegoptim --all-progressive '*.jpg'
