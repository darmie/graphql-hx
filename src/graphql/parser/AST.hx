package graphql.parser;

import haxe.ds.ReadOnlyArray;
import graphql.parser.TokenEnum;

/**
 * Contains a range of UTF-8 character offsets and token references that
 * identify the region of the source from which the AST derived.
 */
typedef TLocation = {
	/**
	 * The character offset at which this Node begins.
	 */
	@:optional var start:Int;

	/**
	 * The character offset at which this Node ends.
	 */
	 @:optional var end:Int;

	/**
	 * The Token at which this Node begins.
	 */
	 @:optional var startToken:Token;

	/**
	 * The Token at which this Node ends.
	 */
	 @:optional var endToken:Token;

	/**
	 * The Source document the AST represents.
	 */
	 @:optional var source:Source;
}
@:forward(startToken, endToken, start, end, source)
abstract Location(TLocation) from TLocation to TLocation {
	public inline function new(startToken:Token, endToken:Token, source:Source) {
		this = {
			startToken: startToken,
			endToken: endToken,
			source: source
		};
	}
}

typedef TToken = {
	/**
	 * The kind of Token.
	 */
	var kind:TokenEnum;

	/**
	 * The character offset at which this Node begins.
	 */
	var start:Int;

	/**
	 * The character offset at which this Node ends.
	 */
	var end:Int;

	/**
	 * The 1-indexed line number on which this Token appears.
	 */
	var line:Int;

	/**
	 * The 1-indexed column number at which this Token begins.
	 */
	var column:Int;

	/**
	 * For non-punctuation tokens, represents the interpreted value of the token.
	 */
	var ?value:String;

	/**
	 * Tokens exist as nodes in a double-linked-list amongst all tokens
	 * including ignored tokens. <SOF> is always the first node and <EOF>
	 * the last.
	 */
	var ?prev:Token;

	var ?next:Token;
}

@:forward(kind, start, end, line, column, prev, next, value)
abstract Token(TToken) from TToken to TToken {
	public inline function new(kind:TokenEnum, start:Int, end:Int, line:Int, column:Int, prev:Token, ?value:String) {
		this = {
			kind: kind,
			start: start,
			end: end,
			line: line,
			column: column,
			prev: prev,
			value: value
		};
	}
}

/**
 * AST Node types
 */
typedef ASTNode = {
	?kind:Kind,
	?loc:Location
}

typedef ASTKindToNode = {
	Name:NameNode,
	Document:DocumentNode,
	OperationDefinition:OperationDefinitionNode,
	VariableDefinition:VariableDefinitionNode,
	Variable:VariableNode,
	SelectionSet:SelectionSetNode,
	Field:FieldNode,
	Argument:ArgumentNode,
	FragmentSpread:FragmentSpreadNode,
	InlineFragment:InlineFragmentNode,
	FragmentDefinition:FragmentDefinitionNode,
	IntValue:IntValueNode,
	FloatValue:FloatValueNode,
	StringValue:StringValueNode,
	BooleanValue:BooleanValueNode,
	NullValue:NullValueNode,
	EnumValue:EnumValueNode,
	ListValue:ListValueNode,
	ObjectValue:ObjectValueNode,
	ObjectField:ObjectFieldNode,
	Directive:DirectiveNode,
	NamedType:NamedTypeNode,
	ListType:ListTypeNode,
	NonNullType:NonNullTypeNode,
	SchemaDefinition:SchemaDefinitionNode,
	OperationTypeDefinition:OperationTypeDefinitionNode,
	ScalarTypeDefinition:ScalarTypeDefinitionNode,
	ObjectTypeDefinition:ObjectTypeDefinitionNode,
	FieldDefinition:FieldDefinitionNode,
	InputValueDefinition:InputValueDefinitionNode,
	InterfaceTypeDefinition:InterfaceTypeDefinitionNode,
	UnionTypeDefinition:UnionTypeDefinitionNode,
	EnumTypeDefinition:EnumTypeDefinitionNode,
	EnumValueDefinition:EnumValueDefinitionNode,
	InputObjectTypeDefinition:InputObjectTypeDefinitionNode,
	DirectiveDefinition:DirectiveDefinitionNode,
	SchemaExtension:SchemaExtensionNode,
	ScalarTypeExtension:ScalarTypeExtensionNode,
	ObjectTypeExtension:ObjectTypeExtensionNode,
	InterfaceTypeExtension:InterfaceTypeExtensionNode,
	UnionTypeExtension:UnionTypeExtensionNode,
	EnumTypeExtension:EnumTypeExtensionNode,
	InputObjectTypeExtension:InputObjectTypeExtensionNode
}

typedef TNameNode = {
	> ASTNode,
	value:String
}

/**
 * Name
 */
@:forward(kind, loc, value)
abstract NameNode(TNameNode) from TNameNode to TNameNode {
	inline function new(n:TNameNode) {
		this = n;
		this.kind = "Name";
	}
}

typedef TDocumentNode = {
	> ASTNode,
	definitions:ReadOnlyArray<DefinitionNode>
}

/**
 * Document
 */
@:forward(kind, loc, value, definitions)
abstract DocumentNode(TDocumentNode) from TDocumentNode to TDocumentNode {
	inline function new(n:TDocumentNode) {
		this = n;
		this.kind = "Document";
	}
}

typedef DefinitionNode = {
	> ASTNode,
}

typedef ExecutableDefinitionNode = {
	> DefinitionNode,
	?operation:OperationTypeNode,
	?name:NameNode,
	?variableDefinitions:ReadOnlyArray<VariableDefinitionNode>,
	?directives:ReadOnlyArray<DirectiveNode>,
	selectionSet:SelectionSetNode,
}

typedef TOperationDefinitionNode = {
	> ExecutableDefinitionNode,
}

@:forward(kind, loc, name, operation, variableDefinitions, directives, selectionSet)
abstract OperationDefinitionNode(TOperationDefinitionNode) from TOperationDefinitionNode to TOperationDefinitionNode {
	inline function new(n:TOperationDefinitionNode) {
		this = n;
		this.kind = 'OperationDefinition';
	}
}

enum abstract OperationTypeNode(String) from String to String {
	var QUERY = "query";
	var MUTATION = "mutation";
	var SUBSCRIPTION = "subscription";
}

typedef TVariableDefinitionNode = {
	> ASTNode,
	variable:VariableNode,
	type:TypeNode,
	?defaultValue:ValueNode,
	?directives:ReadOnlyArray<DirectiveNode>,
}

@:forward(kind, loc, variable, defaultValue, directives)
abstract VariableDefinitionNode(TVariableDefinitionNode) from TVariableDefinitionNode to TVariableDefinitionNode {
	inline function new(n:TVariableDefinitionNode) {
		this = n;
		this.kind = 'VariableDefinition';
	}
}

typedef TVariableNode = {
	> ASTNode,
	name:NameNode,
}

@:forward(kind, loc, name)
abstract VariableNode(TVariableNode) from TVariableNode to TVariableNode {
	inline function new(n:TVariableNode) {
		this = n;
		this.kind = 'Variable';
	}
}

typedef TSelectionSetNode = {
	> ASTNode,
	selections:ReadOnlyArray<SelectionNode>,
}

@:forward(kind, loc, selections)
abstract SelectionSetNode(TSelectionSetNode) from TSelectionSetNode to TSelectionSetNode {
	inline function new(n:TSelectionSetNode) {
		this = n;
		this.kind = 'SelectionSet';
	}
}

typedef SelectionNode = {
	> ASTNode,
	directives:ReadOnlyArray<DirectiveNode>
}

typedef TFieldNode = {
	> SelectionNode,
	?alias:NameNode,
	name:NameNode,
	?arguments:ReadOnlyArray<ArgumentNode>,
	?selectionSet:SelectionSetNode,
}

@:forward(kind, loc, directives, name, alias, arguments, selectionSet)
abstract FieldNode(TFieldNode) from TFieldNode to TFieldNode {
	inline function new(n:TFieldNode) {
		this = n;
		this.kind = "Field";
	}
}

typedef TArgumentNode = {
	> ASTNode,
	name:NameNode,
	value:ValueNode
}

@:forward(kind, loc, name, value)
abstract ArgumentNode(TArgumentNode) from TArgumentNode to TArgumentNode {
	inline function new(n:TArgumentNode) {
		this = n;
		this.kind = "Argument";
	}
}

typedef TFragmentSpreadNode = {
	> SelectionNode,
	name:NameNode,
}

@:forward(kind, loc, directives, name)
abstract FragmentSpreadNode(TFragmentSpreadNode) from TFragmentSpreadNode to TFragmentSpreadNode {
	inline function new(n:TFragmentSpreadNode) {
		this = n;
		this.kind = "FragmentSpread";
	}
}

typedef TInlineFragmentNode = {
	> SelectionNode,
	?typeCondition:NamedTypeNode,
	selectionSet:SelectionSetNode
}

@:forward(kind, loc, directives, name, typeCondition, selectionSet)
abstract InlineFragmentNode(TInlineFragmentNode) from TInlineFragmentNode to TInlineFragmentNode {
	inline function new(n:TInlineFragmentNode) {
		this = n;
		this.kind = "InlineFragment";
	}
}

typedef TFragmentDefinitionNode = {
	> ExecutableDefinitionNode,
	typeCondition:NamedTypeNode
}

@:forward(kind, loc, name, operation, variableDefinitions, directives, selectionSet, typeCondition)
abstract FragmentDefinitionNode(TFragmentDefinitionNode) from TFragmentDefinitionNode to TFragmentDefinitionNode {
	inline function new(n:TFragmentDefinitionNode) {
		this = n;
		this.kind = 'FragmentDefinition';
	}
}

typedef ValueNode = {
	> ASTNode,
	?value:Dynamic
}

@:forward(kind, loc, value)
abstract IntValueNode(ValueNode) from ValueNode to ValueNode {
	inline function new(n:ValueNode) {
		this = n;
		this.kind = "IntValue";
	}
}

@:forward(kind, loc, value)
abstract FloatValueNode(ValueNode) from ValueNode to ValueNode {
	inline function new(n:ValueNode) {
		this = n;
		this.kind = "FloatValue";
	}
}

@:forward(kind, loc, value)
abstract BooleanValueNode(ValueNode) from ValueNode to ValueNode {
	inline function new(n:ValueNode) {
		this = n;
		this.kind = "BooleanValue";
	}
}

@:forward(kind, loc)
abstract NullValueNode(ValueNode) from ValueNode to ValueNode {
	inline function new(n:ValueNode) {
		this = n;
		this.kind = "NullValue";
	}
}

@:forward(kind, loc, value)
abstract EnumValueNode(ValueNode) from ValueNode to ValueNode {
	inline function new(n:ValueNode) {
		this = n;
		this.kind = "EnumValue";
	}
}

typedef TStringValueNode = {
	> ValueNode,
	?block:Bool
}

@:forward(kind, loc, value, block)
abstract StringValueNode(TStringValueNode) from TStringValueNode to TStringValueNode {
	inline function new(n:TStringValueNode) {
		this = n;
		this.kind = "StringValue";
	}
}

typedef TListValueNode = {
	> ValueNode,
	values:ReadOnlyArray<ValueNode>
}

@:forward(kind, loc, values)
abstract ListValueNode(TListValueNode) from TListValueNode to TListValueNode {
	inline function new(n:TListValueNode) {
		this = n;
		this.kind = "ListValue";
	}
}

typedef TObjectValueNode = {
	> ValueNode,
	fields:ReadOnlyArray<ObjectFieldNode>
}

@:forward(kind, loc, fields)
abstract ObjectValueNode(TObjectValueNode) from TObjectValueNode to TObjectValueNode {
	inline function new(n:TObjectValueNode) {
		this = n;
		this.kind = "ObjectValue";
	}
}

typedef TObjectFieldNode = {
	> ASTNode,
	name:NameNode,
	value:ValueNode
}

@:forward(kind, loc, name, value)
abstract ObjectFieldNode(TObjectFieldNode) from TObjectFieldNode to TObjectFieldNode {
	inline function new(n:TObjectFieldNode) {
		this = n;
		this.kind = "ObjectField";
	}
}

typedef TDirectiveNode = {
	> ASTNode,
	name:NameNode,
	?arguments:ReadOnlyArray<ArgumentNode>
}

@:forward(kind, loc, name, arguments)
abstract DirectiveNode(TDirectiveNode) from TDirectiveNode to TDirectiveNode {
	inline function new(n:TDirectiveNode) {
		this = n;
		this.kind = "Directive";
	}
}

typedef TypeNode = {
	> ASTNode,
	?type:TypeNode
}

typedef TNamedTypeNode = {
	> TypeNode,
	name:NameNode
}

@:forward(kind, loc, name)
abstract NamedTypeNode(TNamedTypeNode) from TNamedTypeNode to TNamedTypeNode {
	inline function new(n:TNamedTypeNode) {
		this = n;
		this.kind = "NamedType";
	}
}

typedef TListTypeNode = {
	> TypeNode,
}

@:forward(kind, loc, type)
abstract ListTypeNode(TListTypeNode) from TListTypeNode to TListTypeNode {
	inline function new(n:TListTypeNode) {
		this = n;
		this.kind = "ListType";
	}
}

typedef TNonNullTypeNode = {
	> TypeNode,
}

@:forward(kind, loc, type)
abstract NonNullTypeNode(TNonNullTypeNode) from TNonNullTypeNode to TNonNullTypeNode {
	inline function new(n:TNonNullTypeNode) {
		this = n;
		this.kind = "NonNullType";
	}
}

typedef TypeSystemDefinitionNode = {
	> DefinitionNode,
	?description:StringValueNode
}

typedef TSchemaDefinitionNode = {
	> TypeSystemDefinitionNode,
	?directives:ReadOnlyArray<DirectiveNode>,
	operationTypes:ReadOnlyArray<OperationTypeDefinitionNode>
}

@:forward(kind, loc, description, directives, operationTypes)
abstract SchemaDefinitionNode(TSchemaDefinitionNode) from TSchemaDefinitionNode to TSchemaDefinitionNode {
	inline function new(n:TSchemaDefinitionNode) {
		this = n;
		this.kind = "SchemaDefinition";
	}
}

typedef TOperationTypeDefinitionNode = {
	> ASTNode,
	operation:OperationTypeNode,
	type:NamedTypeNode,
}

@:forward(kind, loc, operation, type)
abstract OperationTypeDefinitionNode(TOperationTypeDefinitionNode) from TOperationTypeDefinitionNode to TOperationTypeDefinitionNode {
	inline function new(n:TOperationTypeDefinitionNode) {
		this = n;
		this.kind = "OperationTypeDefinition";
	}
}

typedef TypeDefinitionNode = {
	> ASTNode,
	?description:StringValueNode,
	name:NameNode,
	directives:ReadOnlyArray<DirectiveNode>
}

@:forward(kind, loc, description, name, directives)
abstract ScalarTypeDefinitionNode(TypeDefinitionNode) from TypeDefinitionNode to TypeDefinitionNode {
	inline function new(n:TypeDefinitionNode) {
		this = n;
		this.kind = "ScalarTypeDefinition";
	}
}

typedef TObjectTypeDefinitionNode = {
	> TypeDefinitionNode,
	?interfaces:ReadOnlyArray<NamedTypeNode>,
	?fields:ReadOnlyArray<FieldDefinitionNode>
}

@:forward(kind, loc, description, name, directives, interfaces, fields)
abstract ObjectTypeDefinitionNode(TObjectTypeDefinitionNode) from TObjectTypeDefinitionNode to TObjectTypeDefinitionNode {
	inline function new(n:TObjectTypeDefinitionNode) {
		this = n;
		this.kind = "ObjectTypeDefinition";
	}
}

typedef TFieldDefinitionNode = {
	> ASTNode,
	?description:StringValueNode,
	name:NameNode,
	?arguments:ReadOnlyArray<InputValueDefinitionNode>,
	type:TypeNode,
	?directives:ReadOnlyArray<DirectiveNode>
}

@:forward(kind, loc, description, name, directives, type, arguments)
abstract FieldDefinitionNode(TFieldDefinitionNode) from TFieldDefinitionNode to TFieldDefinitionNode {
	inline function new(n:TFieldDefinitionNode) {
		this = n;
		this.kind = "FieldDefinition";
	}
}

typedef TInputValueDefinitionNode = {
	> ASTNode,
	?description:StringValueNode,
	name:NameNode,
	?arguments:ReadOnlyArray<InputValueDefinitionNode>,
	type:TypeNode,
	?directives:ReadOnlyArray<DirectiveNode>,
	?defaultValue:ValueNode
}

@:forward(kind, loc, description, name, directives, type, defaultValue)
abstract InputValueDefinitionNode(TInputValueDefinitionNode) from TInputValueDefinitionNode to TInputValueDefinitionNode {
	inline function new(n:TInputValueDefinitionNode) {
		this = n;
		this.kind = "InputValueDefinition";
	}
}

typedef TInterfaceTypeDefinitionNode = {
	> TypeDefinitionNode,
	?interfaces:ReadOnlyArray<NamedTypeNode>,
	?fields:ReadOnlyArray<FieldDefinitionNode>
}

@:forward(kind, loc, description, name, directives, interfaces, fields)
abstract InterfaceTypeDefinitionNode(TInterfaceTypeDefinitionNode) from TInterfaceTypeDefinitionNode to TInterfaceTypeDefinitionNode {
	inline function new(n:TInterfaceTypeDefinitionNode) {
		this = n;
		this.kind = "InterfaceDefinition";
	}
}

typedef TUnionTypeDefinitionNode = {
	> TypeDefinitionNode,
	?types:ReadOnlyArray<NamedTypeNode>,
}

@:forward(kind, loc, description, name, directives, types)
abstract UnionTypeDefinitionNode(TUnionTypeDefinitionNode) from TUnionTypeDefinitionNode to TUnionTypeDefinitionNode {
	inline function new(n:TUnionTypeDefinitionNode) {
		this = n;
		this.kind = "UnionTypeDefinition";
	}
}

typedef TEnumTypeDefinitionNode = {
	> TypeDefinitionNode,
	?values:ReadOnlyArray<EnumValueDefinitionNode>,
}

@:forward(kind, loc, description, name, directives, values)
abstract EnumTypeDefinitionNode(TEnumTypeDefinitionNode) from TEnumTypeDefinitionNode to TEnumTypeDefinitionNode {
	inline function new(n:TEnumTypeDefinitionNode) {
		this = n;
		this.kind = "EnumTypeDefinition";
	}
}

typedef TEnumValueDefinitionNode = {
	> ASTNode,
	?description:StringValueNode,
	name:NameNode,
	?directives:ReadOnlyArray<DirectiveNode>,
}

@:forward(kind, loc, description, name, directives)
abstract EnumValueDefinitionNode(TEnumValueDefinitionNode) from TEnumValueDefinitionNode to TEnumValueDefinitionNode {
	inline function new(n:TEnumValueDefinitionNode) {
		this = n;
		this.kind = "EnumValueDefinition";
	}
}

typedef TInputObjectTypeDefinitionNode = {
	> TypeDefinitionNode,
	?fields:ReadOnlyArray<InputValueDefinitionNode>,
}

@:forward(kind, loc, description, name, directives, fields)
abstract InputObjectTypeDefinitionNode(TInputObjectTypeDefinitionNode) from TInputObjectTypeDefinitionNode to TInputObjectTypeDefinitionNode {
	inline function new(n:TInputObjectTypeDefinitionNode) {
		this = n;
		this.kind = "InputObjectTypeDefinition";
	}
}

typedef TDirectiveDefinitionNode = {
	> ASTNode,
	?description:StringValueNode,
	name:NameNode,
	?arguments:ReadOnlyArray<InputValueDefinitionNode>,
	repeatable:Bool,
	locations:ReadOnlyArray<NameNode>
}

@:forward(kind, loc, description, name, arguments, repeatable, locations)
abstract DirectiveDefinitionNode(TDirectiveDefinitionNode) from TDirectiveDefinitionNode to TDirectiveDefinitionNode {
	inline function new(n:TDirectiveDefinitionNode) {
		this = n;
		this.kind = "DirectiveDefinition";
	}
}

typedef TypeSystemExtensionNode = {
	> DefinitionNode,
	?directives:ReadOnlyArray<DirectiveNode>
}

typedef TSchemaExtensionNode = {
	> TypeSystemExtensionNode,
	?operationTypes:ReadOnlyArray<OperationTypeDefinitionNode>
}

@:forward(kind, loc, directives, operationTypes)
abstract SchemaExtensionNode(TSchemaExtensionNode) from TSchemaExtensionNode to TSchemaExtensionNode {
	inline function new(n:TSchemaExtensionNode) {
		this = n;
		this.kind = "SchemaExtension";
	}
}

typedef TypeExtensionNode = {
	> TypeSystemExtensionNode,
	name:NameNode
}

@:forward(kind, loc, directives, name)
abstract ScalarTypeExtensionNode(TypeExtensionNode) from TypeExtensionNode to TypeExtensionNode {
	inline function new(n:TypeExtensionNode) {
		this = n;
		this.kind = 'ScalarTypeExtension';
	}
}

typedef TObjectTypeExtensionNode = {
	> TypeExtensionNode,
	?interfaces:ReadOnlyArray<NamedTypeNode>,
	?fields:ReadOnlyArray<FieldDefinitionNode>
}

@:forward(kind, loc, directives, name, interfaces, fields)
abstract ObjectTypeExtensionNode(TObjectTypeExtensionNode) from TObjectTypeExtensionNode to TObjectTypeExtensionNode {
	inline function new(n:TObjectTypeExtensionNode) {
		this = n;
		this.kind = 'ObjectTypeExtension';
	}
}

typedef TInterfaceTypeExtensionNode = {
	> TypeExtensionNode,
	?interfaces:ReadOnlyArray<NamedTypeNode>,
	?fields:ReadOnlyArray<FieldDefinitionNode>
}

@:forward(kind, loc, directives, name, interfaces, fields)
abstract InterfaceTypeExtensionNode(TInterfaceTypeExtensionNode) from TInterfaceTypeExtensionNode to TInterfaceTypeExtensionNode {
	inline function new(n:TInterfaceTypeExtensionNode) {
		this = n;
		this.kind = 'InterfaceTypeExtension';
	}
}

typedef TUnionTypeExtensionNode = {
	> TypeExtensionNode,
	?types:ReadOnlyArray<NamedTypeNode>
}

@:forward(kind, loc, directives, name, interfaces, types)
abstract UnionTypeExtensionNode(TUnionTypeExtensionNode) from TUnionTypeExtensionNode to TUnionTypeExtensionNode {
	inline function new(n:TUnionTypeExtensionNode) {
		this = n;
		this.kind = 'UnionTypeExtension';
	}
}

typedef TEnumTypeExtensionNode = {
	> TypeExtensionNode,
	?values:ReadOnlyArray<EnumValueDefinitionNode>,
}

@:forward(kind, loc, directives, name, interfaces, values)
abstract EnumTypeExtensionNode(TEnumTypeExtensionNode) from TEnumTypeExtensionNode to TEnumTypeExtensionNode {
	inline function new(n:TEnumTypeExtensionNode) {
		this = n;
		this.kind = 'EnumTypeExtension';
	}
}

typedef TInputObjectTypeExtensionNode = {
	> TypeExtensionNode,
	?fields:ReadOnlyArray<InputValueDefinitionNode>
}

@:forward(kind, loc, directives, name, fields)
abstract InputObjectTypeExtensionNode(TInputObjectTypeExtensionNode) from TInputObjectTypeExtensionNode to TInputObjectTypeExtensionNode {
	inline function new(n:TInputObjectTypeExtensionNode) {
		this = n;
		this.kind = 'InputObjectTypeExtension';
	}
}

typedef AST = {}
