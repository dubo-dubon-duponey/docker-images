#!/usr/bin/env bash
set -o errexit -o errtrace -o functrace -o nounset -o pipefail

#############################################################
# Version detectors
#############################################################
version::latest::patch(){
  local urlfunction="$1"
  local base_version="$2"
  local repo="$3"

  local major=${base_version%%.*}
  local rest=${base_version#*.}
  local minor=${rest%%.*}
  local patch=0
  # Handle short and long versions (X.Y vs. X.Y.Z)
  if [ "$rest" != "$minor" ]; then
    patch=${rest#*.}
  fi

  local candidate_patch="$patch"
  local next_patch

  next_patch=$((patch + 1))
  #echo >&2 curl --proto '=https' --tlsv1.2 -L -I -o /dev/null -v "$("$urlfunction" "$repo" "$major" "$minor" "$next_patch")"
  while curl --proto '=https' --tlsv1.2 -L -I -o /dev/null -v "$("$urlfunction" "$repo" "$major" "$minor" "$next_patch")" 2>&1 | grep -qE "HTTP/[0-9. ]+ 200"; do
  #while [ "$(curl --proto '=https' --tlsv1.2 -L -I -o /dev/null -v "$("$urlfunction" "$platform" "$major" "$minor" "$next_patch")" 2>&1 | grep -E "HTTP/[0-9.]+ [0-9]{3}" | tail -1 | sed -E 's/.* ([0-9]{3}).*/\1/')" != "404" ]; do
    candidate_patch="$next_patch"
    next_patch=$((next_patch + 1))
    # echo >&2 curl --proto '=https' --tlsv1.2 -L -I -o /dev/null -v "$("$urlfunction" "$repo" "$major" "$minor" "$next_patch")"
    # curl --proto '=https' --tlsv1.2 -L -I -o /dev/null -v "$("$urlfunction" "$repo" "$major" "$minor" "$next_patch")" 2>&1 | grep -E "HTTP/[0-9.]+" 1>&2
    sleep 1
  done

  printf "%s.%s.%s" "$major" "$minor" "$candidate_patch"
  if [ "$candidate_patch" != "$patch" ];then
    return 1
  fi
}

version::latest::minor(){
  local urlfunction="$1"
  local base_version="$2"
  local repo="$3"

  local major=${base_version%%.*}
  local rest=${base_version#*.}
  local minor=${rest%%.*}
  local patch=0

  local candidate_minor=${minor}
  local next_minor

  next_minor=$((minor + 1))

  #echo >&2 curl --proto '=https' --tlsv1.2 -L -I -o /dev/null -v "$("$urlfunction" "$repo" "$major" "$next_minor" "$patch")"
  while curl --proto '=https' --tlsv1.2 -L -I -o /dev/null -v "$("$urlfunction" "$repo" "$major" "$next_minor" "$patch")" 2>&1 | grep -qE "HTTP/[0-9. ]+ 200"; do
#  while [ "$(curl --proto '=https' --tlsv1.2 -L -I -o /dev/null -v "$("$urlfunction" "$repo" "$major" "$next_minor" "$patch")" 2>&1 | grep -E "HTTP/[0-9.]+ [0-9]{3}" | tail -1 | sed -E 's/.* ([0-9]{3}).*/\1/')" != "404" ]; do
    candidate_minor=${next_minor}
    next_minor=$((next_minor + 1))
    #echo >&2 curl --proto '=https' --tlsv1.2 -L -I -o /dev/null -v "$("$urlfunction" "$repo" "$major" "$next_minor" "$patch")"
    #curl --proto '=https' --tlsv1.2 -L -I -o /dev/null -v "$("$urlfunction" "$repo" "$major" "$next_minor" "$patch")" 2>&1 | grep -E "HTTP/[0-9.]" 1>&2
    sleep 1
  done

  if [ "$candidate_minor" != "$minor" ];then
    printf "%s.%s.0" "$major" "$candidate_minor"
    return 1
  fi
  printf "%s" "$base_version"
}

version::latest::major(){
  local urlfunction="$1"
  local base_version="$2"
  local repo="$3"

  local major=${base_version%%.*}
  local minor=0
  local patch=0

  local candidate_major=${major}
  local next_major

  next_major=$((major + 1))
  #echo >&2 curl --proto '=https' --tlsv1.2 -L -I -o /dev/null -v "$("$urlfunction" "$repo" "$next_major" "$minor" "$patch")"
  while curl --proto '=https' --tlsv1.2 -L -I -o /dev/null -v "$("$urlfunction" "$repo" "$next_major" "$minor" "$patch")" 2>&1 | grep -qE "HTTP/[0-9. ]+ 200"; do
    candidate_major=${next_major}
    next_major=$((next_major + 1))
    # echo >&2 curl --proto '=https' --tlsv1.2 -L -I -o /dev/null -v "$("$urlfunction" "$repo" "$next_major" "$minor" "$patch")"
    #curl --proto '=https' --tlsv1.2 -L -I -o /dev/null -v "$("$urlfunction" "$repo" "$next_major" "$minor" "$patch")" 2>&1 | grep -E "HTTP/[0-9.]+" 1>&2
    sleep 1
  done
  if [ "$candidate_major" != "$major" ];then
    printf "%s.0.0" "$candidate_major"
    return 1
  fi
  printf "%s" "$base_version"
}

url::git(){
  local repo="$1"
  local version="v$2"
  [ "${3:-}" == "" ] || version="$version.$3.$4"
  printf "https://%s/tree/%s" "$repo" "$version"
}

url::git_no_v(){
  local repo="$1"
  local version="$2"
  [ "${3:-}" == "" ] || version="$version.$3.$4"
  printf "https://%s/tree/%s" "$repo" "$version"
}

dock="$1"
packages="$(cat "$dock" | grep -Ev "^#" | gsed ':a;N;$!ba;s/\\\n/ /g' | grep "ARG           GIT_" | sed -E 's/.+GIT_(.*)/\1/g')" || {
  >&2 printf "Nothing in this dockerfile... Move along\n"
  exit
}

repo=
version=
commit=
while read -r line; do
  if [ "${line:0:4}" == "COMM" ]; then
    commit=${line##*=}
    checker=url::git_no_v
    >&2 printf "Checking %s %s %s\n" "$repo" "$version" "$commit"
    # XXX Ideally would work with v1.2.3-rFOO and others - harder to increment though
    if printf "%s" "$version" | grep -qE "v?[0-9]+[.][0-9]+([.][0-9]+)?$"; then
      [ "${version:0:1}" != "v" ] || {
        version=${version:1}
        checker=url::git
      }
      newversion=$(version::latest::major "$checker" "$version" "$repo") || true
      newversion=$(version::latest::minor "$checker" "$newversion" "$repo") || true
      newversion=$(version::latest::patch "$checker" "$newversion" "$repo") || true
      if [ "$newversion" == "$version" ]; then
        tput setaf 4
        echo "$repo is fine with $version and $commit"
      else
        tput setaf 1
        echo "GIT_REPO=$repo"
        echo "GIT_VERSION=$version"
        echo "GIT_COMMIT=$commit"
        tput op
        tput setaf 2
        newcommit="$(curl --proto '=https' --tlsv1.2 -sSfL "$("$checker" "$repo" "$newversion" | sed "s/tree/commits/")" | grep "?after=" | sed -E "s/.+([0-9a-f]{40}).+/\1/")"
        echo "GIT_REPO=$repo"
        # XXX do not swallow up a possibly v that was there - generally should be smarter and just allow any syntax and find out which it is from github
        [ "$checker" == "url::git" ] && {
          echo "GIT_VERSION=v$newversion"
        } || {
          echo "GIT_VERSION=$newversion"
        }
        echo "GIT_COMMIT=$newcommit"
      fi
      }
    else
      newcommit="$(curl --proto '=https' --tlsv1.2 -sSfL "https://$repo"  | grep "commit\/" | grep fragment | sed -E "s/.+([0-9a-f]{40}).+/\1/")" || {
        tput setaf 1
        >&2 printf "Something very wrong here. Ignoring.\n"
        tput op
        continue
      }
      if [ "$newcommit" == "$commit" ]; then
        tput setaf 4
        echo "$repo is fine with $version and $commit"
      else
        tput setaf 1
        echo "GIT_REPO=$repo"
        echo "GIT_VERSION=$version"
        echo "GIT_COMMIT=$commit"
        tput op
        tput setaf 2
        echo "GIT_REPO=$repo"
        echo "GIT_VERSION=${newcommit:0:7}"
        echo "GIT_COMMIT=$newcommit"
      fi
    fi
    tput op

    repo=
    version=
    commit=
  fi
  if [ "${line:0:4}" == "VERS" ]; then
    version=${line##*=}
  fi
  if [ "${line:0:4}" == "REPO" ]; then
    repo=${line##*=}
  fi
done <<<"$packages"

