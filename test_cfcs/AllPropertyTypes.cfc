component accessors=true {
	// CF property types
	// See https://helpx.adobe.com/coldfusion/cfml-reference/coldfusion-tags/tags-p-q/cfproperty.html
	property name="anyProp" type="any";
	property name="arrayProp" type="array";
	property name="binaryProp" type="binary";
	property name="booleanProp" type="boolean";
	property name="dateProp" type="date";
	property name="guidProp" type="guid";
	property name="numericProp" type="numeric";
	property name="queryProp" type="query";
	property name="stringProp" type="string";
	property name="structProp" type="struct";
	property name="uuidProp" type="uuid";
	property name="optionProp" type="test_cfcs.Option";
	// item_type custom attributes allows array properties to be loaded with arrays of CFCs of item_type
	property name="optionsProp" type="array" item_type="test_cfcs.Option";
}