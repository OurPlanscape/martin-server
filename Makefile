.PHONY: build deploy test

PROJECT=planscape-23d66
APP_NAME=martin
ENV=dev
VERSION="$$(date '+%Y.%m.%d')-$$(git log --abbrev=10 --format=%h | head -1)"
APP=$(APP_NAME)-$(ENV)
DOCKER_REPO=planscape-$(APP_NAME)-$(ENV)
DOCKER_TAG=us-central1-docker.pkg.dev/$(PROJECT)/$(DOCKER_REPO)/$(APP_NAME):$(VERSION)
REGION=us-central1

build:
	docker build -t $(DOCKER_TAG) .

push:
	gcloud builds submit --tag $(DOCKER_TAG)

deploy: build push
	gcloud run deploy $(APP) --image $(DOCKER_TAG) --platform managed --region $(REGION)

run:
	docker compose up

shell:
	./bin/run.sh bash

get-tag:
	echo $(VERSION)