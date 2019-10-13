BUILD_ID=$(shell date --iso-8601='seconds')

.PHONY: download-public deploy build server

download-public:
	$(call redprintf,">>> Downloading gh-pages branch in public folder")
	@git clone --branch=gh-pages git@github.com:ar3s3ru/website public

build:
	$(call blueprintf,">>> Building website")
	@hugo

server:
	$(call blueprintf,">>> Starting Hugo server")
	@hugo server

deploy: build
	$(call redprintf,">>> Deploying updates to Github")

	# Add changes to git
	@cd public ; \
		git add . ; \
		git commit -m "Rebuild site @ $(BUILD_ID)"; \
		git push origin gh-pages


define colorprintf
    @tput setaf $1
    @echo $2
    @tput sgr0
endef

define redprintf
	$(call colorprintf,1,$1)
endef

define blueprintf
	$(call colorprintf,6,$1)
endef
