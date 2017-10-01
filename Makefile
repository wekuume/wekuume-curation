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

generate:
	# Metalsmith build for mobile content (for now only index.json)
	metalsmith --config mobile/metalsmith.json

SUBDIRS := $(wildcard mobile/build/*/topics/*)
ZIPS := $(addsuffix .zip,$(patsubst /,,$(SUBDIRS)))

$(ZIPS) : %.zip : | %
	cd $(dir $*); \
	zip -r $(subst $(dir $*),,$@) $(subst $(dir $*),,$*/*); \
	rm -rf $(subst $(dir $*),,$*/*)

dist: $(ZIPS)

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

#only deploy for mobile
install: deploy-mobile 
