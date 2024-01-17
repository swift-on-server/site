build:
	toucan generate ./src ./docs

watch:
	toucan watch ./src ./docs --base-url /

serve:
	LOG_LEVEL=notice toucan serve
