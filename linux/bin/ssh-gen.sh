#!/usr/bin/env bash

declare -rA SSH_GEN_DEFAULTS=(
  [user]=git
  [hostname]=github.com
  [port]=22
)

SSH_GEN_USER="${SSH_GEN_USER:-${SSH_GEN_DEFAULTS[user]}}"
SSH_GEN_HOSTNAME="${SSH_GEN_HOSTNAME:-${SSH_GEN_DEFAULTS[hostname]}}"
SSH_GEN_PORT="${SSH_GEN_PORT:-${SSH_GEN_DEFAULTS[port]}}"
SSH_GEN_HOST="${SSH_GEN_HOST:-${SSH_GEN_HOSTNAME}}"
SSH_GEN_COMMENT="${SSH_GEN_COMMENT:-$(id -un)@$(hostname -f)}"
SSH_GEN_DEST_DIRNAME="${SSH_GEN_DEST_DIRNAME:-${SSH_GEN_HOSTNAME}}"
SSH_GEN_DEST_FILENAME="${SSH_GEN_DEST_FILENAME:-${SSH_GEN_USER}}"

declare -A SSH_GEN_RESULT=(
  [pk_created]=false
  [pub_created]=false
  [conffile_entry]=false
)

ssh_gen_trap_help() {
  declare -r \
    USER=foo \
    HOSTNAME=10.0.0.69 \
    CUSTOM_DIR=_.serv.com \
    CUSTOM_FILE=bar

  [[ "${1}" =~ ^(-\?|-h|--help)$ ]] || return

  declare THE_SCRIPT=ssh-gen.sh
  grep -q -m 1 -- '.' "${0}" 2>/dev/null && THE_SCRIPT="$(basename -- "${0}")"

  echo "
    Generate private and public key pair and configure ~/.ssh/config
    file to use them. Script configuration via environment variables.

    Environment variables (=DEFAULT_VALUE):
    =====================
    SSH_GEN_USER      - (='${SSH_GEN_DEFAULTS[user]}') SSH user
    SSH_GEN_HOSTNAME  - (='${SSH_GEN_DEFAULTS[hostname]}') The actual SSH host. When aguments
   ,                    like '%h' (the target hostname) used, must provide
   ,                    explicitly SSH_GEN_HOST and SSH_GEN_DEST_DIRNAME
    SSH_GEN_PORT      - (='${SSH_GEN_DEFAULTS[port]}') SSH port
    SSH_GEN_HOST      - (=SSH_GEN_HOSTNAME) SSH host match pattern
    SSH_GEN_COMMENT   - (=\$(id -un)@\$(hostname -f)) Certificate omment
    SSH_GEN_DEST_DIRNAME  - (=SSH_GEN_HOSTNAME) Destination directory name
    SSH_GEN_DEST_FILENAME - (=SSH_GEN_USER) Destination file name

    Demo:
    ====
    # Generate with all defaults to PK file ~/.ssh/${SSH_GEN_DEFAULTS[hostname]}/${SSH_GEN_DEFAULTS[user]}
    ${THE_SCRIPT}

    # Generate to ~/.ssh/${CUSTOM_DIR}/${CUSTOM_FILE} instead of ~/.ssh/${HOSTNAME}/${USER}
    SSH_GEN_DEST_DIRNAME=${CUSTOM_DIR} SSH_GEN_DEST_FILENAME=${CUSTOM_FILE} \\
    SSH_GEN_USER=${USER} SSH_GEN_HOSTNAME=${HOSTNAME} \\
    SSH_GEN_HOST='serv.com *.serv.com' \\
    SSH_GEN_COMMENT='I feel good' \\
   ,  ssh-gen.sh
  " | sed -e 's/^\s\+//;1{/^\s*$/d};${/^\s*$/d}' \
          -e 's/^,//'
}

ssh_gen_main() {
  declare -r PK_SUFFIX=".ssh/${SSH_GEN_DEST_DIRNAME}/${SSH_GEN_DEST_FILENAME}"
  declare -r KEY_CONFFILE_SUFFIX="${PK_SUFFIX}.config"

  ssh_gen_gen_key \
  && ssh_gen_manage_conffile \
  && ssh_gen_post_msg
}

ssh_gen_gen_key() {
  declare key_file="${HOME}/${PK_SUFFIX}"
  declare dest_dir; dest_dir="$(dirname -- "${key_file}")"

  (set -x; mkdir -p "${dest_dir}") || return

  if ! cat -- "${key_file}" &>/dev/null; then
    (set -x; ssh-keygen -q -N '' -b 4096 -t rsa -C "${SSH_GEN_COMMENT}" -f "${key_file}") || return
    SSH_GEN_RESULT[pk_created]=true
    SSH_GEN_RESULT[pub_created]=true
  fi

  if : \
    && ! ${SSH_GEN_RESULT[pk_created]} \
    && ! cat -- "${key_file}.pub" &>/dev/null \
  ; then
    (set -x; ssh-keygen -y -f "${key_file}" | tee -- "${key_file}.pub") || return
    SSH_GEN_RESULT[pub_created]=true
  fi
}

ssh_gen_manage_conffile() {
  declare ssh_conffile="${HOME}/.ssh/config"
  declare confline="Include ~/${KEY_CONFFILE_SUFFIX}"

  declare conf="
    # SSH host match pattern. Sample:
    #   myserv.com
    #   *.myserv.com myserv.com
    Host ${SSH_GEN_HOST}
      # The actual SSH host. Sample:
      #   10.0.0.69
      #   google.com
      #   %h # (referehce to matched Host)
      HostName ${SSH_GEN_HOSTNAME}
      Port ${SSH_GEN_PORT}
      User ${SSH_GEN_USER}
      IdentityFile ~/${PK_SUFFIX}
      IdentitiesOnly yes
  "

  printf -- '%s\n' "${conf}" \
    | grep -v '^\s*$' | sed -e 's/^\s\+//' -e '5,$s/^/  /' \
    | (set -x; tee -- "${HOME}/${KEY_CONFFILE_SUFFIX}" >/dev/null) \
  && {
    # Include in ~/.ssh/config
    grep -qFx -- "${confline}" "${ssh_conffile}" 2>/dev/null && return

    SSH_GEN_RESULT[conffile_entry]=true
    printf -- '%s\n' "${confline}" | (set -x; tee -a -- "${ssh_conffile}" >/dev/null)
  }
}

ssh_gen_post_msg() {
  echo >&2

  echo 'RESULT:' >&2

  if ${SSH_GEN_RESULT[pk_created]}; then
    echo "  * ~/${PK_SUFFIX} created." >&2
  else
    echo "  * ~/${PK_SUFFIX} existed." >&2
  fi

  if ${SSH_GEN_RESULT[pub_created]}; then
    echo "  * ~/${PK_SUFFIX}.pub created." >&2
  else
    echo "  * ~/${PK_SUFFIX}.pub existed." >&2
  fi

  if ${SSH_GEN_RESULT[conffile_entry]}; then
    echo "  * ~/.ssh/config entry added." >&2
  else
    echo "  * ~/.ssh/config entry existed." >&2
  fi

  echo "Add public key to your server:" >&2
  echo "  ssh-copy-id -i ~/${PK_SUFFIX}.pub -p ${SSH_GEN_PORT} ${SSH_GEN_USER}@${SSH_GEN_HOSTNAME}" >&2
  echo "Add public key to your git host account:" >&2
  printf -- '  %s\n' \
    "* https://github.com/settings/keys" \
    "* https://bitbucket.org/account/settings/ssh-keys/" >&2

  echo "THE RESULTING PUBLIC KEY:" >&2
  echo "========================" >&2
  cat -- "${HOME}/${PK_SUFFIX}.pub"
}

if (! return &>/dev/null); then
  ssh_gen_trap_help "${@}" && exit

  [[ ${#} -gt 0 ]] && {
    echo "Invalid options:" >&2
    printf -- '  %s\n' "${@}" >&2
    exit
  }

  ssh_gen_main
fi
