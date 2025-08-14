#!/usr/bin/env bash

# Exit on error
set -e

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	SED_COMMAND="sed"
elif [[ "$OSTYPE" == "darwin"* ]]; then
	SED_COMMAND="gsed"
else
	echo "Sorry, this script hasn't been tested on your OS platform"
	exit 1
fi

CP_VERSION="$1"

for gh_repo in ClassicPress/ClassicPress; do
	user="$(echo "$gh_repo" | cut -d/ -f1)"
	repo="$(echo "$gh_repo" | cut -d/ -f2)"
	if ! [ -d "$repo/.git" ]; then
		git clone --depth 1 "https://github.com/$user/$repo" "$repo"
	fi
done

pushd ClassicPress/

	# Reset everything
	rm -rf build/
	git reset --hard
	git fetch origin
	git checkout origin/develop -B develop
	rm -rf node_modules/

	# Set up node version
	set +x
	echo 'loading nvm and node'
	. ~/.nvm/nvm.sh --no-use
	nvm use || nvm install
	set -x

	# Install dependencies and generate a nightly build
	npm install
	./node_modules/.bin/grunt build

	# Get version numbers for substitution later
	WP_VERSION=$(grep '$wp_version =' build/wp-includes/version.php | head -n 1 | grep -Eo -m1 '[[:digit:]]+\.[[:digit:]]+\.?[[:digit:]]*')
	if [ -z "$CP_VERSION" ]; then
		CP_VERSION=$(grep '$cp_version =' build/wp-includes/version.php | head -n 1 | grep -Eo -m1 '[[:digit:]]+\.[[:digit:]]+\.?[[:digit:]]*')
	fi
popd

# Clean up POT files first
rm *.pot || true

# Create the POT files
wp i18n make-pot ./ClassicPress/build ./en_US.pot --ignore-domain --skip-audit --exclude="wp-content,wp-admin,wp-includes/class-wp-network*.php,wp-includes/ms-*.php" --package-name="ClassicPress"
wp i18n make-pot ./ClassicPress/build ./admin-en_US.pot --ignore-domain --skip-audit --exclude="wp-activate.php,wp-comments-post.php,wp-cron.php,wp-links-opml.php,wp-load.php,wp-login.php,wp-mail.php,wp-signup.php,wp-trackback.php,wp-content,wp-includes,wp-admin/includes/continents-cities.php,wp-admin/ms-*.php,wp-admin/my-sites.php,wp-admin/network.php,wp-admin/includes/class-wp-ms-*.php,wp-admin/includes/ms.php,wp-admin/includes/ms-*.php,wp-admin/network/" --package-name="ClassicPress"
wp i18n make-pot ./ClassicPress/build ./admin-network-en_US.pot --ignore-domain --skip-audit --include="wp-admin/ms-*.php,wp-admin/my-sites.php,wp-admin/network.php,wp-admin/includes/class-wp-ms-*.php,wp-admin/includes/ms.php,wp-admin/includes/ms-*.php,wp-admin/network/,wp-includes/class-wp-network*.php,wp-includes/ms-*.php" --package-name="ClassicPress"
wp i18n make-pot ./ClassicPress/build ./continents-cities-en_US.pot --ignore-domain --skip-audit --include="wp-admin/includes/continents-cities.php" --package-name="ClassicPress"

for pot in en_US.pot admin-en_US.pot admin-network-en_US.pot continents-cities-en_US.pot; do
	# Prepend the Copyright notice to POT files
	$SED_COMMAND -i '1s/^/# Copyright (C) 2024 ClassicPress\n/' ./"$pot"
	$SED_COMMAND -i '2s/^/# This file is distributed under the same license as the ClassicPress package.\n/' ./"$pot"
	# Delete unused lines from POT files
	$SED_COMMAND -i '7d;8d;13d' ./"$pot"
	# Add forum link for bug reporting
	$SED_COMMAND -ri 's|Report-Msgid-Bugs-To: |Report-Msgid-Bugs-To: https://forums.classicpress.net/c/team-discussions/internationalisation/42|' ./"$pot"
	# Update version number
	$SED_COMMAND -ri "s|${WP_VERSION}|${CP_VERSION}|" ./"$pot"
done
