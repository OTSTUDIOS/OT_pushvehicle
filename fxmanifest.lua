fx_version 'cerulean'
games {'gta5'}

author 'stuxxy'
version '1.0.1'

lua54 'yes'

shared_scripts {
	'@ox_lib/init.lua',
	'shared/config.lua',
}

client_scripts {
	'client/main.lua'
}

server_scripts {
	'server/main.lua'
}

escrow_ignore {
	'**/*.lua'
}
