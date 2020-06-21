package graphql;

/**
 * The set of allowed kind values for AST nodes.
 */
enum abstract Kind(String) from String to String {
	// Name
	var NAME = 'Name';
	// Document
	var DOCUMENT = 'Document';
	var OPERATION_DEFINITION = 'OperationDefinition';
	var VARIABLE_DEFINITION = 'VariableDefinition';
	var SELECTION_SET = 'SelectionSet';
	var FIELD = 'Field';
	var ARGUMENT = 'Argument';
	// Fragments
	var FRAGMENT_SPREAD = 'FragmentSpread';
	var INLINE_FRAGMENT = 'InlineFragment';
	var FRAGMENT_DEFINITION = 'FragmentDefinition';
	// Values
	var VARIABLE = 'Variable';
	var INT = 'IntValue';
	var FLOAT = 'FloatValue';
	var STRING = 'StringValue';
	var BOOLEAN = 'BooleanValue';
	var NULL = 'NullValue';
	var ENUM = 'EnumValue';
	var LIST = 'ListValue';
	var OBJECT = 'ObjectValue';
	var OBJECT_FIELD = 'ObjectField';
	// Directives
	var DIRECTIVE = 'Directive';
	// Types
	var NAMED_TYPE = 'NamedType';
	var LIST_TYPE = 'ListType';
	var NON_NULL_TYPE = 'NonNullType';
	// Type System Definitions
	var SCHEMA_DEFINITION = 'SchemaDefinition';
	var OPERATION_TYPE_DEFINITION = 'OperationTypeDefinition';
	// Type Definitions
	var SCALAR_TYPE_DEFINITION = 'ScalarTypeDefinition';
	var OBJECT_TYPE_DEFINITION = 'ObjectTypeDefinition';
	var FIELD_DEFINITION = 'FieldDefinition';
	var INPUT_VALUE_DEFINITION = 'InputValueDefinition';
	var INTERFACE_TYPE_DEFINITION = 'InterfaceTypeDefinition';
	var UNION_TYPE_DEFINITION = 'UnionTypeDefinition';
	var ENUM_TYPE_DEFINITION = 'EnumTypeDefinition';
	var ENUM_VALUE_DEFINITION = 'EnumValueDefinition';
	var INPUT_OBJECT_TYPE_DEFINITION = 'InputObjectTypeDefinition';
	// Directive Definitions
	var DIRECTIVE_DEFINITION = 'DirectiveDefinition';
	// Type System Extensions
	var SCHEMA_EXTENSION = 'SchemaExtension';
	// Type Extensions
	var SCALAR_TYPE_EXTENSION = 'ScalarTypeExtension';
	var OBJECT_TYPE_EXTENSION = 'ObjectTypeExtension';
	var INTERFACE_TYPE_EXTENSION = 'InterfaceTypeExtension';
	var UNION_TYPE_EXTENSION = 'UnionTypeExtension';
	var ENUM_TYPE_EXTENSION = 'EnumTypeExtension';
	var INPUT_OBJECT_TYPE_EXTENSION = 'InputObjectTypeExtension';
}
