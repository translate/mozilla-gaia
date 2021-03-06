#!/bin/bash

source ttk.inc.sh

progress="--progress=none"

langs=$(which_langs $*)

if [ -z "$release" ]; then
	git checkout master
	mozilla_repository=http://hg.mozilla.org/gaia-l10n
else
	git checkout $release
	mozrelease="v$(echo $release | tr '.' '_')"
	mozilla_repository=http://hg.mozilla.org/releases/gaia-l10n/$mozrelease
fi

function update_hg_repo()
{
	(
	mkdir -p $base_dir/build/locales/$mozrelease
	cd $base_dir/build/locales/$mozrelease
	if [ -d $mozlang ]; then
		cd $mozlang
		if [ $mozlang == "en-US" ]; then
			hg pull
			hg update
		else
			hg pull -u
			hg update -C
		fi

	else
		log_debug "hg clone $mozilla_repository/$mozlang $mozlang"
		hg clone $mozilla_repository/$mozlang $mozlang
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
		log_debug "cd $base_dir/build/locales/$mozrelease/$mozlang; moz2po $progress --exclude=".hgtags" --exclude="*.diff" -P .      $translation_dir/$polang"
		(cd $base_dir/build/locales/$mozrelease/$mozlang; moz2po $progress --exclude=".hgtags" --exclude="*.diff" -P . $translation_dir/$polang)
	else
		polang=$(get_language_pootle $lang)
		mozlang=$(get_language_upstream $lang)
		update_hg_repo
		# update against templates
		rm -rf $translation_dir/.tmp/$polang
		mkdir -p $translation_dir/.tmp/
		cp -rp $translation_dir/$polang $translation_dir/.tmp/
		rm $(find $translation_dir/$polang -name "*.po")
		pomigrate2 --quiet --pot2po $translation_dir/.tmp/$polang $translation_dir/$polang $translation_dir/templates
		rm -rf $translation_dir/.tmp/$polang
		# new locale files
		rm $(find $base_dir/build/locales/$mozrelease/$mozlang -name "*.properties")
		po2moz $progress --removeuntranslated --exclude="obsolete" -t $base_dir/build/locales/$mozrelease/en-US $translation_dir/$polang $base_dir/build/locales/$mozrelease/$mozlang
	fi
done

langs=$(get_language_pootle $langs)
clean_po_location $translation_dir $langs
revert_unchanged_po_git $translation_dir $langs
