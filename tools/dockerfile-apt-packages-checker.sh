#!/usr/bin/env bash
set -o errexit -o errtrace -o functrace -o nounset -o pipefail

SUITE=bullseye
DATE=2021-07-01
dock="$1"

echo "Starting processing of dockerfile $dock"

packages="$(cat "$dock" | grep -Ev "^#" | gsed ':a;N;$!ba;s/\\\n/ /g' | grep -E "apt-get install ([-][^ ]+[ ]+)*([^-.;&][^;&]+)" | sed -E 's/.*apt-get install ([-][^ ]+[ ]+)*([^-.;&][^;&]+).*/\2/g' || true)"

[ "$packages" ] || {
  >&2 echo "No packages found in this dockerfile. Exiting."
  exit
}

>&2 echo "Found packages $packages"

names=()
available=()

docker inspect dubo-analyze 1>/dev/null 2>&1 || {
	docker run --rm --name "dubo-analyze" -d -ti ghcr.io/dubo-dubon-duponey/debian:$SUITE-$DATE bash
	docker exec dubo-analyze apt-get update -o "Acquire::Check-Valid-Until=no"
}

for i in $packages; do
  echo "Reading $i"
	name=${i%%=*}
	version=${i##*=}
	[ "$version" != "$name" ] || version=""
	name=${name%%:*}
	if printf "%s" "$version" | grep -Eq "[$]" || printf "%s" "$name" | grep -Eq "[$]"; then
		tput setaf 2
		echo "Ignoring (likely dynamic) package $name version $version"
		tput op
		continue
  fi
	newversion="$(docker exec dubo-analyze apt-cache show "$name" | grep "Version:")" || {
		tput setaf 2
		echo "Ignoring dramatic failure on package $name version $version"
		tput op
	  continue
	}
	newversion="${newversion##*: }"
	if [ "$version" == "$newversion" ]; then
		tput setaf 4
		echo "$name is OK"
		tput op
	else
		tput setaf 1
		echo "$name=$newversion"
		tput op
	fi
done
