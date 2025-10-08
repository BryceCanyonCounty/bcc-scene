fx_version "cerulean"
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

game 'rdr3'
lua54 'yes'
author 'BCC Team'

shared_scripts {
    'configs/*.lua'
}

client_scripts {
	'client/nui.lua',
	'client/main.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/main.lua'
}

files {
    'ui/*',
    'ui/assets/*',
    'ui/assets/fonts/*'
}

ui_page 'ui/index.html'

version '2.2.3'
