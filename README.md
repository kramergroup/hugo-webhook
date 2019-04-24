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
docker run --rm -it -p 9000:9000 \
           -v $(pwd):/target \
           -v <MY_SSH_PRIVATE_KEY>:/ssh/id_rsa \
           -e GIT_REPO_URL=<THE_GIT_REPO_URL> \
           -e GIT_REPO_CONTENT_PATH=<A_SUBPATH_IN_REPO> kramergroup/hugo
```

This will run the container locally. A refresh can be triggered with 

```bash
curl http://localhost:9000/hooks/refresh
```


## Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hugo-site
spec:
  selector:
    matchLabels:
      app: hugo-site
  template:
    metadata:
      labels:
        app: hugo-site
    spec:
      volumes:
      - name: git-secret
        secret:
          secretName: git-credentials   # = a secret holding the id_rsa file for password-less pull
          defaultMode: 256              # = mode 0400
      - name: html
        emptyDir: {}
      containers:
      - name: webhook
        image: kramergroup/hugo-webhook:latest
        env:
        - name: GIT_REPO_URL
          value: <git clone url>
        - name: GIT_REPO_CONTENT_PATH
          value: docs
        ports:
        - containerPort: 9000
        volumeMounts:
        - name: html
          mountPath: /target
        - name: git-secret
          mountPath: /ssh
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
```

This configures a deployment in Kubernetes called *hugo-site*. It consists of a pod with two containers: (1) holding the webhook, and (2) an nginx server serving the static content. The web-server is exposed at port 80 and the webhook at port 9000. A service object should be configured to access these.

> Note that "git clone url" needs to be replaced with the git repository url.