#/usr/bin/env bash

gen_secret() {
  while [[ ${#rand} -lt 16 ]];
  do
    local rand="${rand}$(printf '%x\n' ${RANDOM})";
  done;
  if [[ "${#rand}" -ge "16" ]]; then
    echo "${rand:0:16}";
    return 0;
  else
    return 1;
  fi;
}

rm_secret() {
  local secret_name="${1}";
  if [[ "$(docker secret inspect $secret_name 2>&1 >/dev/null; echo $?)" == "0" ]]; then
    echo "[INFO] Attempting to remove secret: $secret_name";
    docker secret rm "${secret_name}" 2>&1 >/dev/null;
    rm "${secret_name}.docker_secret.txt";
    if [[ "$(docker secret inspect $secret_name 2>&1 >/dev/null; echo $?)" != "0" ]]; then
      echo "[INFO] Successfully removed secret: ${secret_name}";
      return 0;
    else
      echo "[FAIL] Failed to remove secret: ${secret_name}" >&2;
      return 1;
    fi
  else
    echo "[WARN] Secret ($secret_name) already removed!";
    return 0;
  fi;
}

add_secret() {
    local secret_name="${1}";
    local secret="${2}";
    if [[ "$(docker secret inspect $secret_name 2>&1 >/dev/null; echo $?)" != "0" ]]; then
      echo "[INFO] Attempting to create secret: ${secret_name}";
      docker secret create $secret_name - <<<"${secret}" 2>&1 >/dev/null
      if [[ "$(docker secret inspect $secret_name 2>&1 >/dev/null; echo $?)" == "0" ]]; then
        echo "[INFO] Successfully created secret: ${secret_name}";
	echo "${secret_name}=${secret}" > ${secret_name}.docker_secret.txt;
	echo "[INFO] Secret value recorded in ${PWD}/${secret_name}.docker_secret.txt";
	return 0;
      else
        echo "[FAIL] Failed to create secret: $secret_name" >&2;
        return 1;
      fi;
    else
      echo "[WARN] Secret (${secret_name}) already exists!";
      return 0;
    fi;
}

main() {
  if ! [ -x "$(command -v docker)" ]; then
    echo "[FAIL] Unable to find docker command, please install Docker (https://www.docker.com/) and retry!" >&2;
    exit 1;
  fi
  
  if [[ "${#}" != "2" ]]; then
    echo "[FAIL] Specify either 'rm' or 'add' followed by secret_name!" >&2;
    exit 1;
  else
    secret_name="${2//[^a-z-A-Z0-9_]}";
    if [[ "${2}" != "${secret_name}" ]]; then
      echo "[FAIL] Requested secret name contains invalid characters!";
      exit 1;
    fi;
  fi;
  
  case "${1}" in
    add)
      secret="$(gen_secret)";
      add_secret "${secret_name}" "${secret}" || exit 1;
      ;;
    rm)
      rm_secret "${secret_name}" || exit 1;
      ;;
    *)
      echo "[FAIL] Invalid subcommand passed!" >&2
      exit 1;
      ;;    
  esac;
}

main ${@};

