REPO := `git remotes | grep -oE "/.*\.git" | sed "s/\/\(.*\)\.git/\1/g" | head -n 1`
USER := `git remotes | grep -oE "\:.*\/" | sed "s/\:\(.*\)\//\1/g" | head -n 1`

build:
	reveal-md source/slides.md --theme moon --preprocessor source/pre-hack.js \
		--static docs --static-dirs=source \
		--assets-dir=source \
		--absolute-url https://{{USER}}.github.io/{{REPO}}/
	rm docs/slides.md

serve:
	reveal-md source/slides.md --theme moon --preprocessor source/pre-hack.js
