function system.group() {
  _group_name=$1; shift

  __babashka_log "system.group $_group_name"
  while getopts "g:" opt; do
    case "$opt" in
      # echoing through xargs trims whitespace
      g)
        gid=$(echo $OPTARG | xargs);;
    esac
  done
  # Reset the option parsing
  unset OPTIND
  unset OPTARG
  function is_met() {
    if ! getent group $_group_name; then
      return 1
    fi
    if [[ $gid != "" ]]; then
      current_gid=$(getent group ${_group_name} | awk -F ':' '{print $3}')
      if [[ $current_gid != $gid ]]; then
        return 1
      fi
    fi
  }
  function meet() {
    if getent group $_group_name; then
      $__babashka_sudo groupmod -g $gid $_group_name
    else
      $__babashka_sudo addgroup $_group_name ${gid:+-g $gid}
    fi
  }
  process
}

function system.user() {

  _user_name=$1; shift
  # g: gid or group name
  # u: uid
  # s: system
  # h: homedir
  # l: shell
  # TODO: Use `getopt` instead to allow more betterer parsing?
  #       Though getopt is often confusing
  #       oh well
  while getopts "g:u:l:h:s" opt; do
    case "$opt" in
      g)
        gid=$(echo $OPTARG | xargs);;
      u)
        uid=$(echo $OPTARG | xargs);;
      h)
        homedir=$(echo $OPTARG | xargs);;
      l)
        shell=$(echo $OPTARG | xargs);;
      s)
        is_system=true
    esac
  done
  # Reset the option parsing
  unset OPTIND
  unset OPTARG
  __babashka_log "system.user $_user_name"
  if [[ is_system == true ]]; then
    unset $homedir
  fi
  function is_met() {
    # User exists?
    getent passwd ${_user_name} || return 1
    # Group ID is correct?
    if [[ $gid != "" ]]; then
      case $gid in
        *[!0-9]*)
          # Is a string, so we need to check if the group even exists
          # And if it doesn't, that's, well, bad? Yes, that's bad.
          _gid=$(getent group $gid | awk -F ':' '{print $3}')
          ;;
        *)
          # is a number
          # We can pass it on directly
          _gid=$gid
          ;;
      esac
      [[ $(getent passwd ${_user_name} | awk -F ':' '{print $4}') == $_gid ]] || return 1
    fi

    if [[ $uid != "" ]]; then
      [[ $(getent passwd ${_user_name} | awk -F ':' '{print $3}') == $uid ]] || return 1
    fi
    if [[ $shell != "" ]]; then
      [[ $(getent passwd ${_user_name} | awk -F ':' '{print $7}') == $shell ]] || return 1
    fi
    if [[ $homedir != "" ]]; then
      [[ $(getent passwd ${_user_name} | awk -F ':' '{print $6}') == $homedir ]] || return 1
    fi
    # TODO
    # Implement -s, since I'm not sure what that should do
  }
  function meet() {
    case $gid in
      *[!0-9]*)
        # Is a string, so we need to check if the group even exists
        # And if it doesn't, that's, well, bad? Yes, that's bad.
        _gid=$(getent group $gid | awk -F ':' '{print $3}')
        ;;
      *)
        # is a number
        # We can pass it on directly
        _gid=$gid
        ;;
    esac
    if getent passwd ${_user_name} ; then
      # User already exists, so we're modifying the user
      $__babashka_sudo usermod \
        ${_gid:+-g $_gid} \
        ${uid:+-u $uid} \
        ${shell:+-s $shell} \
        ${homedir:+-d $homedir} \
        ${_user_name}
    else
      # User doesn't exist, create it
      $__babashka_sudo useradd \
        ${_gid:+-g $_gid} \
        ${uid:+-u $uid} \
        ${homedir:+-d $homedir -m} \
        ${shell:+-s $shell} \
        ${_user_name}
    fi
  }
  process
}

