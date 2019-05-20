# cfc_loader

## Usage

If you want to have a property on a component populated with arrays of components,
you will need to use `item_type="path.to.cfc"` on your properties.

	// example component with a property that is an array of components
	component accessors=true {
		property name="id" type="numeric"; // basic
		property name="options" type="array" item_type="com.foo.Option"; // item_type meta data
	}

(It's unfortunate that ColdFusion has no way to document the types
of items in an array. But, it doesn't. ¯\\\_(ツ)\_/¯.)

### Example Code

	// You should cache your loader.
	// But, for this example, it is uncached.
	var loader = new com.github.cfchris.cfc_loader.loader();
	loader.setLoadersPath("com.generated.loaders");

	// Often data come as JSON from APIs
	var apiData = '{
		"id": 1,
		"name": "Benchmark Bundle",
		"widgets": [
			{"id": 1, "name": "Benchmark Widget 1"},
			{"id": 2, "name": "Benchmark Widget 2"}
		]
	}';

	// (option 1) Return a data component (populated from a raw API response)
	return loader.load(new test_cfcs.Bundle(), apiData);

	// (option 2) Return a data component (populated from a deserialized API response)
	return loader.load(new test_cfcs.Bundle(), DeserializeJson(apiData));

That's really it. The loader will handle generating and caching loaders.
Loaders are generated for each component with a name containing a "signature" hash.
If you add any properties to a component (_or_ any it extends _or_ even update this package),
it will automatically regenerate loader components as necessary.

## Why?

If you `SerializeJson()` structs and arrays in ColdFusion/CFML, you will get
inconsistent and undesirable results. (Type conversions, strings that can
convert to numbers missing quotes, etc)

If you use components with properties with correct types, you will get more
consistent `SerializeJson()` results. (And as a bonus, you have documented your API.)

Where I work we have been using components for a while that are nested types
with component properties, etc. We were loading them with a system where all
objects extend a BaseValueObject that contains a `loadFromStruct()` method that
dynamically and recursively loads the component and all of its children. But,
when we started using them for APIs that respond with deeply nested types, it
got very, very _slow_.

So, I wrote cfc_loader.

## License

Copyright (c) 2019 Chris Phillips and Contributors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
