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
		pofiledate="$(grep -E "\"PO-Revision-Date: " "${n}" | cut -c 20- | cut -c -16)"
		podates+="$(printf  '%s,' "${pofiledate}")"
		wp i18n make-mo "${n}"
	done

	IFS=',' read -ra podatesarr <<< "$podates"
	most_recent_ts=0

	for podate in "${podatesarr[@]}";
	do
		if [[ "$OSTYPE" == "linux-gnu"* ]]; then
			ts="$(date -d "${podate}" +%s)"
		elif [[ "$OSTYPE" == "darwin"* ]]; then
			ts="$(date -j -f "%Y-%m-%d %H:%M" "${podate}" "+%s")"
		fi
		
		if [[ -n "${ts}" && ( "${most_recent_ts}" -eq 0 || "${ts}" -gt "${most_recent_ts}" ) ]]; then
			most_recent_ts="${ts}"
			most_recent="${podate}"
		fi
	done

	echo ''
	echo 'Most recent update'
	echo "${most_recent}"

	echo ''
	echo 'Creating JSON files'
	wp i18n make-json --no-purge .

	echo ''
	echo 'Creating l10n.php files'
	wp i18n make-php .

	pomofiles=""
	for f in *${locales}.{po,mo,l10n.php}; do
		pomofiles+="${f} "
	done

	echo ''
	echo 'Creating zip file'
	for n in ${pomofiles[@]};
	do
		zip -q "../../zips/$locales.zip" "$n"
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
		zip -q "../../zips/$locales.zip" "$n"
	done
popd > /dev/null

echo 'Removing working locale folder'
rm -rf "$locales"

# report zip file name and creation date/time
echo ''
echo "$locales.zip created"


# human readable to minified
# gsed -r s'|^\s*||' < translations-hr.json | gsed -r s'|:\s|:|' | tr -d '\n'> translations.json
# $SED_COMMAND -r s'|^\s*||' < translations-hr.json | $SED_COMMAND -r s'|:\s|:|' | tr -d '\n'> translations.json