# cfc_loader

## TL;DR

Where I work we had a way of loading nested sets of components from a struct
(often containing nested data). But, for large, deeply nested payloads it was
very, _very_ slow. (In one case, it took 1,300 ms to load deeply nested data.)

I wrote this package to recursively populate the properties of components
with data (usually deserialized JSON) in the fastest possible way I could 
manage.

With this package (and removing the inheritance of the old package), I was able
to reduce the time to load certain schema items by as much as __95%__.

The component that took 1,300 ms to load before can be loaded in about 70ms.

## How do I use it?

Create an instance of the loader and set the LoadersPath.

	// Plain old CFML
	var loader = new com.github.cfchris.cfc_loader.loader();
	loader.setLoadersPath("com.generated.loaders"); // directory should exist (probably with .gitignore on *.cfc)

	// ColdSpring
	<bean id="VoLoader" class="com.github.cfchris.cfc_loader.loader">
		<property name="LoadersPath"><value>com.generated.loaders</value></property>
	</bean>

Get a handle on the loader and use it to load a CFC with data.

	var response = new com.foo.bar();
	loader.load(response, data);
	return response;

That's really it. The loader will handle generating and caching loaders.
Loaders are generated for each component with a name containing a "signature" hash.
If you add any properties to a component (_or_ any it extends _or_ even update this package),
it will automatically regenerate loader components as necessary.

## Why?

If you `SerializeJson()` structs and arrays in ColdFusion/CFML, you will get
inconsistent and undesirable results. (Type conversions, strings that can
convert to numbers missing quotes, etc)

If you use components with properties with correct types, you will get more
consistent `SerializeJson()` results. (And as a bonus, you have documented you API.)

Where I work we have been using components for a while that are nested types
with component properties, etc. We were loading them with a system where all
objects extend a BaseValueObject that contains a `loadFromStruct()` method that
dynamically and recursively loads the component and all of its children. But,
when we started using them for APIs that respond with deeply nested types, it
got very, very _slow_.

I looked into the slowness and here are _a few_ of the issues that I found (and some solutions)

1. creating components from scratch in CF is slow (on the scale of thousands)
   1. make one component and `Duplicate()` it as needed
   2. cache the templates if possible
2. using `GetMetaData()` repeatedly is expensive
   1. use it sparingly and cache the result
3. dynamically looping over the incoming data (and dynamically finding/using setters) is expensive
   1. generate code that doesn't do this (it has conditionals that call setters directly)
4. basic functions calls (even simple getters) have some overhead
   1. generate code that caches things in structs and uses them directly

Based on that (and more experimenting), I wrote this library (cfc_loader).

It contains a generator that generates strings of code. The generator
accepts a component, determines all it's properties (including inheritance),
and generates a component that can load the components properties.

It also contains the loader that you will use in your code. The loader
is configured with a LoadersPath (e.g. com.generated.loaders). When asked
to load a component, it will determine if it already has a loader for that
component. If necessary, it will use the generator to generate a loader
for the component provided. Regardless, it will cache the generator for
subsequent use. Given there is a generated and cached loader, it will use
the loader specific to the provided component to load it with data. The
loader specific to the component provided, may have references to other
loaders to load properties with components or arrays of components. This
system ends up eventually recursively loading the components properties
with the values in the corresponding keys in the data provided.

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