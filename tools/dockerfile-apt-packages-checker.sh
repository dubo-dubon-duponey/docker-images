#!/usr/bin/env bash
set -o errexit -o errtrace -o functrace -o nounset -o pipefail

SUITE=bookworm
# bullseye
DATE="${DATE:-2024-02-20}"
dock="$1"

echo "Starting processing of dockerfile $dock"

#packages="$(cat "$dock" | grep -Ev "^#" | gsed ':a;N;$!ba;s/\\\n/ /g' | grep -E "apt-get install ([-][^ ]+[ ]+)*([^-.;&][^;&]+)" | sed -E 's/.*apt-get install ([-][^ ]+[ ]+)*([^-.;&][^;&]+).*/\2/g' || true)"
#echo "got packages:"

packages="$(cat "$dock" | grep -Ev "^#" | gsed ':a;N;$!ba;s/\\\n/ /g' | grep -E "apt-get install ([-][^ ]+[ ]+)*([^-.;&][^;&]+)" | sed -E 's/apt-get install ([-][^ ]+[ ]+)*/\napt-get install /g' | grep -E "apt-get install " \
  | sed -E 's/^apt-get install ([^-.;&][^;&]+).*/\1/g' | gsed -z 's/\n/ /g' || true)"

[ "$packages" ] || {
  >&2 echo "No packages found in this dockerfile. Exiting."
  exit
}

>&2 echo "Found packages $packages"

names=()
available=()

#  --add-host snapshot.debian.org:10.0.4.101
docker inspect "dubo-analyze-$SUITE-$DATE" 1>/dev/null 2>&1 || {
	docker run --rm --name "dubo-analyze-$SUITE-$DATE" -d -ti \
    docker.io/dubodubonduponey/debian:$SUITE-$DATE bash
#	docker run --rm --name "dubo-analyze-$SUITE-$DATE" -d -ti \
#	  --add-host snapshot.debian.org:10.0.4.101 \
#    docker.io/dubodubonduponey/debian:$SUITE-$DATE bash
	docker exec "dubo-analyze-$SUITE-$DATE" dpkg --add-architecture amd64
	docker exec "dubo-analyze-$SUITE-$DATE" apt-get update -o "Acquire::Check-Valid-Until=no"
}

for i in $packages; do
	name=${i%%=*}
	version=${i##*=}
	[ "$version" != "$name" ] || version=""
	name=${name%%:*}
	originalname="$name"
	originalversion="$version"
	# Turn parameterized platform into dummy amd64
	name="$(printf "%s" "$name" | sed -E 's/(["]?[$][a-zA-Z_]+["]?)/amd64/')"
	version="$(printf "%s" "$version" | sed -E 's/(["]?[$][a-zA-Z_]+["]?)/amd64/')"

#	newversion="$(docker exec "dubo-analyze-$SUITE-$DATE" apt-cache show "$name" | grep "Version:")" || {
	newversion="$(docker exec "dubo-analyze-$SUITE-$DATE" apt show "$name" 2>/dev/null | grep "Version:")" || {
		tput setaf 2
		echo "Ignoring dramatic failure on package $name version $version"
		tput op
	  continue
	}
	newversion="${newversion##*: }"
	if [ "$version" == "$newversion" ]; then
		tput setaf 4
		echo "$name=$version"
		tput op
	elif [ ! "$version" ]; then
		tput setaf 3
		echo "$name=$newversion (< was $originalname without any version)"
		tput op
	else
		tput setaf 1
		echo "$name=$newversion (< was $originalname=$originalversion)"
		tput op
	fi
done
