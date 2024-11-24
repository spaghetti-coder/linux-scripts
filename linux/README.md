**Binary tools**:
* [bin/ssh-gen](#binssh-gen)

## bin/ssh-gen

<details>
  <summary>Man</summary>

  ```
  Generate private and public key pair and configure ~/.ssh/config
  file to use them. Script configuration via environment variables.

  Environment variables (=DEFAULT_VALUE):
  =====================
  SSH_GEN_USER      - (='git') SSH user
  SSH_GEN_HOSTNAME  - (='github.com') The actual SSH host. When aguments
                      like '%h' (the target hostname) used, must provide
                      explicitly SSH_GEN_HOST and SSH_GEN_DEST_DIRNAME
  SSH_GEN_PORT      - (='22') SSH port
  SSH_GEN_HOST      - (=SSH_GEN_HOSTNAME) SSH host match pattern
  SSH_GEN_COMMENT   - (=$(id -un)@$(hostname -f)) Certificate omment
  SSH_GEN_DEST_DIRNAME  - (=SSH_GEN_HOSTNAME) Destination directory name
  SSH_GEN_DEST_FILENAME - (=SSH_GEN_USER) Destination file name

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
</details>

<details>
  <summary>Ad hoc usage</summary>

  ```sh
  (
    export SSH_GEN_USER="dummy"
    export SSH_GEN_HOSTNAME="10.0.0.69"
    SSH_GEN_PORT="22" \
    SSH_GEN_HOST="${SSH_GEN_HOSTNAME}" \
    SSH_GEN_COMMENT="$(id -un)@$(hostname -f)" \
    SSH_GEN_DEST_DIRNAME="${SSH_GEN_HOSTNAME}" \
    SSH_GEN_DEST_FILENAME="${SSH_GEN_USER}" \
      bash <(
        curl -V &>/dev/null && tool=(curl -sL) || tool=(wget -qO-)
        "${tool[@]}" https://raw.githubusercontent.com/spaghetti-coder/linux-scripts/master/linux/bin/ssh-gen.sh
      )
  )
  ```
</details>
