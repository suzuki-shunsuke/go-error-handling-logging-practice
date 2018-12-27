# Usage
#   bash scripts/tag.sh v0.3.2

if [ $# -gt 1 ]; then
  echo "too many arguments" > /dev/stderr
  echo 'Usage tag.sh $TAG' > /dev/stderr
  exit 1
fi

if [ $# -lt 1 ]; then
  echo "TAG argument is required" > /dev/stderr
  echo 'Usage tag.sh $TAG' > /dev/stderr
  exit 1
fi

TAG=$1
echo "TAG: $TAG"
VERSION=${TAG#v}

if [ "$TAG" = "$VERSION" ]; then
  echo "TAG must start with 'v'"
  exit 1
fi

echo "cd `dirname $0`/.."
cd `dirname $0`/..

echo "update the README's version string"
gsed -i "s/\*\*v.*\*\*/**$TAG**/" README.md
git add README.md || exit 1
git commit -m "build: update version to $TAG" || exit 1
echo "git tag $TAG"
git tag $TAG
