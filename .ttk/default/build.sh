#!/bin/bash

source ttk.inc.sh

langs=$(which_langs $*)

for lang in $langs
do
	log_info "Building: $lang"
	if [ "$lang" == "templates" ]; then
		# Update en-US
		(cd build/locales/en-US; hg pull; hg update)
		
		# Make new template files
		rm $(find templates -name "*.pot")
		(cd build/locales/en-US; moz2po $verbosity --exclude=".hgtags" --exclude="*.diff" -P . $translation_dir/templates)
	else
		polang=$(get_language_pootle $lang)
		mozlang=$(get_language_upstream $lang)
		# update against templates
		pot2po $verbosity -t $translation_dir/$polang $translation_dir/templates $translation_dir/$polang
		# new locale files
		po2moz $verbosity --exclude="obsolete" -t build/locales/en-US $translation_dir/$polang build/locales/$mozlang
	fi
done

langs=$(get_language_pootle $langs)
clean_po_location $translation_dir $langs
revert_unchanged_po_git $translation_dir $langs
