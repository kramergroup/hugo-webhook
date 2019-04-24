# Hugo Webhook

This container provides a webhook that triggers a Hugo rebuild of a given git repository.

The container is meant to operate as a webhook consumer to trigger a rebuild of a [Hugo](https://http://gohugo.io) static website.
This can be used to autmatically refresh a static website after a git commit. A refresh is always triggered when the container is
started.

The container exposed a webhook listener on port 9000. A refresh of the site can be triggered with:

```bash
curl http://localhost:9000/hooks/refresh
```



The *target directory* should be mounted by a static
webserver (such as nginx) and served. See the Kubernetes deployment example for a fully working deployment.

## Configuration

The container is configured through environment variables and some configuration files. The Hugo version is 0.55.3.

### Environment variables

| Name                    | Description                                                                                        |
| ----------------------- | -------------------------------------------------------------------------------------------------- |
| `GIT_REPO_URL`          | The URL of the git repository                                                                      |
| `GIT_REPO_CONTENT_PATH` | The subpath of the repository holding the hugo source files (e.g., where `config.toml` is located) |
| `GIT_REPO_BRANCH`       | The branch of the git repository                                                                   |
| `HUGO_PARAMS`           | Additional HUGO parameter (e.g., `--minify`)                                                       |

### Volumes and configuration files

| Name              | Description                                                                                          |
| ----------------- | ---------------------------------------------------------------------------------------------------- |
| `/target`         | The location of the rendered HTML site                                                               |
| `/etc/hooks.json` | The [webhook](https://github.com/adnanh/webhook) configuration file                                  |
| `/ssh/id_rsa`     | The private key used to communicate with the git repository (needs to have at least 400 permissions) |

# Deployment examples

## Docker

```bash
docker run --rm -it -p 9000:9000 -v <MY_SSH_PRIVATE_KEY>:/ssh/id_rsa \
           -e GIT_REPO_URL=<THE_GIT_REPO_URL> /
           -e GIT_REPO_CONTENT_PATH=<A_SUBPATH_IN_REPO> kramergroup/hugo
```

## Kubernetes

