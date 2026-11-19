# Translating ClassicPress

## Background

This repository contains files and scripts used for translating ClassicPress into other languages. If you are looking for the right place to contribute translations you need to visit our project on [CrownIn](https://classicpress.crowdin.com/u/projects/1).

If you are here to review or contribute to the translation file process, them **welcome**!

## Requirements

To work with this repository you will need to be using Linux or MacOS locally. You will need:
- WP-CLI installed (see [external documentation](https://wp-cli.org/) on how to install)
- MacOS users will need **gsed**, we recommend installing via [brew](https://brew.sh/)
- git

## Creating POT files

To create new POT files for a new release:

`bin/create_pot.sh`

This command will clone ClassicPress locally, build the distribution code and then create three POT files:

- en_US.pot
- admin-en_US.pot
- admin-network-en_US.pot

The first of these contains string that exist in the root files and `wp-includes`, the second  contains the majority of string the appear in the Admin area after logging in and the last contains Admin area files used in Multisite installs only. The purpose of the three files is to reduce loading times by only loading string translations that are likely to be needed.

Once these files are committed to GitHub, Crowdin will automatically sync them for known branches to allow translation contributors to get to work. For brand new major releases of ClassicPress a new branch is needed and further configuration in Crowdin may be needed.  

## Creating POT files

Once the Crowdin contributors have added some translations, these are synced back to GitHub into a service branch. This is a branch prefixed with`l10n_`. and it will contain PO files. The script at `bin/build_zip.sh` can be used to create MO files from these files and also create language pack zip files ready to upload to the API server. A json file will also be needed to deliver information to ClassicPress instals about the available language packs.