component accessors=true {

	property name="Generator" type="component" hint="constructor will usually load this for you";
	property name="LoadersPath" type="string" hint="path to generate loaders into e.g. 'com.generated.loaders'";

	public loader function init() {
		variables.loaderCache = {};
		setGenerator(new generator());
		return this;
	}

	/**
	* @hint Clears loader cache (for testing)
	**/
	public void function clearLoaderCache() {
		variables.loaderCache = {};
	}

	/**
	* @hint given a string, returns a string mimicking (cffile action="write" fixnewline="yes")
	* @see  https://www.raymondcamden.com/2014/02/10/Mimicking-fixNewLine-in-ColdFusion-Script
	**/
	private string function fixNewLine(s) {
		// http://stackoverflow.com/a/6374360/52160
		if ( server.os.name contains "windows" ) {
			return rereplace(arguments.s, "\r\n|\n|\r","#chr(13)##chr(10)#", "all");
		} else {
			return rereplace(arguments.s, "\r\n|\n|\r","#chr(10)#", "all");
		}
	}

	/**
	* @hint returns a specific loader given a cfc
	**/
	public component function getCfcLoader(required component cfc, string cfcName) {
		if ( !StructKeyExists(arguments, "cfcName") || Len(arguments.cfcName) == 0 ) {
			arguments.cfcName = getCfcName(cfc = arguments.cfc);
		}
		if ( !StructKeyExists(variables.loaderCache, arguments.cfcName) ) {
			var loaderName = getCfcLoaderName(cfc = arguments.cfc, cfcName = arguments.cfcName);
			if ( !loaderExists(cfcName = loaderName) ) {
				writeLoader(
					cfcName = loaderName,
					code = fixNewLine(getGenerator().generate(cfc = arguments.cfc))
				);
			}
			variables.loaderCache[arguments.cfcName] = CreateObject("component", loaderName).init(loader = this);
		}
		return variables.loaderCache[arguments.cfcName];
	}

	/**
	* @hint returns a loader name given a cfc (specific to the CFC and its current metadata)
	**/
	private string function getCfcLoaderName(required component cfc, string cfcName) {
		if ( StructKeyExists(arguments, "cfcName") && Len(arguments.cfcName) > 0 ) {
			var loaderName = arguments.cfcName;
		} else {
			var loaderName = getCfcName(cfc = arguments.cfc);
			arguments.cfcName = loaderName;
		}
		// We're going to replace the dots (which represent directories in CFC names) with underscore.
		// But, some CFCs already have an underscore in the name.
		// And we could get a naming collision with two cfcs like the following:
		// 	* com.foo.bar_baz > com_foo_bar_baz
		// 	* com.foo.bar.baz > com_foo_bar_baz
		// So, I'm going to double up underscores in names before replacing the dots.
		loaderName = Replace(loaderName, "_", "__", "all");
		// Replace dots with underscores (to keep all loaders in one directory).
		loaderName = Replace(loaderName, ".", "_", "all");
		// Prepend LoadersPath to fully qualify CFC name.
		loaderName = getLoadersPath() & '.' & loaderName;
		// Suffix cfc path with hash so that we know it's the right "version" for the CFC.
		loaderName &= "_" & getGenerator().getSignature(cfcName = arguments.cfcName);
		return loaderName;
	}

	/**
	* @hint returns a component path given a cfc
	**/
	private string function getCfcName(required component cfc) {
		return GetMetaData(arguments.cfc).name;
	}

	/**
	* @hint loads a provided component with provided data
	**/
	public component function load(
		required component cfc,
		required any data = {},
		string cfcName = ""
	) {
		if ( !IsStruct(arguments.data) ) {
			arguments.data = DeserializeJson(arguments.data);
		}
		getCfcLoader(cfc = arguments.cfc, cfcName = arguments.cfcName).load(
			cfc = arguments.cfc,
			data = arguments.data
		);
		return arguments.cfc;
	}

	/**
	* @hint given a loader name, returns true if it exists
	**/
	private boolean function loaderExists(required string cfcName) {
		var filePath = "/" & Replace(arguments.cfcName, ".", "/", "all") & ".cfc";
		return FileExists(ExpandPath(filePath));
	}

	/**
	* @hint given a loader name and code, writes code to disk
	**/
	private void function writeLoader(
		required string cfcName,
		required string code
	) {
		var filePath = "/" & Replace(arguments.cfcName, ".", "/", "all") & ".cfc";
		FileWrite(ExpandPath(filePath), arguments.code);
	}

}