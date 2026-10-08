# martin-server

Our custom martin deployment

## Docker

The deployment and execution of this is docker based. So if you don't want
to install ruff and uv in your system, go the docker route.

# makefile

You can pretty much do all you need using the Makefile, which operates
on **docker**.

# deploy

The deploy command will deploy this to GCP. You can manually deploy from
your local environment with:

* `make deploy ENV=<target_env>` where `target_env` can be dev, staging or production. The default is dev.

Github actions handles the deployment as well as follows:

### merged to main -> deploys to DEV
### created a prerelease -> deploys to STAGING
### created a release/promote prerelease to latest -> deploys to PRODUCTION

# cicd

Everything is running from github actions. Install ruff locally and configure
your editor to work with ruff.

# infrastructure

Check the infrastructure repo. It's all done with terraform.