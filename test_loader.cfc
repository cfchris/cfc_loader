component extends="mxunit.framework.TestCase" {

	/*
		run tests:
			/cfc_loader/test_loader.cfc?method=runtestremote&output=html
	*/

	variables.tempLoadersPath = "test_generated_" & GetTickCount();

	/* this will run before every single test in this test case */
	public void function setUp() {
		variables.loader = new loader();
		variables.loader.setLoadersPath(variables.tempLoadersPath);
	}

	/* this will run after every single test in this test case */
	public void function tearDown() {}

	/* this will run once after initialization and before setUp() */
	public void function beforeTests() {
		if ( !DirectoryExists(ExpandPath(variables.tempLoadersPath)) ) {
			DirectoryCreate(ExpandPath(variables.tempLoadersPath));
		}
	}

	/* this will run once after all tests have been run */
	public void function afterTests() {
		if ( DirectoryExists(ExpandPath(variables.tempLoadersPath)) ) {
			// comment this out if you want to see generated CFCs
			DirectoryDelete(ExpandPath(variables.tempLoadersPath), true);
		}
	}

	/*
	* TESTS
	*/

	/**
	* @hint "I test getCfcLoader."
	**/
	public void function test_getCfcLoader() {
		variables.loader.setLoadersPath("test_loaders");
		var tests = [
			"Bundle loader (exists: no generate) (use cfcName)": {
				"args": {
					"cfc": new test_cfcs.Bundle().setId(1),
					"cfcName": "test_cfcs.Bundle"
				},
				"mocks": {
					"getCfcName": "test_cfcs.Bundle",
					"getCfcLoaderName": "test_loaders.test_cfcs_Bundle",
					"loaderExists": true,
					"generator.generate": "N/A"
				},
				"expect": {
					"calls": {
						"getCfcName": [], // arg cfcName skips getCfcName(), thus skipping GetMetaData(cfc).name
						"getCfcLoaderName": [
							{
								"cfc": SerializeJson(new test_cfcs.Bundle().setId(1)),
								"cfcName": "test_cfcs.Bundle"
							}
						],
						"loaderExists": [
							{"cfcName": "test_loaders.test_cfcs_Bundle"}
						],
						"generator.generate": [], // exists, so no generation
						"writeLoader": []         // exists, so no generation
					},
					"returnType": "test_loaders.test_cfcs_Bundle"
				}
			},
			"Bundle loader (exists: no generate)": {
				"args": {
					"cfc": new test_cfcs.Bundle().setId(1)
				},
				"mocks": {
					"getCfcName": "test_cfcs.Bundle",
					"getCfcLoaderName": "test_loaders.test_cfcs_Bundle",
					"loaderExists": true,
					"generator.generate": "N/A"
				},
				"expect": {
					"calls": {
						"getCfcName": [
							{"cfc": SerializeJson(new test_cfcs.Bundle().setId(1))},
							{"cfc": SerializeJson(new test_cfcs.Bundle().setId(1))}
						],
						"getCfcLoaderName": [
							{
								"cfc": SerializeJson(new test_cfcs.Bundle().setId(1)),
								"cfcName": "test_cfcs.Bundle"
							}
						],
						"loaderExists": [
							{"cfcName": "test_loaders.test_cfcs_Bundle"}
						],
						"generator.generate": [], // exists, so no generation
						"writeLoader": []         // exists, so no generation
					},
					"returnType": "test_loaders.test_cfcs_Bundle"
				}
			},
			"Option loader (!exists: generate)": {
				"args": {
					"cfc": new test_cfcs.Option().setId(2)
				},
				"mocks": {
					"getCfcName": "test_cfcs.Option",
					"getCfcLoaderName": "test_loaders.test_cfcs_Option",
					"loaderExists": false,
					"generator.generate": "option loader code"
				},
				"expect": {
					"calls": {
						"getCfcName": [
							{"cfc": SerializeJson(new test_cfcs.Option().setId(2))},
							{"cfc": SerializeJson(new test_cfcs.Option().setId(2))}
						],
						"getCfcLoaderName": [
							{
								"cfc": SerializeJson(new test_cfcs.Option().setId(2)),
								"cfcName": "test_cfcs.Option"
							}
						],
						"loaderExists": [
							{"cfcName": "test_loaders.test_cfcs_Option"}
						],
						"generator.generate": [
							{"cfc": SerializeJson(new test_cfcs.Option().setId(2))}
						],
						"writeLoader": [
							{"cfcName": "test_loaders.test_cfcs_Option", "code": "option loader code"}
						]
					},
					"returnType": "test_loaders.test_cfcs_Option"
				}
			}
		];
		MakePublic(variables.loader, "getCfcName");
		InjectMethod(variables.loader, this, "getCfcNameMock", "getCfcName");
		MakePublic(variables.loader, "getCfcLoaderName");
		InjectMethod(variables.loader, this, "getCfcLoaderNameMock", "getCfcLoaderName");
		MakePublic(variables.loader, "loaderExists");
		InjectMethod(variables.loader, this, "loaderExistsMock", "loaderExists");
		MakePublic(variables.loader, "writeLoader");
		InjectMethod(variables.loader, this, "writeLoaderMock", "writeLoader");
		for ( var name in tests ) {
			var test = tests[name];
			// reset calls and mocks
			var calls = {
				"getCfcName": [],
				"getCfcLoaderName": [],
				"loaderExists": [],
				"generator.generate": [],
				"writeLoader": []
			};
			variables.loader["getCfcName_Mock"] = test.mocks.getCfcName;
			variables.loader["getCfcName_Args"] = [];
			variables.loader["getCfcLoaderName_Mock"] = test.mocks.getCfcLoaderName;
			variables.loader["getCfcLoaderName_Args"] = [];
			variables.loader["loaderExists_Mock"] = test.mocks.loaderExists;
			variables.loader["loaderExists_Args"] = [];
			variables.loader["writeLoader_Args"] = [];
			var generatorMock = new test_cfcs.Blank();
			generatorMock.generate = function(required component cfc) {
				ArrayAppend(calls["generator.generate"], {"cfc": SerializeJson(arguments.cfc)});
				var mocks = Duplicate(test.mocks);
				return mocks["generator.generate"];
			};
			variables.loader.setGenerator(generatorMock);
			// clear loader cache between tests
			variables.loader.clearLoaderCache();
			// call method under test (more than once to ensure caching)
			var result = variables.loader.getCfcLoader(argumentCollection = test.args);
			var result = variables.loader.getCfcLoader(argumentCollection = test.args);
			// check assertions
			calls["getCfcName"] = variables.loader["getCfcName_Args"];
			calls["getCfcLoaderName"] = variables.loader["getCfcLoaderName_Args"];
			calls["loaderExists"] = variables.loader["loaderExists_Args"];
			calls["writeLoader"] = variables.loader["writeLoader_Args"];
			AssertEquals(test.expect.calls, calls, "#name# - calls don't match expected");
			AssertTrue(IsInstanceOf(result, test.expect.returnType), "#name# - response not of expected type");
		}
	}

	/**
	* @hint "I test getCfcLoaderName."
	**/
	public void function test_getCfcLoaderName() {
		MakePublic(variables.loader, "getCfcLoaderName");
		variables.loader.setLoadersPath("test_loaders");
		var tests = [
			"test one": {
				"args": {
					"cfc": new test_cfcs.Bundle().setId(1)
				},
				"mocks": {
					"getCfcName": "foo.bar.baz",
					"generator.getSignature": "signature1"
				},
				"expect": {
					"calls": {
						"getCfcName": [
							{"cfc": SerializeJson(new test_cfcs.Bundle().setId(1))}
						],
						"generator.getSignature": [
							{"cfcName": "foo.bar.baz"}
						]
					},
					"result": "test_loaders.foo_bar_baz_signature1"
				}
			},
			"test two": {
				"args": {
					"cfc": new test_cfcs.Option().setId(2)
				},
				"mocks": {
					"getCfcName": "foo.bar_baz.qux",
					"generator.getSignature": "signature2"
				},
				"expect": {
					"calls": {
						"getCfcName": [
							{"cfc": SerializeJson(new test_cfcs.Option().setId(2))}
						],
						"generator.getSignature": [
							{"cfcName": "foo.bar_baz.qux"}
						]
					},
					"result": "test_loaders.foo_bar__baz_qux_signature2" // double underscore to disambiguate directory dots being replaced by _
				}
			},
			"test three (use cfcName)": {
				"args": {
					"cfc": new test_cfcs.Option().setId(2),
					"cfcName": "test_cfcs.Option"
				},
				"mocks": {
					"getCfcName": "N/A",
					"generator.getSignature": "signature2"
				},
				"expect": {
					"calls": {
						"getCfcName": [], // arg cfcName skips getCfcName(), thus skipping GetMetaData(cfc).name
						"generator.getSignature": [
							{"cfcName": "test_cfcs.Option"}
						]
					},
					"result": "test_loaders.test__cfcs_option_signature2" // double underscore to disambiguate directory dots being replaced by _
				}
			}
		];
		MakePublic(variables.loader, "getCfcName");
		InjectMethod(variables.loader, this, "getCfcNameMock", "getCfcName");
		for ( var name in tests ) {
			var test = tests[name];
			// reset calls and mocks
			var calls = {
				"getCfcName": [],
				"generator.getSignature": []
			};
			variables.loader["getCfcName_Mock"] = test.mocks.getCfcName;
			variables.loader["getCfcName_Args"] = [];
			var mockGenerator = new test_cfcs.Blank();
			mockGenerator.getSignature = function(required string cfcName) {
				ArrayAppend(calls["generator.getSignature"], {"cfcName": arguments.cfcName});
				var mocks = Duplicate(test.mocks);
				return mocks["generator.getSignature"];
			};
			variables.loader.setGenerator(mockGenerator);
			// call method under test
			var result = variables.loader.getCfcLoaderName(argumentCollection = test.args);
			// check assertions
			calls["getCfcName"] = variables.loader["getCfcName_Args"];
			AssertEquals(test.expect.calls, calls, "#name# - calls don't match expected");
			AssertEquals(test.expect.result, result, "#name# failed");
		}
	}

	/**
	* @hint "I test getCfcName."
	**/
	public void function test_getCfcName() {
		MakePublic(variables.loader, "getCfcName");
		var tests = [
			"Bundle path": {
				"cfc": new test_cfcs.Bundle(),
				"expect": "test_cfcs.Bundle"
			},
			"Option path": {
				"cfc": new test_cfcs.Option(),
				"expect": "test_cfcs.Option"
			}
		];
		for ( var name in tests ) {
			var test = tests[name];
			// call method under test
			var result = variables.loader.getCfcName(test.cfc);
			// check assertions
			AssertEquals(test.expect, result, "#name# - result doesn't match expected");
		}
	}

	/**
	* @hint "I test load (for speed)."
	**/
	public void function test_load_benchmark() {
		// NOTE
		// This test could fail (be too slow) on different hardware/OS/etc combinations.
		// I'm aware of this.
		// I'll adjust this as necessary.
		var data = {
			"id": 1,
			"name": "Benchmark Bundle",
			"widgets": [
				{
					"id": 1,
					"name": "Benchmark Widget 1",
					"options": [
						{"id": 1, "name": "Benchmark Option 1"},
						{"id": 2, "name": "Benchmark Option 2"}
					],
					"isInBundles": [
						{"id": 1, "Name": "Benchmark Bundle"},
						{"id": 7, "Name": "Some Other Bundle"}
					]
				},
				{
					"id": 2,
					"name": "Benchmark Widget 2",
					"options": [
						{"id": 3, "name": "Benchmark Option 3"},
						{"id": 4, "name": "Benchmark Option 4"}
					],
					"isInBundles": [
						{"id": 1,  "Name": "Benchmark Bundle"},
						{"id": 42, "Name": "Yet Another Bundle"}
					]
				}
			]
		};
		var loopCount = 1000;
		// note the time
		var startTime = GetTickCount();
		// make sure loader is working (also warms loader by generating and caching required sub-loaders)
		AssertEquals(
			DeserializeJson(SerializeJson(data)),
			DeserializeJson(SerializeJson(variables.loader.load(
				cfcName = "test_cfcs.Bundle",
				cfc = new test_cfcs.Bundle(),
				data = data
			))),
			"start - loader failure (bundle doesn't match source data)"
		);
		// load a bunch of bundles nested 3 levels deep (i.e. bundle > widget[] > bundle[])
		for ( var i = 0; i < loopCount; i++ ) {
			var bundle = variables.loader.load(
				cfcName = "test_cfcs.Bundle",
				cfc = new test_cfcs.Bundle(),
				data = data
			);
		}
		// figure out how long it took
		var elapsedTime = GetTickCount() - startTime;
		// make sure the CFCs were being completely loaded (sanity check)
		AssertEquals(
			DeserializeJson(SerializeJson(data)),
			DeserializeJson(SerializeJson(bundle)),
			"finished - loader failure (bundle doesn't match source data)"
		);
		// "baseline" stats from 2019-02-01
		var baseline = [
			"elapsed ms": 210,
			"loop count": 1000,
			"avg load() ms": 0.21
		];
		// stats for the current run
		var stats = [
			"elapsed ms": elapsedTime,
			"loop count": loopCount,
			"avg load() ms": elapsedTime / loopCount
		];
		// display stats when run in debug
		debug([
			"baseline": baseline,
			"current": stats
		]);
		// have we drastically exceeded previous benchmarks? (see var baseline above)
		AssertTrue(
			stats["elapsed ms"] < (3 * baseline["elapsed ms"]),
			"load time has more than tripled since benchmark was established"
		);
	}

	/**
	* @hint "I test load (with generation)."
	**/
	public void function test_load_integration() {
		var tests = [
			"test Widget (data is just structs/arrays)": {
				"args": {
					"cfc": new test_cfcs.Widget(),
					"data": {
						"id": 1,
						"isOnSpecial": "",
						"name": "structs/arrays",
						"options": [
							{"id": 1, "name": "Option 1"},
							{"id": 2, "name": "Option 2"}
						]
					}
				},
				"expect": {
					"returnType": "test_cfcs.Widget",
					"serialized": {
						"id": 1,
						"name": "structs/arrays",
						"options": [
							{"id": 1, "name": "Option 1"},
							{"id": 2, "name": "Option 2"}
						]
					}
				}
			},
			"test Widget (data has items of item_type)": {
				"args": {
					"cfc": new test_cfcs.Widget(),
					"data": {
						"id": 2,
						"name": "items of item_type",
						"options": [
							new test_cfcs.Option().setId(3).setName("Option 3"),
							new test_cfcs.Option().setId(4).setName("Option 4")
						]
					}
				},
				"expect": {
					"returnType": "test_cfcs.Widget",
					"serialized": {
						"id": 2,
						"name": "items of item_type",
						"options": [
							{"id": 3, "name": "Option 3"},
							{"id": 4, "name": "Option 4"}
						]
					}
				}
			}
		];
		for ( var dataType in ["json", "struct"] ) {
			for ( var name in tests ) {
				var test = tests[name];
				if ( dataType == "json" ) {
					test.args.data = SerializeJson(test.args.data);
				}
				// call method under test
				var result = variables.loader.load(
					cfc = test.args.cfc,
					data = test.args.data
				);
				// check assertions
				AssertEquals(test.expect.returnType, GetMetaData(result).name, "(data:#dataType#) #name# - return type doesn't match expected");
				AssertEquals(
					test.expect.serialized,
					DeserializeJson(SerializeJson(result)),
					"(data:#dataType#) #name# - result did not contain expected data"
				);
			}
		}
	}

	/**
	* @hint "I test load."
	**/
	public void function test_load() {
		var tests = [
			"test Option (1)": {
				"args": {
					"cfc": new test_cfcs.Option().setId(1),
					"data": {name: "Option 1"}
				},
				"expect": {
					"calls": {
						"getCfcLoader": [{
							"cfcName": "",
							"cfc": SerializeJson(new test_cfcs.Option().setId(1))
						}],
						"cfcLoader.load": {
							"cfc": SerializeJson(new test_cfcs.Option().setId(1)),
							"data": {name: "Option 1"}
						}
					},
					"returnType": "test_cfcs.Option"
				}
			},
			"test Widget (2)": {
				"args": {
					"cfc": new test_cfcs.Widget().setId(2),
					"data": {name: "Widget 2"}
				},
				"expect": {
					"calls": {
						"getCfcLoader": [{
							"cfcName": "",
							"cfc": SerializeJson(new test_cfcs.Widget().setId(2))
						}],
						"cfcLoader.load": {
							"cfc": SerializeJson(new test_cfcs.Widget().setId(2)),
							"data": {name: "Widget 2"}
						}
					},
					"returnType": "test_cfcs.Widget"
				}
			},
			"test Widget (with cfcName)": {
				"args": {
					"cfcName": "test_cfcs.Widget",
					"cfc": new test_cfcs.Widget().setId(2),
					"data": {name: "Widget 2"}
				},
				"expect": {
					"calls": {
						"getCfcLoader": [{
							"cfcName": "test_cfcs.Widget",
							"cfc": SerializeJson(new test_cfcs.Widget().setId(2))
						}],
						"cfcLoader.load": {
							"cfc": SerializeJson(new test_cfcs.Widget().setId(2)),
							"data": {name: "Widget 2"}
						}
					},
					"returnType": "test_cfcs.Widget"
				}
			}
		];
		MakePublic(variables.loader, "getCfcLoader");
		InjectMethod(variables.loader, this, "getCfcLoaderMock", "getCfcLoader");
		for ( var name in tests ) {
			var test = tests[name];
			// reset calls and mocks
			var calls = {
				"getCfcLoader": [],
				"cfcLoader.load": {}
			};
			var loaderMock = new test_cfcs.Blank();
			loaderMock.load = function(
				required component cfc,
				required struct data,
				string cfcName = ""
			) {
				calls["cfcLoader.load"] = {
					"cfc": SerializeJson(arguments.cfc),
					"data": arguments.data
				};
			};
			variables.loader["getCfcLoader_Mock"] = loaderMock;
			variables.loader["getCfcLoader_Args"] = [];
			// call method under test
			var result = variables.loader.load(argumentCollection = test.args);
			// check assertions
			calls["getCfcLoader"] = variables.loader["getCfcLoader_Args"];
			AssertEquals(test.expect.calls, calls, "<br>#name# - calls don't match expected");
			AssertEquals(test.expect.returnType, GetMetaData(result).name, "<br>#name# - return type doesn't match expected");
		}
	}

	/**
	* @hint "I test loaderExists."
	**/
	public void function test_loaderExists() {
		MakePublic(variables.loader, "loaderExists");
		var tests = [
			"loader exists (returns true)": {
				"args": {
					"loaderName": "test_loaders.test_cfcs_Bundle"
				},
				"expect": {
					"result": true
				}
			},
			"loader doesn't exist (returns false)": {
				"args": {
					"loaderName": "test_loaders.does_not_exist"
				},
				"expect": {
					"result": false
				}
			}
		];
		for ( var name in tests ) {
			var test = tests[name];
			// call method under test
			var result = variables.loader.loaderExists(cfcName = test.args.loaderName);
			// check assertions
			AssertEquals(test.expect.result, result, "#name# - result doesn't match expected");
		}
	}

	/**
	* @hint "I test writeLoader."
	**/
	public void function test_writeLoader() {
		MakePublic(variables.loader, "writeLoader");
		var tests = [
			"test one": {
				"args": {
					"cfcName": variables.tempLoadersPath & ".writeLoader_test_one",
					"code": "write loader test one"
				}
			},
			"test two": {
				"args": {
					"cfcName": variables.tempLoadersPath & ".writeLoader_test_two",
					"code": "write loader test two"
				}
			}
		];
		for ( var name in tests ) {
			var test = tests[name];
			// call method under test
			var result = variables.loader.writeLoader(
				cfcName = test.args.cfcName,
				code = test.args.code
			);
			// check assertions
			var filePath = ExpandPath("/" & Replace(test.args.cfcName, ".", "/", "all") & ".cfc");
			AssertTrue(FileExists(filePath), "#name# - file missing");
			AssertEquals(test.args.code, FileRead(filePath), "#name# - file content wrong");
		}
	}

	/* MOCKS */

	private component function getCfcLoaderMock(required component cfc, string cfcName) {
		ArrayAppend(
			this["getCfcLoader_Args"],
			{
				"cfc": SerializeJson(arguments.cfc),
				"cfcName": arguments.cfcName
			}
		);
		return this["getCfcLoader_Mock"];
	}

	private string function getCfcLoaderNameMock(required component cfc, string cfcName) {
		var args = {};
		if ( StructKeyExists(arguments, "cfcName") && Len(arguments.cfcName) > 0 ) {
			args["cfcName"] = arguments.cfcName;
		}
		args.cfc = SerializeJson(arguments.cfc);
		ArrayAppend(this["getCfcLoaderName_Args"], args);
		return this["getCfcLoaderName_Mock"];
	}

	private string function getCfcNameMock(required component cfc) {
		ArrayAppend(this["getCfcName_Args"], {"cfc": SerializeJson(arguments.cfc)});
		return this["getCfcName_Mock"];
	}

	private boolean function loaderExistsMock(required string cfcName) {
		ArrayAppend(this["loaderExists_Args"], arguments);
		return this["loaderExists_Mock"];
	}

	private void function writeLoaderMock(
		required string cfcName,
		required string code
	) {
		ArrayAppend(this["writeLoader_Args"], arguments);
	}
}
