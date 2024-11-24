**Binary tools**:
* [bin/ssh-gen](#binssh-gen)

## bin/ssh-gen

```file
Generate private and public key pair and configure ~/.ssh/config
file to use them. Script configuration via environment variables.

Environment variables (=DEFAULT_VALUE):
=====================
SSH_GEN_USER      - (='git') SSH user
SSH_GEN_HOSTNAME  - (='github.com') The actual SSH host. When '%h' (the
                    target hostname) used, must apply SSH_GEN_DEST_DIRNAME
SSH_GEN_PORT      - (='22') SSH port
SSH_GEN_HOST      - (='github.com') SSH host match pattern
SSH_GEN_COMMENT   - (=$(hostname -f)) Public key comment
SSH_GEN_DEST_DIRNAME  - (=SSH_GEN_HOSTNAME) Destination directory name
SSH_GEN_DEST_FILENAME - (=SSH_GEN_USER) Destination file name, defaults to

Demo:
====
# Generate with all defaults to PK file ~/.ssh/github.com/git
ssh-gen.sh

# Generate to ~/.ssh/_.serv.com/bar instead of ~/.ssh/10.0.0.69/foo
SSH_GEN_DEST_DIRNAME=_.serv.com SSH_GEN_DEST_FILENAME=bar \
SSH_GEN_USER=foo SSH_GEN_HOSTNAME=10.0.0.69 \
SSH_GEN_HOST='serv.com *.serv.com' \
SSH_GEN_COMMENT='I feel good' \
ssh-gen.sh
```
