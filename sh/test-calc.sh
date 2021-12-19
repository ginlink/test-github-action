#!/bin/sh

echo 'starting---------'
echo $RELEASE_VERSION
echo '$RELEASE_VERSION'

# tag_version=$RELEASE_VERSION

# echo 'slice version'
# echo $tag_version
# echo ${tag_version: 1}

abc="123456"
echo ${abc: 1}

tmp_version=$RELEASE_VERSION
echo ${tmp_version: 1}
echo 'ending-----------'