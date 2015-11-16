project=firefoxos
instance=mozilla
user=pootlesync
server=mozilla.locamotion.org
local_copy=$base_dir/.pootle_tmp
manage_command="/var/www/sites/$instance/src/manage.py"
manage_py_verbosity=0
precommand=". /var/www/sites/$instance/env/bin/activate;"
opt_verbose=0

alt_src="es fr ru"
