#!/bin/bash

if [ $# -lt 2 ]; then
    type="master"
    branch="master"
    ref="trunk"
else
    case "$1" in
        branch)
            type="branch"
            branch="$2"
            ref="branches/$2"
            ;;
        tag)
            type="tag"
            branch="tag-$2"
            ref="tags/$2"
            ;;
        *)
            echo "Invalid type"
            exit 1
            ;;
    esac
fi

if [ -d /tmp/wp ]; then
    rm -rf /tmp/wp
fi

revision=$(svn info "https://develop.svn.wordpress.org/$ref/" | grep 'Last Changed Rev' | sed 's/Last Changed Rev: //')
svn export --ignore-externals "https://develop.svn.wordpress.org/$ref/" /tmp/wp/

pushd /tmp/wp/

npm set progress=false && \
    npm install && \
    grunt

if [ $? -ne 0 ]; then
    echo "Error installing npm or running grunt!"
    exit 3
fi

git clone "https://$GITHUB_AUTH_USER:$GITHUB_AUTH_PW@github.com/johnpbloch/wordpress-core.git" /tmp/wp-git

pushd /tmp/wp-git

if [[ `git branch -a | grep "remotes/origin/$branch"` ]]; then
    git checkout -b "$branch" "origin/$branch"
else
    git checkout clean
    git checkout -b $branch
fi

rm -r $(ls -1A | grep -vP '^\.git')

mv /tmp/wp/build/* .

cp /var/composer.json .

git add -A .

git commit -m "Update from $ref\n\nSVN r$revision"

case $type in
    tag)
        tag="$2"
        if [[ `echo -n "$tag" | grep -P '^\s*\d+\.\d+\s*$'` ]]; then
            tag="$tag.0"
        fi
        git tag "$tag"
        git rm composer.json
        git commit -m "Hide tag branch from packagist"
        ;;
    master)
        tag=$(php -r 'include "wp-includes/version.php"; echo "$wp_version\n";')
        if [[ ! `git tag | grep -P "^$tag$"` ]]; then
            git tag "$tag"
        fi
        ;;
esac

git push --tags origin "$branch"