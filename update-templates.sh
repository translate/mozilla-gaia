#!/bin/bash

source $(dirname $0)/../firefox/ttk.inc.sh
stop_if_running
mk_lock_file

if [ "$release" ]; then
	mozrelease="v$(echo $release | tr '.' '_')"
	release_str=$release
else
	release_str="master"
fi

ttk-build templates
git add -A templates
git diff --quiet --cached --exit-code templates
if [ $? -ne 0 ]; then
	git commit -m "Templates: update ($release_str)" templates
	ttk-put templates
	id=$(ttk-changeid)
	logger_file templates $id
	ttk-get
	git add -A $(ttk-langs)
	git commit -m "Various: pre templates update ($release_str)"
	ttk-build
	git add -A $(ttk-langs)
	git commit -m "All: update against templates ($release_str)"
	ttk-put --keep=$id
fi
git push
rm_lock_file
