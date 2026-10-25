fx_version 'cerulean'
game 'gta5'

name 'mrpat_offshore_maintenance'
author 'MisterPattie'
description 'Offshore Maintenance for Qbox'
version '1.0.0'

ui_page 'html/index.html'

dependencies {
	'ox_lib',
	'qbx_core',
	'qbx_vehiclekeys',
	'ox_target'
}

shared_scripts {
	'@ox_lib/init.lua',
	'@qbx_core/modules/lib.lua',
	'config/shared.lua',
	'shared/utils.lua',
}

client_scripts {
	'config/client.lua',
	'client/client.lua',
	'client/debug.lua',
}

server_scripts {
	'config/server.lua',
	'server/server.lua',
	'server/stats.lua',
	'server/debug.lua',
}

files {
	'locales/*.json',
	'html/index.html',
	'html/style.css',
	'html/script.js',
}