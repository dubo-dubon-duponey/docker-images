#!/usr/bin/env bash
set -o errexit -o errtrace -o functrace -o nounset -o pipefail

dock="$1"
readonly magic="docker.io/dubodubonduponey"

echo "Starting processing of dockerfile $dock"

images="$(cat "$dock" | grep -Ev "^#" | gsed ':a;N;$!ba;s/\\\n/ /g' | grep -E "FROM_IMAGE_[^=]+=([^@]+)@(.+)" | sed -E 's/[^=]+=([^@]+)@(.+)/\1 \2/g' || true)"

[ "$images" ] || {
  >&2 echo "No images found in this dockerfile. Exiting."
  exit
}

while read -r image; do
  name="${image%% *}"
  digest="${image##* }"
  available="$(docker buildx imagetools inspect "$magic/$name" | grep -E "^Digest")"
  available="${available##* }"
  if [ "$digest" != "$available" ]; then
    echo "Trailing behind: $name - has: $digest <- could have: $available"
  fi
done <<<"$images"
