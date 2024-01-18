build:
	toucan generate ./src ./docs

watch:
	toucan watch ./src ./docs --base-url /

serve:
	LOG_LEVEL=notice toucan serve

# brew install optipng jpegoptim

png:
	find ./src/* -type f -name '*.png' -exec optipng -o7 {} \;

jpg:
	find ./* -type f -name '*.jpg' | xargs jpegoptim --all-progressive '*.jpg' 