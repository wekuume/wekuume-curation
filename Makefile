REV:=$(shell git rev-parse --short HEAD)

default: prepare generate

help:
	@echo "Commands:"
	@echo "	make 							Builds targets from source catalogue"
	@echo "	make serve 				Builds targets with debug output and serve web build"
	@echo "	make install			Installs latest GitBook and dependencies"
	@echo ""

modules:
	npm install

content:
	git clone https://github.com/wekuume/wekuume-content content

prepare: modules content
	cd content;	\
	git pull

gitbook: web/build/_book/gitbook

serve: generate
	cd web/build/citizen && gitbook install .
	cd web/build/citizen && gitbook build .
	cd web/build/journo && gitbook install .
	cd web/build/journo && gitbook build .
	cd web/build/hrd && gitbook install .
	cd web/build/hrd && gitbook build .
	@mv web/build/citizen/_book web/build && mv web/build/journo/_book web/build/_book/journo && mv web/build/hrd/_book web/build/_book/hrd;
	cd web/build/_book; http-server .

serve-journo:
	profile=journo metalsmith --config web/metalsmith.json
	mv web/build web/build-journo
	mkdir web/build
	mv web/build-journo web/build/journo
	cp -R web/src/journo/* web/build/journo
	cp web/src/book.json web/build/journo
	cp web/src/LANGS.md web/build/journo
	cd web/build/journo && gitbook install .
	cd web/build/journo && gitbook build .
	cd web/build/journo/_book; http-server .

generate:
	# Metalsmith build for mobile content (for now only index.json)
	metalsmith --config mobile/metalsmith.json
	# profile=hrd metalsmith --config web/metalsmith.json
  # Metalsmith build for different web site profiles (building as gitbook source)
	profile=journo metalsmith --config web/metalsmith.json
	mv web/build web/build-journo
	profile=hrd metalsmith --config web/metalsmith.json
	mv web/build web/build-hrd
	metalsmith --config web/metalsmith.json
	mv web/build web/build-citizen
	mkdir web/build
	mv web/build-journo web/build/journo
	mv web/build-hrd web/build/hrd
	mv web/build-citizen web/build/citizen
	# TODO: move this to metalsmith build somehow
	cp -R web/src/citizen/* web/build/citizen
	cp web/src/book.json web/build/citizen
	cp web/src/LANGS.md web/build/citizen
	cp -R web/src/journo/* web/build/journo
	cp web/src/book.json web/build/journo
	cp web/src/LANGS.md web/build/journo
	cp -R web/src/hrd/* web/build/hrd
	cp web/src/book.json web/build/hrd
	cp web/src/LANGS.md web/build/hrd
	cp web/src/.nojekyll web/build
	cp web/src/.travis.yml web/build
	cp web/src/Makefile web/build
	cp web/src/LANGS.md web/build
	cp web/src/versions web/build
	cp web/src/README.md web/build
	# TODO: Metalsmith build for print version.
	profile=journo metalsmith --config print/metalsmith.json

SUBDIRS := $(wildcard mobile/build/*/topics/*)
ZIPS := $(addsuffix .zip,$(patsubst /,,$(SUBDIRS)))

$(ZIPS) : %.zip : | %
	cd $(dir $*); \
	zip -r $(subst $(dir $*),,$@) $(subst $(dir $*),,$*/*); \
	rm -rf $(subst $(dir $*),,$*/*)

dist: $(ZIPS)

deploy-web: dist
	# Copy mobile build with zipped topics to web source
	@mkdir -p web/build/dist; \
	cp -R mobile/build/* web/build/dist; \
	cd web/build; \
	git init; \
	git config --local user.name "Travis CI wekuume-web auto-build"; \
	git config --local user.email "joshoke2003@gmail.com"; \
	git remote add upstream "https://${GH_TOKEN}@github.com/wekuume/wekuume-web.git"; \
	git fetch upstream; \
 	git reset upstream/master; \
	touch .; \
	git add -A .; \
	git commit -m "Rebuilt website source at ${REV}"; \
	git push upstream HEAD:master

# -- push to master branch
deploy-mobile: dist
	git clone "https://github.com/wekuume/wekuume.com.git" mobile/build-web; \
	cp -R mobile/build mobile/build-web/dist; \
	cd mobile/build-web; \
	git config --local user.name "Travis CI wekuume-auto-builder"; \
	git config --local user.email "joshoke2003@gmail.com"; \
	git remote add upstream "https://${GH_TOKEN}@github.com/wekuume/wekuume.com.git"; \
	git fetch upstream; \
	git reset upstream/master; \
	touch .; \
	git add -A .; \
	git commit -m "Rebuilt mobile index at ${REV}"; \
	git push -q upstream HEAD:master 

# -- push to gh-pages - find better way to do this and merge in single build
deploy-mob: dist
	git clone "https://github.com/wekuume/wekuume.com.git" -b gh-pages mobile/build-mob; \
	cp -R mobile/build mobile/build-mob/dist; \
	cd mobile/build-mob; \
	git config --local user.name "Travis CI wekuume-auto-builder"; \
	git config --local user.email "joshoke2003@gmail.com"; \
	git remote add upstream "https://${GH_TOKEN}@github.com/wekuume/wekuume.com.git"; \
	git fetch upstream; \
	git reset upstream/gh-pages; \
	touch .; \
	git add -A .; \
	git commit -m "Rebuilt gh-pages for mobile index at ${REV}"; \
	git push -q upstream HEAD:gh-pages

#only deploy for mobile
install: deploy-mobile deploy-mob deploy-web
