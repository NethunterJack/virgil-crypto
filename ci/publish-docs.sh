#!/bin/bash
#
# Copyright (C) 2015-2016 Virgil Security Inc.
#
# Lead Maintainer: Virgil Security Inc. <support@virgilsecurity.com>
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     (1) Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#
#     (2) Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in
#     the documentation and/or other materials provided with the
#     distribution.
#
#     (3) Neither the name of the copyright holder nor the names of its
#     contributors may be used to endorse or promote products derived from
#     this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ''AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#

set -ev

if [[ "${PUBLISH_DOCS}" == "ON" ]] && [[ "${TRAVIS_BRANCH}" == "master" ]]; then
    # Settings
    REPO_PATH=git@github.com:VirgilSecurity/virgil-crypto.git
    HTML_PATH_DST="${PROJECT_ROOT}/build/docs/html"
    COMMIT_USER="Travis CI documentation builder."
    COMMIT_EMAIL="sergey.seroshtan@gmail.com"
    CHANGESET=$(git rev-parse --verify HEAD)

    # Get a clean version of the HTML documentation repo.
    rm -rf ${HTML_PATH_DST}
    mkdir -p ${HTML_PATH_DST}
    git clone -b gh-pages "${REPO_PATH}" --single-branch ${HTML_PATH_DST}

    # Define SDK versions
    VIRGIL_CRYPTO_VERSION=`cat ${PROJECT_ROOT}/VERSION | awk -F"." '{ printf "v%d.%d",$1,$2 }'`
    VIRGIL_CRYPTO_HTML_PATH_DST="${HTML_PATH_DST}/${VIRGIL_CRYPTO_VERSION}"

    # Prepare destination folders
    rm -fr "${VIRGIL_CRYPTO_HTML_PATH_DST}" && mkdir -p "${VIRGIL_CRYPTO_HTML_PATH_DST}"

    # Generate the HTML documentation.
    cmake --build "${PROJECT_ROOT}/build" --target doc

    # Copy new documentation
    cp -af "${PROJECT_ROOT}/docs/html/." "${VIRGIL_CRYPTO_HTML_PATH_DST}"

    # Fix source file names
    function fix_html_source_file_names {
        cd "${1}"
        for f in _*.html; do
            old_name=$f
            new_name=${f/${f:0:1}/}
            mv $old_name $new_name
            if [ "$(uname -s)" == "Darwin" ]; then
                sed -i "" -e "s/[[:<:]]$old_name[[:>:]]/$new_name/g" *.html
            else
                sed -i"" "s/\b$old_name\b/$new_name/g" *.html
            fi
        done
        cd -
    }

    fix_html_source_file_names "${VIRGIL_CRYPTO_HTML_PATH_DST}"

    # Generate root HTML file
    function get_dir_names {
        local DIRS=`find "$1" -maxdepth 1 -type d -name "$2"`
        local DIR_NAMES=()
        for dir in ${DIRS}; do
            DIR_NAMES+=("${dir#${1}/}")
        done
        echo ${DIR_NAMES[*]}
    }

    cat >"${HTML_PATH_DST}/index.html" <<EOL
<!DOCTYPE HTML>
<html>
   <head>
        <meta charset="utf-8">
        <title>Virgil Security Crypto Lib</title>
   </head>
   <body>
        Virgil Security Crypto Lib
        <ul>
EOL

    for dir in `get_dir_names "${VIRGIL_CRYPTO_HTML_PATH_DST}/.." "v*"`; do
        echo "            <li><p><a href=\"${dir}/index.html\">${dir}</a></p></li>" >> "${HTML_PATH_DST}/index.html"
    done

    cat >>"${HTML_PATH_DST}/index.html" <<EOL
        </ul>
   </body>
</html>
EOL

    # Import credentials
    openssl aes-256-cbc -K $encrypted_f0ca52e75c0f_key -iv $encrypted_f0ca52e75c0f_iv \
        -in "${PROJECT_ROOT}/ci/publish-docs-rsa.enc" \
        -out "${PROJECT_ROOT}/ci/publish-docs-rsa" -d
    chmod 0600 "${PROJECT_ROOT}/ci/publish-docs-rsa"
    eval $(ssh-agent -s)
    ssh-add "${PROJECT_ROOT}/ci/publish-docs-rsa"

    # Create and commit the documentation repo.
    cd ${HTML_PATH_DST}
    git add .
    git config user.name "${COMMIT_USER}"
    git config user.email "${COMMIT_EMAIL}"
    git commit -m "Automated documentation build for changeset ${CHANGESET}."
    git push origin gh-pages
    cd -
fi
