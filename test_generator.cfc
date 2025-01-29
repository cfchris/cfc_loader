component extends="mxunit.framework.TestCase" {

	/*
		run tests:
			/cfc_loader/test_generator.cfc?method=runtestremote&output=html
	*/

	/* this will run before every single test in this test case */
	public void function setUp() {
		variables.generator = new generator();
	}

	/* this will run after every single test in this test case */
	public void function tearDown() {}

	/* this will run once after initialization and before setUp() */
	public void function beforeTests() {}

	/* this will run once after all tests have been run */
	public void function afterTests() {}

	/*
	* TESTS
	*/

	/**
	* @hint "I test generate."
	**/
	public void function test_generate() {
		var tests = [
			"no properties": {
				"args": {
					"cfc": new test_cfcs.Option().setId(1)
				},
				"mocks": {
					"getProperties": [],
					"getVoCacheCode": "// VO cache code 1",
					"getLoadMethod": "// load method 1"
				},
				"expect": {
					"calls": {
						"getProperties": [
							{"cfc": SerializeJson(new test_cfcs.Option().setId(1))}
						],
						"getVoCacheCode": [
							{"properties": []}
						],
						"getLoadMethod": [
							{"properties": []}
						]
					},
					"result": '
						component {

							// name of component this loader loads
							variables.componentToLoad = "test_cfcs.Option";

							// cache of loaders (lazy loaded by getCfcLoader)
							variables.loaders = {};

							// cache of template VOs (for duplicateing)
							variables.vos = {};
							// VO cache code 1

							public component function init(required loader loader) {
								variables.parentLoader = arguments.loader;
								return this;
							}

							private component function getCfcLoader(required string cfcName) {
								if ( !StructKeyExists(variables.loaders, arguments.cfcName) ) {
									variables.loaders[arguments.cfcName] = variables.parentLoader.getCfcLoader(
										cfc = variables.vos[arguments.cfcName],
										cfcName = arguments.cfcName
									);
								}
								return variables.loaders[arguments.cfcName];
							}

							// load method 1
						}
					'
				}
			},
			"multiple properties": {
				"args": {
					"cfc": new test_cfcs.Option().setId(2)
				},
				"mocks": {
					"getProperties": [
						{"name": "numericProp", "type": "numeric",   "item_type": ""},
						{"name": "optionProp",  "type": "component", "item_type": "testVo1"}
					],
					"getVoCacheCode": "// VO cache code 2",
					"getLoadMethod": "// load method 2"
				},
				"expect": {
					"calls": {
						"getProperties": [
							{"cfc": SerializeJson(new test_cfcs.Option().setId(2))}
						],
						"getVoCacheCode": [
							{
								"properties": [
									{"name": "numericProp", "type": "numeric",   "item_type": ""},
									{"name": "optionProp",  "type": "component", "item_type": "testVo1"}
								]
							}
						],
						"getLoadMethod": [
							{
								"properties": [
									{"name": "numericProp", "type": "numeric",   "item_type": ""},
									{"name": "optionProp",  "type": "component", "item_type": "testVo1"}
								]
							}
						]
					},
					"result": '
						component {

							// name of component this loader loads
							variables.componentToLoad = "test_cfcs.Option";

							// cache of loaders (lazy loaded by getCfcLoader)
							variables.loaders = {};

							// cache of template VOs (for duplicateing)
							variables.vos = {};
							// VO cache code 2

							public component function init(required loader loader) {
								variables.parentLoader = arguments.loader;
								return this;
							}

							private component function getCfcLoader(required string cfcName) {
								if ( !StructKeyExists(variables.loaders, arguments.cfcName) ) {
									variables.loaders[arguments.cfcName] = variables.parentLoader.getCfcLoader(
										cfc = variables.vos[arguments.cfcName],
										cfcName = arguments.cfcName
									);
								}
								return variables.loaders[arguments.cfcName];
							}

							// load method 2
						}
					'
				}
			}
		];
		MakePublic(variables.generator, "getProperties");
		InjectMethod(variables.generator, this, "getPropertiesMock", "getProperties");
		MakePublic(variables.generator, "getVoCacheCode");
		InjectMethod(variables.generator, this, "getVoCacheCodeMock", "getVoCacheCode");
		MakePublic(variables.generator, "getLoadMethod");
		InjectMethod(variables.generator, this, "getLoadMethodMock", "getLoadMethod");
		for ( var name in tests ) {
			var test = tests[name];
			// reset calls and mocks
			var calls = {
				"getProperties": [],
				"getVoCacheCode": [],
				"getLoadMethod": []
			};
			variables.generator["getProperties_Args"] = [];
			variables.generator["getProperties_Mock"] = test.mocks.getProperties;
			variables.generator["getVoCacheCode_Args"] = [];
			variables.generator["getVoCacheCode_Mock"] = test.mocks.getVoCacheCode;
			variables.generator["getLoadMethod_Args"] = [];
			variables.generator["getLoadMethod_Mock"] = test.mocks.getLoadMethod;
			// call method under test
			var result = variables.generator.generate(cfc = test.args.cfc);
			// gather calls from injected mocks
			calls["getProperties"] = variables.generator["getProperties_Args"];
			calls["getVoCacheCode"] = variables.generator["getVoCacheCode_Args"];
			calls["getLoadMethod"] = variables.generator["getLoadMethod_Args"];
			// check assertions
			AssertEquals(test.expect.calls, calls, "#name# - calls don't match expected");
			var trimIndentRegex = "(?m)^\s+";
			AssertEquals(
				ReReplace(Trim(test.expect.result), trimIndentRegex, "", "all"),
				ReReplace(Trim(result), trimIndentRegex, "", "all"),
				"#name# - result doesn't match expected"
			);
		}
	}

	/**
	* @hint "I test getRecursiveCfcCode."
	**/
	public void function test_getRecursiveCfcCode() {
		var tests = [
			"no extends": {
				args: {
					cfcName: "test_cfcs.ExtendsBase"
				},
				expect: {
					result: '
						component accessors="true" {
							property name="base1" type="string";
							property name="base2" type="string";
						}
					'
				}
			},
			"extends one level": {
				args: {
					cfcName: "test_cfcs.Extends1"
				},
				expect: {
					result: '
						component accessors="true" extends="ExtendsBase" {
							property name="extends1" type="string";
						}
						component accessors="true" {
							property name="base1" type="string";
							property name="base2" type="string";
						}
					'
				}
			},
			"extends multiple levels": {
				args: {
					cfcName: "test_cfcs.Extends2"
				},
				expect: {
					result: '
						component accessors="true" extends="Extends1" {
							property name="extends2" type="string";
						}
						component accessors="true" extends="ExtendsBase" {
							property name="extends1" type="string";
						}
						component accessors="true" {
							property name="base1" type="string";
							property name="base2" type="string";
						}
					'
				}
			}
		];
		for ( var name in tests ) {
			var test = tests[name];
			try {
				var result = variables.generator.getRecursiveCfcCode(cfcName = test.args.cfcName);
			} catch (any e) {
				debug(e);
				fail("#name# - unexpected error (#e.message#). run w/ debug for details.");
			}
			var trimWhiteSpace = "(?m)\s+";
			AssertEquals(
				ReReplace("<pre>" & Trim(test.expect.result), trimWhiteSpace, "", "all") & "</pre>",
				ReReplace("<pre>" & Trim(result), trimWhiteSpace, "", "all") & "</pre>",
				"#name# - result doesn't match expected"
			);
		}
	}

	/**
	* @hint "I test getLoadMethod."
	**/
	public void function test_getLoadMethod() {
		var tests = [
			"no properties": {
				"args": {
					"properties": []
				},
				"mocks": {
					"getPropertyCode": ""
				},
				"expect": {
					"calls": {
						"getPropertyCode": [] // expect no calls
					},
					"result": '
						public void function load(
							required component cfc,
							required struct data = {}
						) {
							if ( StructIsEmpty(arguments.data) ) {
								return;
							}
							
						}
					'
				}
			},
			"multiple properties": {
				"args": {
					"properties": [
						{"name": "numericProp", "type": "numeric",   "item_type": ""},
						{"name": "optionProp",  "type": "component", "item_type": "testVo1"}
					]
				},
				"mocks": {
					"getPropertyCode": "// property code"
				},
				"expect": {
					"calls": {
						"getPropertyCode": [
							{
								"property": {"name": "numericProp", "type": "numeric",   "item_type": ""}
							},
							{
								"property": {"name": "optionProp",  "type": "component", "item_type": "testVo1"}
							}
						]
					},
					"result": '
						public void function load(
							required component cfc,
							required struct data = {}
						) {
							if ( StructIsEmpty(arguments.data) ) {
								return;
							}
							// property code
							// property code
						}
					'
				}
			}
		];
		MakePublic(variables.generator, "getPropertyCode");
		InjectMethod(variables.generator, this, "getPropertyCodeMock", "getPropertyCode");
		for ( var name in tests ) {
			var test = tests[name];
			// reset calls and mocks
			var calls = {
				"getPropertyCode": []
			};
			variables.generator["getPropertyCode_Args"] = [];
			variables.generator["getPropertyCode_Mock"] = test.mocks.getPropertyCode;
			// call method under test
			var result = variables.generator.getLoadMethod(properties = test.args.properties);
			// check assertions
			calls["getPropertyCode"] = variables.generator["getPropertyCode_Args"];
			AssertEquals(test.expect.calls, calls, "#name# - calls don't match expected");
			var trimIndentRegex = "(?m)^\s+";
			AssertEquals(
				ReReplace(Trim(test.expect.result), trimIndentRegex, "", "all"),
				ReReplace(Trim(result), trimIndentRegex, "", "all"),
				"#name# - result doesn't match expected"
			);
		}
	}

	/**
	* @hint "I test getProperties."
	**/
	public void function test_getProperties() {
		var tests = [
			"*all* property types": {
				"args": {
					"cfc": new test_cfcs.AllPropertyTypes()
				},
				"expect": {
					"result": [
						{"name": "anyProp",       "type": "any",       "item_type": ""},
						{"name": "arrayProp",     "type": "array",     "item_type": ""},
						{"name": "binaryProp",    "type": "binary",    "item_type": ""},
						{"name": "booleanProp",   "type": "boolean",   "item_type": ""},
						{"name": "dateProp",      "type": "date",      "item_type": ""},
						{"name": "guidProp",      "type": "guid",      "item_type": ""},
						{"name": "numericProp",   "type": "numeric",   "item_type": ""},
						{"name": "optionProp",    "type": "component", "item_type": "test_cfcs.Option"},
						{"name": "optionsProp",   "type": "array",     "item_type": "test_cfcs.Option"},
						{"name": "queryProp",     "type": "query",     "item_type": ""},
						{"name": "stringProp",    "type": "string",    "item_type": ""},
						{"name": "structProp",    "type": "struct",    "item_type": ""},
						{"name": "uuidProp",      "type": "uuid",      "item_type": ""}
					]
				}
			},
			"*extended* properties test": {
				"args": {
					"cfc": new test_cfcs.ExtendsAndOverrides()
				},
				"expect": {
					"result": [
						{"name": "base1",    "type": "string",  "item_type": ""},
						{"name": "base2",    "type": "numeric", "item_type": ""},
						{"name": "extends1", "type": "string",  "item_type": ""},
						{"name": "extends2", "type": "string",  "item_type": ""}
					]
				}
			}
		];
		for ( var name in tests ) {
			var test = tests[name];
			// call method under test
			var result = variables.generator.getProperties(cfc = test.args.cfc);
			// check assertions
			AssertEquals(test.expect.result, result, "#name# - result doesn't match expected");
		}
	}

	/**
	* @hint "I test getPropertyCode."
	**/
	public void function test_getPropertyCode() {
		var tests = [
			"'any' property setter": {
				"property": {
					"name": "anyProp",
					"type": "any",
					"item_type": ""
				},
				"expect": '
					if ( StructKeyExists(arguments.data, "anyProp") && !IsNull(arguments.data["anyProp"]) ) {
						arguments.cfc.setanyProp(arguments.data["anyProp"]);
					}
				'
			},
			"'array' (no item_type) setter": {
				"property": {
					"name": "arrayProp",
					"type": "array",
					"item_type": ""
				},
				"expect": '
					if ( StructKeyExists(arguments.data, "arrayProp") && !IsNull(arguments.data["arrayProp"]) ) {
						arguments.cfc.setarrayProp(arguments.data["arrayProp"]);
					}
				'
			},
			"'array' (of item_type) setter": {
				"property": {
					"name": "optionsProp",
					"type": "array",
					"item_type": "test_cfcs.Option"
				},
				"expect": '
					if ( StructKeyExists(arguments.data, "optionsProp") && !IsNull(arguments.data["optionsProp"]) && IsArray(arguments.data["optionsProp"]) ) {
						var clean = [];
						var loader = getCfcLoader("test_cfcs.Option");
						for ( var item in arguments.data["optionsProp"] ) {
							if ( IsStruct(item) && !IsObject(item) ) {
								var vo = Duplicate(variables.vos["test_cfcs.Option"]);
								loader.load(cfc = vo, data = item);
								ArrayAppend(clean, vo);
							} else {
								ArrayAppend(clean, item);
							}
						}
						arguments.cfc.setoptionsProp(clean);
					}
				'
			},
			"'boolean' setter": {
				"property": {
					"name": "booleanProp",
					"type": "boolean",
					"item_type": ""
				},
				"expect": '
					if ( StructKeyExists(arguments.data, "booleanProp") && !IsNull(arguments.data["booleanProp"]) && IsValid("boolean", arguments.data["booleanProp"]) ) {
						arguments.cfc.setbooleanProp(arguments.data["booleanProp"] ? true : false);
					}
				'
			},
			"'component' (of item_type) setter": {
				"property": {
					"name": "optionProp",
					"type": "component",
					"item_type": "test_cfcs.Option"
				},
				"expect": '
					if ( StructKeyExists(arguments.data, "optionProp") && !IsNull(arguments.data["optionProp"]) ) {
						if ( IsStruct(arguments.data["optionProp"]) && !IsObject(arguments.data["optionProp"]) ) {
							var vo = Duplicate(variables.vos["test_cfcs.Option"]);
							getCfcLoader("test_cfcs.Option").load(cfc = vo, data = arguments.data["optionProp"]);
							arguments.cfc.setoptionProp(vo);
						} else {
							arguments.cfc.setoptionProp(arguments.data["optionProp"]);
						}
					}
				'
			},
			"'date' setter": {
				"property": {
					"name": "dateProp",
					"type": "date",
					"item_type": ""
				},
				"expect": '
					if ( StructKeyExists(arguments.data, "dateProp") && !IsNull(arguments.data["dateProp"]) && IsValid("date", arguments.data["dateProp"]) ) {
						arguments.cfc.setdateProp(arguments.data["dateProp"]);
					}
				'
			},
			"'guid' setter": {
				"property": {
					"name": "guidProp",
					"type": "guid",
					"item_type": ""
				},
				"expect": '
					if ( StructKeyExists(arguments.data, "guidProp") && !IsNull(arguments.data["guidProp"]) && IsValid("guid", arguments.data["guidProp"]) ) {
						arguments.cfc.setguidProp(arguments.data["guidProp"]);
					}
				'
			},
			"'numeric' setter": {
				"property": {
					"name": "numericProp",
					"type": "numeric",
					"item_type": ""
				},
				"expect": '
					if ( StructKeyExists(arguments.data, "numericProp") && !IsNull(arguments.data["numericProp"]) && IsValid("numeric", arguments.data["numericProp"]) ) {
						arguments.cfc.setnumericProp(arguments.data["numericProp"]);
					}
				'
			},
			"string setter": {
				"property": {
					"name": "stringProp",
					"type": "string",
					"item_type": ""
				},
				"expect": '
					if ( StructKeyExists(arguments.data, "stringProp") && !IsNull(arguments.data["stringProp"]) ) {
						arguments.cfc.setstringProp(arguments.data["stringProp"]);
					}
				'
			},
			"'uuid' setter": {
				"property": {
					"name": "uuidProp",
					"type": "uuid",
					"item_type": ""
				},
				"expect": '
					if ( StructKeyExists(arguments.data, "uuidProp") && !IsNull(arguments.data["uuidProp"]) && IsValid("uuid", arguments.data["uuidProp"]) ) {
						arguments.cfc.setuuidProp(arguments.data["uuidProp"]);
					}
				'
			}
		];
		MakePublic(variables.generator, "getPropertyCode");
		for ( var name in tests ) {
			var test = tests[name];
			// call method under test
			var result = variables.generator.getPropertyCode(property = test.property);
			// check assertions
			var trimIndentRegex = "(?m)^\s+";
			AssertEquals(
				ReReplace(Trim(test.expect), trimIndentRegex, "", "all"),
				ReReplace(Trim(result), trimIndentRegex, "", "all"),
				"#name# - result doesn't match expected"
			);
		}
	}

	/**
	* @hint "I test getSignature."
	**/
	public void function test_getSignature() {
		MakePublic(variables.generator, "getRecursiveCfcCode");
		InjectMethod(variables.generator, this, "getRecursiveCfcCodeMock", "getRecursiveCfcCode");
		// If the cfc (or any it extends) changes, we would need to generate a new loader.
		// We would also need to generate a new loader if the generator itself changed.
		// So, the signature of a generated loader is the hash of:
		// 	the code of the CFC (and all it extends)
		// 	+ the code of the generator
		var generatorCode = FileRead(GetMetaData(variables.generator).Path);
		var tests = [
			{
				"cfcName": "test_cfcs.Bundle",
				"expect": Hash("test_cfcs.Bundle" & generatorCode, "MD5")
			},
			{
				"cfcName": "test_cfcs.Option",
				"expect": Hash("test_cfcs.Option" & generatorCode, "MD5")
			}
		];
		for ( var test in tests ) {
			// set up mocks
			variables.generator["getRecursiveCfcCode_Args"] = [];
			variables.generator["getRecursiveCfcCode_Mock"] = test.cfcName;
			// call method under test
			var result = variables.generator.getSignature(cfcName = test.cfcName);
			// check assertions
			AssertEquals(test.expect, result, test.cfcName & " signature doesn't match");
		}
	}

	/**
	* @hint "I test getVoCacheCode."
	**/
	public void function test_getVoCacheCode() {
		var tests = [
			"no properties": {
				"properties": [],
				"expect": ""
			},
			"component property": {
				"properties": [
					{"name": "numericProp", "type": "numeric",   "item_type": ""},
					{"name": "optionProp",  "type": "component", "item_type": "testVo1"}
				],
				"expect": '
					variables.vos["testVo1"] = CreateObject("component", "testVo1");
				'
			},
			"array of components property": {
				"properties": [
					{"name": "optionsProp", "type": "array",   "item_type": "testVo2"},
					{"name": "numericProp", "type": "numeric", "item_type": ""}
				],
				"expect": '
					variables.vos["testVo2"] = CreateObject("component", "testVo2");
				'
			},
			"mix of arrays and single (with duplication)": {
				"properties": [
					{"name": "anotherProp", "type": "component", "item_type": "another"},
					{"name": "optionProp",  "type": "component", "item_type": "duplicates"},
					{"name": "optionsProp", "type": "array",     "item_type": "duplicates"},
					{"name": "numericProp", "type": "numeric",   "item_type": ""}
				],
				"expect": '
					variables.vos["another"] = CreateObject("component", "another");
					variables.vos["duplicates"] = CreateObject("component", "duplicates");
				'
			}
		];
		MakePublic(variables.generator, "getVoCacheCode");
		for ( var name in tests ) {
			var test = tests[name];
			// call method under test
			var result = variables.generator.getVoCacheCode(properties = test.properties);
			// check assertions
			var trimIndentRegex = "(?m)^\s+";
			AssertEquals(
				Trim(ReReplace(test.expect, trimIndentRegex, "", "all")),
				Trim(ReReplace(result, trimIndentRegex, "", "all")),
				"#name# - result doesn't match expected"
			);
		}
	}

	/* MOCKS */

	private string function getLoadMethodMock(required array properties) {
		ArrayAppend(this["getLoadMethod_Args"], arguments);
		return this["getLoadMethod_Mock"];
	}

	private array function getPropertiesMock(required component cfc) {
		ArrayAppend(this["getProperties_Args"], {"cfc": SerializeJson(arguments.cfc)});
		return this["getProperties_Mock"];
	}

	private string function getPropertyCodeMock(required struct property) {
		ArrayAppend(this["getPropertyCode_Args"], arguments);
		return this["getPropertyCode_Mock"];
	}

	private string function getRecursiveCfcCodeMock(required string cfcName) {
		ArrayAppend(this["getRecursiveCfcCode_Args"], arguments);
		return this["getRecursiveCfcCode_Mock"];
	}

	private string function getVoCacheCodeMock(required array properties) {
		ArrayAppend(this["getVoCacheCode_Args"], arguments);
		return this["getVoCacheCode_Mock"];
	}

}
