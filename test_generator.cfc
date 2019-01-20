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

							// Cached loaders (populated in constructor)
							variables.loaders = {};

							// Template VOs
							variables.vos = {};
							// VO cache code 1

							public component function init(required loader loader) {
								variables.loader = arguments.loader;
								// micro-optimization: pre-cache a loader for each template VO
								for ( var key in variables.vos ) {
									if ( key == variables.componentToLoad ) {
										variables.loaders[key] = this;
									} else {
										variables.loaders[key] = variables.loader.getCfcLoader(variables.vos[key]);
									}
								}
								return this;
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

							// Cached loaders (populated in constructor)
							variables.loaders = {};

							// Template VOs
							variables.vos = {};
							// VO cache code 2

							public component function init(required loader loader) {
								variables.loader = arguments.loader;
								// micro-optimization: pre-cache a loader for each template VO
								for ( var key in variables.vos ) {
									if ( key == variables.componentToLoad ) {
										variables.loaders[key] = this;
									} else {
										variables.loaders[key] = variables.loader.getCfcLoader(variables.vos[key]);
									}
								}
								return this;
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
					"cfc": new test_cfcs.Extends2()
				},
				"expect": {
					"result": [
						{"name": "base1",    "type": "string", "item_type": ""},
						{"name": "base2",    "type": "string", "item_type": ""},
						{"name": "extends1", "type": "string", "item_type": ""},
						{"name": "extends2", "type": "string", "item_type": ""}
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
			"'boolean' setter": {
				"property": {
					"name": "booleanProp",
					"type": "boolean",
					"item_type": ""
				},
				"expect": '
					if ( StructKeyExists(arguments.data, "booleanProp") && !IsNull(arguments.data["booleanProp"]) ) {
						arguments.cfc.setbooleanProp(arguments.data["booleanProp"]);
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
						if ( IsStruct(arguments.data["optionProp"]) ) {
							var vo = Duplicate(variables.vos["test_cfcs.Option"]);
							variables.loaders["test_cfcs.Option"].load(cfc = vo, data = arguments.data["optionProp"]);
							arguments.cfc.setoptionProp(vo);
						} else {
							arguments.cfc.setoptionProp(arguments.data["optionProp"]);
						}
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
						for ( var item in arguments.data["optionsProp"] ) {
							if ( IsStruct(item) ) {
								var vo = Duplicate(variables.vos["test_cfcs.Option"]);
								variables.loaders["test_cfcs.Option"].load(cfc = vo, data = item);
								ArrayAppend(clean, vo);
							} else {
								ArrayAppend(clean, item);
							}
						}
						arguments.cfc.setoptionsProp(clean);
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
		MakePublic(variables.generator, "getProperties");
		InjectMethod(variables.generator, this, "getPropertiesMock", "getProperties");
		// If the cfc (or any it extends) changes, we would need to generate a new loader.
		// We would also need to generate a new loader if the generator itself changed.
		// So, the signature of a generated loader is the hash of:
		// 	the data container CFC's metadata
		// 	+ the actual code of the generator
		var generatorCode = FileRead(GetMetaData(variables.generator).Path);
		var tests = [
			{
				"cfc": "test_cfcs.Bundle",
				"expect": Hash(SerializeJson(["test_cfcs.Bundle"]) & generatorCode)
			},
			{
				"cfc": "test_cfcs.Option",
				"expect": Hash(SerializeJson(["test_cfcs.Option"]) & generatorCode)
			}
		];
		for ( var test in tests ) {
			// set up mocks
			variables.generator["getProperties_Args"] = [];
			variables.generator["getProperties_Mock"] = [test.cfc];
			// call method under test
			var result = variables.generator.getSignature(cfc = CreateObject("component", test.cfc));
			// check assertions
			AssertEquals(test.expect, result, test.cfc & " signature doesn't match");
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

	private string function getVoCacheCodeMock(required array properties) {
		ArrayAppend(this["getVoCacheCode_Args"], arguments);
		return this["getVoCacheCode_Mock"];
	}

}
