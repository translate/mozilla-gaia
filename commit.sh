#!/bin/bash

source $(dirname $0)/../firefox/ttk.inc.sh
stop_if_running
mk_lock_file

if [[ $# -lt 1 ]]; then
	echo "$(basename $0) <--since|[lang|changeid>"
	echo "We don't allow all commits as we might overwrite other peoples work"
	exit 1
fi

if [[ $1 == "--since" ]]; then
	stop_if_no_last_commit
	mk_new_commit_file
	langs=$(which_langs $(cat $last_commit_file))
	[[ $langs ]] && logger_file commit auto "$(cat $last_commit_file)>$(cat $new_commit_file)" "{ $langs }"
	auto="yes"
else
	langs=$(which_langs $*)
	[[ $langs ]] && logger_file commit manual "{ $* }" "{ $langs }"
fi

if [[ ! $langs ]]; then
	rm_lock_file
	exit
fi

if [ "$release" ]; then
	mozrelease="v$(echo $release | tr '.' '_')"
	release_str=$release
else
	release_str="master"
fi

for lang in $langs
do
	mozlang=$(get_language_upstream $lang)
	pootlelang=$(get_language_pootle $lang)
	ttk-get $lang
	git add -A $lang
	git commit -m "[$lang] pull from Pootle ($release_str)"
	ttk-build $lang
	git checkout $lang
	(
	cd build/locales/$mozrelease/$mozlang
	for prop in $(find . -name "*.properties")
	do
		sed -i 's/\\n/\\u000a/g' $prop
	done
	hg addremove
	hg commit -m "[$mozlang] update from Pootle ($release_str)" --user "$mozlang team [Pootle] <https://wiki.mozilla.org/L10n:Teams:$mozlang>"
	hg push
	)
done
git push
[[ $auto ]] & update_last_commit_file
rm_lock_file
