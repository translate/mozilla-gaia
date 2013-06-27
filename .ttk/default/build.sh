#!/bin/bash

source ttk.inc.sh

langs=$(which_langs $*)

function update_hg_repo()
{
	(
	mkdir -p $base_dir/build/locales/
	cd $base_dir/build/locales/
	if [ -d $mozlang ]; then
		cd $mozlang;
		hg pull;
		hg update;
	else
		hg clone http://hg.mozilla.org/gaia-l10n/$mozlang $mozlang
	fi
	)
}

for lang in $langs
do
	log_info "Building: $lang"
	if [ "$lang" == "templates" ]; then
		polang=$lang
		mozlang=en-US
		# Update en-US
		update_hg_repo
		
		# Make new template files
		rm $(find $translation_dir/$polang -name "*.pot")
		(cd $base_dir/build/locales/$mozlang; moz2po $verbosity --exclude=".hgtags" --exclude="*.diff" -P . $translation_dir/$polang)
	else
		polang=$(get_language_pootle $lang)
		mozlang=$(get_language_upstream $lang)
		update_hg_repo
		# update against templates
		pot2po $verbosity -t $translation_dir/$polang $translation_dir/templates $translation_dir/$polang
		# new locale files
		po2moz $verbosity --exclude="obsolete" -t $base_dir/build/locales/en-US $translation_dir/$polang $base_dir/build/locales/$mozlang
	fi
done

langs=$(get_language_pootle $langs)
clean_po_location $translation_dir $langs
revert_unchanged_po_git $translation_dir $langs
