package graphql.parser;

/**
 * The set of allowed directive location values.
 */
enum abstract DirectiveLocation(String) from String to String {
 // Request Definitions
 var QUERY= 'QUERY';
 var MUTATION= 'MUTATION';
 var SUBSCRIPTION= 'SUBSCRIPTION';
 var FIELD= 'FIELD';
 var FRAGMENT_DEFINITION= 'FRAGMENT_DEFINITION';
 var FRAGMENT_SPREAD= 'FRAGMENT_SPREAD';
 var INLINE_FRAGMENT= 'INLINE_FRAGMENT';
 var VARIABLE_DEFINITION= 'VARIABLE_DEFINITION';
 // Type System Definitions
 var SCHEMA= 'SCHEMA';
 var SCALAR= 'SCALAR';
 var OBJECT= 'OBJECT';
 var FIELD_DEFINITION= 'FIELD_DEFINITION';
 var ARGUMENT_DEFINITION= 'ARGUMENT_DEFINITION';
 var INTERFACE= 'INTERFACE';
 var UNION= 'UNION';
 var ENUM= 'ENUM';
 var ENUM_VALUE= 'ENUM_VALUE';
 var INPUT_OBJECT= 'INPUT_OBJECT';
 var INPUT_FIELD_DEFINITION= 'INPUT_FIELD_DEFINITION';

}