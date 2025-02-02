#!/usr/bin/env bash

# Exit on error
set -e

cd "$(dirname "$0")"
cd ..

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	SED_COMMAND="sed"
elif [[ "$OSTYPE" == "darwin"* ]]; then
	SED_COMMAND="gsed"
else
	echo "Sorry, this script hasn't been tested on your OS platform"
	exit 1
fi

locales="$1"

if [ -z "$locales" ]; then
	echo "Locale variable not set!" >&2
	echo "Usage : $0 LOCALE_CODE" >&2
	exit 1
fi

mkdir -p zips
dir="./translations"

cd "$dir"
mkdir "$locales"

# create a list of all available locales
echo 'Creating list of PO files for locale'
pofiles=""
for f in *${locales}.po; do
	pofiles+="${f} "
done

echo 'Copying PO files to working locale folder'
for n in ${pofiles[@]};
do
	cp "${n}" "$locales"
done

pushd "$locales" > /dev/null
	# make *.mo files for all *.po files
	echo 'Working in locale folder'
	echo ''
	echo 'Creating mo files'
	for n in ${pofiles[@]};
	do
		wp i18n make-mo "${n}"
	done

	echo ''
	echo 'Creating JSON files'
	wp i18n make-json --no-purge .
	
	pomofiles=""
	for f in *${locales}.{po,mo}; do
		pomofiles+="${f} "
	done
	
	echo ''
	echo 'Creating zip file'
	for n in ${pomofiles[@]};
	do
		zip "../../zips/$locales.zip" "$n"
	done

	for f in admin-*${locales}*.json; do
		mv "${f}" "${f#admin-}"
	done
	
	jsonfiles=""
	for f in *${locales}*.json; do
		jsonfiles+="${f} "
	done

	for n in ${jsonfiles[@]};
	do
		zip "../../zips/$locales.zip" "$n"
	done
popd > /dev/null

echo 'Removing working locale folder'
rm -rf "$locales"

# report zip file name and creation date/time
echo ''
echo "$locales.zip created"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	stat -c '%.19z' "../../zips/$locales.zip"
elif [[ "$OSTYPE" == "darwin"* ]]; then
	stat -f %SB -t '%Y-%m-%d %H:%M:%S' "../../zips/$locales.zip"
fi

# human readable to minified
# gsed -r s'|^\s*||' < translations-hr.json | gsed -r s'|:\s|:|' | tr -d '\n'> translations.json
# $SED_COMMAND -r s'|^\s*||' < translations-hr.json | $SED_COMMAND -r s'|:\s|:|' | tr -d '\n'> translations.json