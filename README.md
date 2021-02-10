# Hugo Webhook

This container provides a webhook that triggers a Hugo rebuild of a given git repository.


Based on [kramergroup/hugo-webhook](https://github.com/kramergroup/hugo-webhook), this webhook
image lets you authenticate to github, gitea or gitlab using a web token. It was built as a 
base for jfardello/hugo-webhook-chart.
Some features:

* Web tokens: it is a lot easier to pass tokens as arguments to the chart than passing certificates.
* It doesn't make use of supervisord
* Smaller: it now uses the alpine docker image, webhook and hugo binaries have been compressed 
  with UPX and thus the image is pretty small. 
* It doesn't run as root.
* Can cache sources for faster pulling.

The container is meant to operate as a webhook consumer to trigger a rebuild of a 
[Hugo](https://http://gohugo.io) static website. This can be used to autmatically refresh a 
static website after a git commit. A refresh is always triggered when the container is
started.

The container exposed a webhook listener on port 9000. A refresh of the site can be triggered with:

```bash
curl http://localhost:9000/hooks/refresh
```



The *hugo target directory* should be mounted by a static webserver (such as nginx) and served.
See the Kubernetes deployment example for a fully working deployment.

## Configuration

The container is configured through environment variables and some configuration files. The Hugo 
version is 0.80.0.

### Environment variables

| Name                    | Description                                                                                        |
| ----------------------- | -------------------------------------------------------------------------------------------------- |
| `GIT_PROVIDER`          | Your git provider (GITHUB|GITEA|GITLAB), defaults to GITHUB, only used if TRANSPORT is HTTP.       |
| `GIT_TRANSPORT`         | Whether to use SSH or HTTP git transport, defaults to HTTP.                                        |
| `GIT_TOKEN`             | A gitlab, geta, or github token for authorizing th git pull over http.                             |
| `GIT_USERNAME`          | When using webtockens and GITEA, the tokens' owner username.                                       |
| `GIT_HTTP_INSECURE`     | Force clear http as trasnport. (A nasty thing, you know what you're doing).                                       |
| `GIT_REPO_URL`          | The URL of the git repository.                                                                     |
| `GIT_REPO_CONTENT_PATH` | The subpath of the repository holding the hugo source files (e.g., where `config.toml` is located).|
| `GIT_REPO_BRANCH`       | The branch of the git repository.                                                                  |
| `GIT_CLONE_DEST`        | Where to clone the repo to, defaults to /srv/src                                                   |
| `GIT_PRESERVE_SRC`      | Whether to preserve(cache) the src upon build or not. "TRUE" or "FALSE", default to FALSE          |
| `HUGO_TARGET_DIR`       | Where to save hugo's built html, defaults to /srv/static                                           |
| `HUGO_PARAMS`           | Additional HUGO parameter (e.g., `--minify`).                                                      |

### Volumes and configuration files

| Name              | Description                                                                                                   |
| ----------------- | --------------------------------------------------------------------------------------------------------------|
| `/srv/static`     | The default location of the rendered HTML site.                                                               |
| `/etc/hooks.json` | The [webhook](https://github.com/adnanh/webhook) configuration file.                                          |
| `/ssh/id_rsa`     | The private key used to communicate with the git repository over SSH (needs to have at least 400 permissions).|

# Deployment examples

## Docker

```bash

docker  run --rm -it \
            -e GIT_TOKEN=<a github,gitea or gitlab token> \
            -e GIT_REPO_URL=<githubrepo url>  \
            -p9000:9000 -v ./html:/srv:Z quay.io/jfardello/hugo-webhook
```
*NOTE*: 
  git repository url *should not* have the schema, ex: github.com/user/repo.git

This will run the container locally. A refresh can be triggered with 

```bash
curl http://localhost:9000/hooks/refresh
```


## Kubernetes

Use this helm chart:

```
$ helm repo add jfardello https://jfardello.github.io/helm-charts/
$ helm install jfardello/hugo-webhook --set -e GIT_TOKEN=xxxxxredactedyyyyyyyzzzzzz \
  --set GIT_REPO_URL=github.com/username/hugo-site.git
```

See [jfardello/hugo-webhook-chart](https://github.com/jfardello/hugo-webhook-chart). 