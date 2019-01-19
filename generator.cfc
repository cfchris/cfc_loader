component {

	/**
	* @hint given a component, returns the generated code for a loader
	**/
	public string function generate(required component cfc) {
		var properties = getProperties(cfc = arguments.cfc);
		var code =  'component {

			// Cached loaders (populated in constructor)
			variables.loaders = {};

			// Template VOs
			variables.vos = {};
			#Trim(getVoCacheCode(properties = properties))#

			public component function init(required loader loader) {
				variables.loader = arguments.loader;
				for ( var key in variables.vos ) {
					variables.loaders[key] = variables.loader.getCfcLoader(variables.vos[key]);
				}
				return this;
			}

			#Trim(getLoadMethod(properties = properties))#
		}';
		// replace two tabs from the front of lines
		code = ReReplace(code, "(?m)^\t\t", "", "all");
		// replace lines that are only tabs with empty line
		code = ReReplace(code, "(?m)^[\t]+$", "", "all");
		return code;
	}

	/**
	* @hint generates code for the load()
	**/
	public string function getLoadMethod(required array properties) {
		var propertySetters = "";
		for ( var p in arguments.properties ) {
			var propertySetters &= '
				#Trim(getPropertyCode(property = p))#';
		}
		return '
			public void function load(
				required component cfc,
				required struct data = {}
			) {
				if ( StructIsEmpty(arguments.data) ) {
					return;
				}
				#Trim(propertySetters)#
			}
		';
	}

	/**
	* @hint given a component, returns array of properties
	**/
	public array function getProperties(required component cfc) {
		var properties = [];
		var metaData = GetMetaData(arguments.cfc);
		while ( StructKeyExists(metaData, "extends") ) {
			if ( !StructKeyExists(metaData, "Properties") ) {
				metaData = metaData.extends;
				continue;
			}
			for ( var p in metaData.Properties ) {
				var property = {
					"name": p.name,
					"type": p.type,
					"item_type": StructKeyExists(p, "item_type") ? p.item_type : ""
				};
				if ( !ListFindNoCase("any,array,binary,boolean,date,guid,numeric,query,string,struct,uuid", p.type) ) {
					// see: https://helpx.adobe.com/coldfusion/cfml-reference/coldfusion-tags/tags-p-q/cfproperty.html
					// > If the type attribute value is not one of the preceding items,
					// > ColdFusion treats it as the name of a ColdFusion component.
					property.type = "component";
					property.item_type = p.type;
				}
				ArrayAppend(properties, property);
			}
			metaData = metaData.extends;
		}
		ArraySort(properties, function(a, b) {
			return CompareNoCase(a.name, b.name);
		});
		return properties;
	}

	/**
	* @hint given a property, returns the generated code for using 'data' to populate it
	**/
	private string function getPropertyCode(required struct property) {
		// NOTE:
		// 	"component" and "array" of "item_type" check if the data needs to be "load()ed" by using IsStruct().
		// 	(The "assumption" being that if the data is a struct we can load it into "item_type".)
		// 	I was doing the opposite using IsInstanceOf() to see it we "didn't need to load()" items.
		// 	But, IsInstanceOf was like 100 times slower than IsStruct(). It's just too slow.
		if ( arguments.property.type == "array" && arguments.property.item_type != "" ) {
			return '
				if ( StructKeyExists(arguments.data, "#arguments.property.name#") && !IsNull(arguments.data["#arguments.property.name#"]) && IsArray(arguments.data["#arguments.property.name#"]) ) {
					var clean = [];
					for ( var item in arguments.data["#arguments.property.name#"] ) {
						if ( IsStruct(item) ) {
							var vo = Duplicate(variables.vos["#arguments.property.item_type#"]);
							variables.loaders["#arguments.property.item_type#"].load(cfc = vo, data = item);
							ArrayAppend(clean, vo);
						} else {
							ArrayAppend(clean, item);
						}
					}
					arguments.cfc.set#arguments.property.name#(clean);
				}
			';
		}
		if ( arguments.property.type == "component" ) {
			return '
				if ( StructKeyExists(arguments.data, "#arguments.property.name#") && !IsNull(arguments.data["#arguments.property.name#"]) ) {
					if ( IsStruct(arguments.data["#arguments.property.name#"]) ) {
						var vo = Duplicate(variables.vos["#arguments.property.item_type#"]);
						variables.loaders["#arguments.property.item_type#"].load(cfc = vo, data = arguments.data["#arguments.property.name#"]);
						arguments.cfc.set#arguments.property.name#(vo);
					} else {
						arguments.cfc.set#arguments.property.name#(arguments.data["#arguments.property.name#"]);
					}
				}
			';
		}
		return '
				if ( StructKeyExists(arguments.data, "#arguments.property.name#") && !IsNull(arguments.data["#arguments.property.name#"]) ) {
					arguments.cfc.set#arguments.property.name#(arguments.data["#arguments.property.name#"]);
				}
		';
	}

	/**
	* @hint given a cfc, returns a hash used to make sure the generated loader is in sync with the CFC it's going to load
	**/
	public string function getSignature(required component cfc) {
		// The goal of any given loader is to set properties on a given CFC.
		// If any of the properties on a CFC (or any it extends) change, that's a new signature.
		var identity = SerializeJson(getProperties(cfc = arguments.cfc));
		// If the generator itself changes, we also need to generate a new loader.
		var generatorCode = FileRead(GetMetaData(this).path);
		return Hash(identity & generatorCode);
	}

	/**
	* @hint given array of properties, returns the generated code for caching VOs (to duplicate)
	**/
	private string function getVoCacheCode(required array properties) {
		var typeList = "";
		for ( var p in arguments.properties ) {
			var typeList = ListAppend(typeList, p.item_type);
		}
		var typeList = ListSort(ListRemoveDuplicates(typeList), "text");
		var sets = "";
		for ( var typeName in ListToArray(typeList) ) {
			var sets &= '
			variables.vos["#typeName#"] = CreateObject("component", "#typeName#");';
		}
		return sets;
	}
}