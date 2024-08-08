SHELL=/bin/bash

# brew install optipng jpegoptim

png:
	find ./dist/* -type f -name '*.png' -exec optipng -o7 {} \;

jpg:
	find ./dist/* -type f -name '*.jpg' | xargs jpegoptim --all-progressive '*.jpg'
