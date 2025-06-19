.DEFAULT_GOAL := help

SHELL=/bin/bash
TAG		?= 1.0.0 #$(shell git rev-parse --short HEAD)
RG		:= go-containerapps-rg
SUFFIX		:= 01jmcsp02ds1wm0gg541tndr6y4
LOCATION 	:= eastasia
KO_DOCKER_REPO	:= acr$(SUFFIX).azurecr.io
ACR_NAME	:= acr$(SUFFIX)
APP_NAME 	:= simpleweb
IMAGE_NAME	:= $(KO_DOCKER_REPO)/$(APP_NAME)

.PHONY: help build-image acr-login

help: ## show help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-8s\033[0m\t\t %s\n", $$1, $$2}'

build-image: ## build image
	cd src && KO_DOCKER_REPO=$(KO_DOCKER_REPO) ko build -B -t latest -t $(TAG) 

acr-login: ## login to acr
	az acr login --name $(ACR_NAME)

rg: ## create resource group
	az group create --name $(RG) --location $(LOCATION)

env: ## deploy container app env and acr
	az deployment group create --resource-group $(RG) --template-file ./bicep/env.bicep \
	--parameters suffix=$(SUFFIX)

deploy: ## deploy container apps 
	az deployment group create --resource-group $(RG) --template-file ./bicep/deploy.bicep \
	--parameters suffix=$(SUFFIX) imageName=$(APP_NAME):$(TAG)