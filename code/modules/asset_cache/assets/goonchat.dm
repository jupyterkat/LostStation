/datum/asset/group/goonchat
	children = list(
		/datum/asset/simple/jquery,
		/datum/asset/simple/namespaced/goonchat,
		/datum/asset/simple/namespaced/goonchat_fontawesome
	)


/datum/asset/simple/namespaced/goonchat
	legacy = TRUE
	assets = list(
		"json2.min.js"             = 'code/modules/goonchat/browserassets/js/json2.min.js',
		"browserOutput.js"         = 'code/modules/goonchat/browserassets/js/browserOutput.js',
		"browserOutput.css"	       = 'code/modules/goonchat/browserassets/css/browserOutput.css',
		"errorHandler.js"          = 'code/modules/goonchat/browserassets/js/errorHandler.js',
	)
	parents = list(
		//this list intentionally left empty (parent namespaced assets can't be referred to by name, only by generated url, and goonchat isn't smart enough for that. yet)
	)

/datum/asset/simple/namespaced/goonchat_fontawesome
	legacy = TRUE
	assets = list(
		"fontawesome-webfont.eot"  = 'html/fontawesome-goonchat/fontawesome-webfont.eot',
		"fontawesome-webfont.svg"  = 'html/fontawesome-goonchat/fontawesome-webfont.svg',
		"fontawesome-webfont.ttf"  = 'html/fontawesome-goonchat/fontawesome-webfont.ttf',
		"fontawesome-webfont.woff" = 'html/fontawesome-goonchat/fontawesome-webfont.woff',
		"font-awesome-gc.css"	   = 'code/modules/goonchat/browserassets/css/font-awesome.css',
	)
