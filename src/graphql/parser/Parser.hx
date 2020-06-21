package graphql.parser;

using graphql.parser.AST;
using graphql.parser.Kind;

import graphql.parser.Macro.ASSERT;
import graphql.parser.Macro.AssertionFailure;
import graphql.parser.TokenEnum;

/**
 * Configuration options to control parser behavior
 */
typedef /* export type */ ParseOptions = {
	/**
	 * By default, the parser creates AST nodes that know the location
	 * in the source that they correspond to. This configuration flag
	 * disables that behavior for performance or testing.
	 */
	@:optional var noLocation /* opt */:Bool;

	/**
	 * If enabled, the parser will parse empty fields sets in the Schema
	 * Definition Language. Otherwise, the parser will follow the current
	 * specification.
	 *
	 * This option is provided to ease adoption of the final SDL specification
	 * and will be removed in v16.
	 */ @:optional var allowLegacySDLEmptyFields /* opt */:Bool;

	/**
	 * If enabled, the parser will parse implemented interfaces with no '&'
	 * character between each interface. Otherwise, the parser will follow the
	 * current specification.
	 *
	 * This option is provided to ease adoption of the final SDL specification
	 * and will be removed in v16.
	 */ @:optional var allowLegacySDLImplementsInterfaces /* opt */:Bool;

	/**
	 * EXPERIMENTAL:
	 *
	 * If enabled, the parser will understand and parse variable definitions
	 * contained in a fragment definition. They'll be represented in the
	 * 'variableDefinitions' field of the FragmentDefinitionNode.
	 *
	 * The syntax is identical to normal, query-defined variables. For example:
	 *
	 *   fragment A($var: Boolean = false) on T  {
	 *     ...
	 *   }
	 *
	 * Note: this feature is experimental and may change or be removed in the
	 * future.
	 */ @:optional var experimentalFragmentVariables /* opt */:Bool;
};

class Parser {
	/**
	 * Given a GraphQL source, parses it into a Document.
	 * Throws GraphQLError if a syntax error is encountered.
	 */
	public static function parse(source:Dynamic, ?options:ParseOptions) {
		final parser = new Parser(source, options);
		return parser.parseDocument();
	}

	/**
	 * Given a string containing a GraphQL value (ex. '[42]'), parse the AST for
	 * that value.
	 *
	 * Throws GraphQLError if a syntax error is encountered.
	 *
	 * This is useful within tools that operate upon GraphQL Values directly and
	 * in isolation of complete GraphQL documents.
	 *
	 * Consider providing the results to the utility function: valueFromAST().
	 * @param source
	 * @param options
	 * @return ValueNode
	 */
	public static function parseValue(source:Dynamic, ?options:ParseOptions):ValueNode {
		final parser = new Parser(source, options);
		parser.expectToken(SOF);
		final value = parser.parseValueLiteral(false);
		parser.expectToken(EOF);
		return value;
	}

	/**
	 * Given a string containing a GraphQL Type (ex. '[Int!]'), parse the AST for
	 * that type.
	 * Throws GraphQLError if a syntax error is encountered.
	 *
	 * This is useful within tools that operate upon GraphQL Types directly and
	 * in isolation of complete GraphQL documents.
	 *
	 * Consider providing the results to the utility function: typeFromAST().
	 */
	public static function parseType(source:Dynamic, ?options:ParseOptions):TypeNode {
		final parser = new Parser(source, options);
		parser.expectToken(SOF);
		final type = parser.parseTypeReference();
		parser.expectToken(EOF);
		return type;
	}

	public static function syntaxError(source:Source, position:Int, description:String):GraphQLError {
		return new GraphQLError('Syntax Error: ${description}', null, source, [position,]);
	}

	var lexer:Lexer;
	var options:ParseOptions;

	public function new(source:Dynamic, ?options:ParseOptions) {
		final sourceObj = Std.isOfType(source, String) ? new Source(source) : source;
		ASSERT(Std.isOfType(sourceObj, Source), 'Must provide Source. Received: ${sourceObj}.');

		this.lexer = new Lexer(sourceObj);
		this.options = options;
	}

	/**
	 * Converts a name lex token into a name parse node.
	 * @return NameNode
	 */
	function parseName():NameNode {
		final token = this.expectToken(NAME);
		return {
			kind: NAME,
			value: token.value,
			loc: this.loc(token),
		};
	}

	function parseDocument():DocumentNode {
		final start = this.lexer.token;
		return {
			kind: DOCUMENT,
			definitions: this.many(SOF, this.parseDefinition, EOF),
			loc: this.loc(start),
		};
	}

	function parseDefinition():DefinitionNode {
		if (this.peek(NAME)) {
			return switch (this.lexer.token.value) {
				case 'query' | 'mutation' | 'subscription':
					this.parseOperationDefinition();
				case 'fragment':
					this.parseFragmentDefinition();
				case 'schema' | 'scalar' | 'type' | 'interface' | 'union' | 'enum' | 'input' | 'directive':
					this.parseTypeSystemDefinition();
				case 'extend':
					this.parseTypeSystemExtension();
				case _: throw this.unexpected();
			}
		} else if (this.peek(BRACE_L)) {
			return this.parseOperationDefinition();
		} else if (this.peekDescription()) {
			return this.parseTypeSystemDefinition();
		}

		throw this.unexpected();
	}

	function parseOperationDefinition():OperationDefinitionNode {
		final start = this.lexer.token;
		if (this.peek(BRACE_L)) {
			return {
				kind: OPERATION_DEFINITION,
				operation: QUERY,
				name: null,
				variableDefinitions: [],
				directives: [],
				selectionSet: this.parseSelectionSet(),
				loc: this.loc(start)
			};
		}
		final operation = this.parseOperationType();
		var name = null;
		if (this.peek(NAME)) {
			name = this.parseName();
		}
		return {
			kind: OPERATION_DEFINITION,
			operation: operation,
			name: name,
			variableDefinitions: this.parseVariableDefinitions(),
			directives: this.parseDirectives(false),
			selectionSet: this.parseSelectionSet(),
			loc: this.loc(start),
		};
	}

	function parseOperationType():OperationTypeNode {
		final operationToken = this.expectToken(NAME);
		return switch (operationToken.value) {
			case QUERY: QUERY;
			case MUTATION: MUTATION;
			case SUBSCRIPTION: SUBSCRIPTION;
			case _: throw this.unexpected(operationToken);
		}
	}

	function parseVariableDefinitions():Array<VariableDefinitionNode> {
		return this.optionalMany(PAREN_L, this.parseVariableDefinition, PAREN_R);
	}

	function parseVariableDefinition():VariableDefinitionNode {
		final start = this.lexer.token;
		return {
			kind: VARIABLE_DEFINITION,
			variable: this.parseVariable(),
			type: {this.expectToken(COLON); this.parseTypeReference();},
			defaultValue: this.expectOptionalToken(EQUALS) != null ? this.parseValueLiteral(true) : null,
			directives: this.parseDirectives(true),
			loc: this.loc(start)
		};
	}

	function parseVariable():VariableNode {
		final start = this.lexer.token;
		this.expectToken(DOLLAR);
		return {
			kind: VARIABLE,
			name: this.parseName(),
			loc: this.loc(start),
		};
	}

	function parseSelectionSet():SelectionSetNode {
		final start = this.lexer.token;
		return {
			kind: SELECTION_SET,
			selections: this.many(BRACE_L, this.parseSelection, BRACE_R),
			loc: this.loc(start),
		};
	}

	function parseSelection():SelectionNode {
		return this.peek(SPREAD) ? this.parseFragment() : this.parseField();
	}

	function parseField():FieldNode {
		final start = this.lexer.token;
		final nameOrAlias = this.parseName();
		var alias = null;
		var name = null;
		if (this.expectOptionalToken(COLON) != null) {
			alias = nameOrAlias;
			name = this.parseName();
		} else {
			name = nameOrAlias;
		}
		return {
			kind: FIELD,
			alias: alias,
			name: name,
			arguments: this.parseArguments(false),
			directives: this.parseDirectives(false),
			selectionSet: this.peek(BRACE_L) ? this.parseSelectionSet() : null,
			loc: this.loc(start)
		};
	}

	function parseArguments(isConst:Bool):Array<ArgumentNode> {
		final item = isConst ? this.parseConstArgument : this.parseArgument;
		return this.optionalMany(PAREN_L, item, PAREN_R);
	}

	function parseArgument():ArgumentNode {
		final start = this.lexer.token;
		final name = this.parseName();

		this.expectToken(COLON);
		return {
			kind: ARGUMENT,
			name: name,
			value: this.parseValueLiteral(false),
			loc: this.loc(start),
		};
	}

	function parseConstArgument():ArgumentNode {
		final start = this.lexer.token;
		this.expectToken(COLON);
		return {
			kind: ARGUMENT,
			name: this.parseName(),
			value: this.parseValueLiteral(true),
			loc: this.loc(start),
		};
	}

	function parseFragment():Any /*FragmentSpreadNode | InlineFragmentNode*/ {
		final start = this.lexer.token;
		this.expectToken(SPREAD);

		final hasTypeCondition = this.expectOptionalKeyword('on');
		if (!hasTypeCondition && this.peek(NAME)) {
			return {
				kind: FRAGMENT_SPREAD,
				name: this.parseFragmentName(),
				directives: this.parseDirectives(false),
				loc: this.loc(start),
			};
		}
		return {
			kind: INLINE_FRAGMENT,
			typeCondition: hasTypeCondition ? this.parseNamedType() : null,
			directives: this.parseDirectives(false),
			selectionSet: this.parseSelectionSet(),
			loc: this.loc(start),
		};
	}

	function parseFragmentDefinition():FragmentDefinitionNode {
		final start = this.lexer.token;
		this.expectKeyword('fragment');
		// Experimental support for defining variables within fragments changes
		// the grammar of FragmentDefinition:
		//   - fragment FragmentName VariableDefinitions? on TypeCondition Directives? SelectionSet
		if (this.options != null && this.options.experimentalFragmentVariables == true) {
			return {
				kind: FRAGMENT_DEFINITION,
				name: this.parseFragmentName(),
				variableDefinitions: this.parseVariableDefinitions(),
				typeCondition: {this.expectKeyword('on'); this.parseNamedType();},
				directives: this.parseDirectives(false),
				selectionSet: this.parseSelectionSet(),
				loc: this.loc(start),
			};
		}

		return {
			kind: FRAGMENT_DEFINITION,
			name: this.parseFragmentName(),
			typeCondition: {this.expectKeyword('on'); this.parseNamedType();},
			directives: this.parseDirectives(false),
			selectionSet: this.parseSelectionSet(),
			loc: this.loc(start),
		};
	}

	function parseFragmentName():NameNode {
		if (this.lexer.token.value == 'on') {
			throw this.unexpected();
		}
		return this.parseName();
	}

	function parseValueLiteral(isConst:Bool):ValueNode {
		final token = this.lexer.token;
		return switch (token.kind) {
			case BRACKET_L: this.parseList(isConst);
			case BRACE_L: this.parseObject(isConst);
			case INT:
				this.lexer.advance();
				{
					kind: INT,
					value: token.value,
					loc: this.loc(token),
				};
			case FLOAT:
				this.lexer.advance();
				{
					kind: FLOAT,
					value: token.value,
					loc: this.loc(token),
				};
			case STRING | BLOCK_STRING: this.parseStringLiteral();
			case NAME: {
					this.lexer.advance();
					switch (token.value) {
						case 'true':
							{kind: BOOLEAN, value: true, loc: this.loc(token)};
						case 'false':
							{kind: BOOLEAN, value: false, loc: this.loc(token)};
						case 'null':
							{kind: NULL, loc: this.loc(token)};
						default:
							{
								kind: ENUM,
								value: token.value,
								loc: this.loc(token),
							};
					}
				}
			case DOLLAR: {
					if (!isConst) {
						this.parseVariable();
					}
					null;
				}
			case _: {
					throw this.unexpected();
				}
		}
	}

	function parseStringLiteral():StringValueNode {
		final token = this.lexer.token;
		this.lexer.advance();
		return {
			kind: STRING,
			value: token.value,
			block: token.kind == BLOCK_STRING,
			loc: this.loc(token),
		};
	}

	function parseList(isConst:Bool):ListValueNode {
		final start = this.lexer.token;
		final item = () -> this.parseValueLiteral(isConst);
		return {
			kind: LIST,
			values: this.any(BRACKET_L, item, BRACKET_R),
			loc: this.loc(start),
		};
	}

	function parseObject(isConst:Bool):ObjectValueNode {
		final start = this.lexer.token;
		final item = () -> this.parseObjectField(isConst);
		return {
			kind: OBJECT,
			fields: this.any(BRACE_L, item, BRACE_R),
			loc: this.loc(start),
		};
	}

	function parseObjectField(isConst:Bool):ObjectFieldNode {
		final start = this.lexer.token;
		final name = this.parseName();
		this.expectToken(COLON);

		return {
			kind: OBJECT_FIELD,
			name: name,
			value: this.parseValueLiteral(isConst),
			loc: this.loc(start),
		};
	}

	function parseDirectives(isConst:Bool):Array<DirectiveNode> {
		final directives = [];
		while (this.peek(AT)) {
			directives.push(this.parseDirective(isConst));
		}
		return directives;
	}

	function parseDirective(isConst:Bool):DirectiveNode {
		final start = this.lexer.token;
		this.expectToken(AT);
		return {
			kind: DIRECTIVE,
			name: this.parseName(),
			arguments: this.parseArguments(isConst),
			loc: this.loc(start),
		};
	}

	function parseTypeReference():TypeNode {
		final start = this.lexer.token;
		var type;
		if (this.expectOptionalToken(BRACKET_L) != null) {
			type = this.parseTypeReference();
			this.expectToken(BRACKET_R);
			type = {
				kind: LIST_TYPE,
				type: type,
				loc: this.loc(start),
			};
		} else {
			type = this.parseNamedType();
		}

		if (this.expectOptionalToken(BANG) != null) {
			return {
				kind: NON_NULL_TYPE,
				type: type,
				loc: this.loc(start),
			};
		}
		return type;
	}

	function parseNamedType():NamedTypeNode {
		final start = this.lexer.token;
		return {
			kind: NAMED_TYPE,
			name: this.parseName(),
			loc: this.loc(start),
		};
	}

	function parseTypeSystemDefinition():TypeSystemDefinitionNode {
		// Many definitions begin with a description and require a lookahead.
		final keywordToken = this.peekDescription() ? this.lexer.lookahead() : this.lexer.token;

		if (keywordToken.kind == NAME) {
			return switch (keywordToken.value) {
				case 'schema':
					this.parseSchemaDefinition();
				case 'scalar':
					this.parseScalarTypeDefinition();
				case 'type':
					this.parseObjectTypeDefinition();
				case 'interface':
					this.parseInterfaceTypeDefinition();
				case 'union':
					this.parseUnionTypeDefinition();
				case 'enum':
					this.parseEnumTypeDefinition();
				case 'input':
					this.parseInputObjectTypeDefinition();
				case 'directive':
					this.parseDirectiveDefinition();
				case _: throw this.unexpected(keywordToken);
			}
		}

		throw this.unexpected(keywordToken);
	}

	function peekDescription():Bool {
		return this.peek(STRING) || this.peek(BLOCK_STRING);
	}

	function parseDescription():StringValueNode {
		if (this.peekDescription()) {
			return this.parseStringLiteral();
		}
		return null;
	}

	function parseSchemaDefinition():SchemaDefinitionNode {
		final start = this.lexer.token;
		final description = this.parseDescription();
		this.expectKeyword('schema');
		final directives = this.parseDirectives(true);
		final operationTypes = this.many(BRACE_L, this.parseOperationTypeDefinition, BRACE_R);
		return {
			kind: SCHEMA_DEFINITION,
			description: description,
			directives: directives,
			operationTypes: operationTypes,
			loc: this.loc(start)
		};
	}

	function parseOperationTypeDefinition():OperationTypeDefinitionNode {
		final start = this.lexer.token;
		final operation = this.parseOperationType();
		this.expectToken(COLON);
		final type = this.parseNamedType();
		return {
			kind: OPERATION_TYPE_DEFINITION,
			operation: operation,
			type: type,
			loc: this.loc(start)
		};
	}

	function parseScalarTypeDefinition():ScalarTypeDefinitionNode {
		final start = this.lexer.token;
		final description = this.parseDescription();
		this.expectKeyword('scalar');
		final name = this.parseName();
		final directives = this.parseDirectives(true);
		return {
			kind: SCALAR_TYPE_DEFINITION,
			description: description,
			name: name,
			directives: directives,
			loc: this.loc(start)
		};
	}

	function parseObjectTypeDefinition():ObjectTypeDefinitionNode {
		final start = this.lexer.token;
		final description = this.parseDescription();
		this.expectKeyword('type');
		final name = this.parseName();
		final interfaces = this.parseImplementsInterfaces();
		final directives = this.parseDirectives(true);
		final fields = this.parseFieldsDefinition();
		return {
			kind: OBJECT_TYPE_DEFINITION,
			description: description,
			name: name,
			interfaces: interfaces,
			directives: directives,
			fields: fields,
			loc: this.loc(start),
		};
	}

	function parseImplementsInterfaces():Array<NamedTypeNode> {
		final types = [];
		if (this.expectOptionalKeyword('implements')) {
			// Optional leading ampersand
			this.expectOptionalToken(AMP);
			do {
				types.push(this.parseNamedType());
			} while (this.expectOptionalToken(AMP) != null || // Legacy support for the SDL?
					(this.options != null && this.options.allowLegacySDLImplementsInterfaces == true && this.peek(NAME)));
		}
		return types;
	}

	function parseFieldsDefinition():Array<FieldDefinitionNode> {
		// Legacy support for the SDL?
		if ((this.options != null && this.options.allowLegacySDLEmptyFields == true)
			&& this.peek(BRACE_L)
			&& this.lexer.lookahead().kind == BRACE_R) {
			this.lexer.advance();
			this.lexer.advance();
			return [];
		}
		return this.optionalMany(BRACE_L, this.parseFieldDefinition, BRACE_R);
	}

	function parseFieldDefinition():FieldDefinitionNode {
		final start = this.lexer.token;
		final description = this.parseDescription();
		final name = this.parseName();
		final args = this.parseArgumentDefs();
		this.expectToken(COLON);
		final type = this.parseTypeReference();
		final directives = this.parseDirectives(true);
		return {
			kind: FIELD_DEFINITION,
			description: description,
			name: name,
			arguments: args,
			type: type,
			directives: directives,
			loc: this.loc(start)
		};
	}

	function parseArgumentDefs():Array<InputValueDefinitionNode> {
		return this.optionalMany(PAREN_L, this.parseInputValueDef, PAREN_R);
	}

	function parseInputValueDef():InputValueDefinitionNode {
		final start = this.lexer.token;
		final description = this.parseDescription();
		final name = this.parseName();
		this.expectToken(COLON);
		final type = this.parseTypeReference();
		var defaultValue = null;
		if (this.expectOptionalToken(EQUALS) != null) {
			defaultValue = this.parseValueLiteral(true);
		}
		final directives = this.parseDirectives(true);
		return {
			kind: INPUT_VALUE_DEFINITION,
			description: description,
			name: name,
			type: type,
			defaultValue: defaultValue,
			directives: directives,
			loc: this.loc(start)
		};
	}

	function parseInterfaceTypeDefinition():InterfaceTypeDefinitionNode {
		final start = this.lexer.token;
		final description = this.parseDescription();
		this.expectKeyword('interface');
		final name = this.parseName();
		final interfaces = this.parseImplementsInterfaces();
		final directives = this.parseDirectives(true);
		final fields = this.parseFieldsDefinition();
		return {
			kind: INTERFACE_TYPE_DEFINITION,
			description: description,
			name: name,
			interfaces: interfaces,
			directives: directives,
			fields: fields,
			loc: this.loc(start)
		};
	}

	function parseUnionTypeDefinition():UnionTypeDefinitionNode {
		final start = this.lexer.token;
		final description = this.parseDescription();
		this.expectKeyword('union');
		final name = this.parseName();
		final directives = this.parseDirectives(true);
		final types = this.parseUnionMemberTypes();
		return {
			kind: UNION_TYPE_DEFINITION,
			description: description,
			name: name,
			directives: directives,
			types: types,
			loc: this.loc(start)
		};
	}

	function parseUnionMemberTypes():Array<NamedTypeNode> {
		final types = [];
		if (this.expectOptionalToken(EQUALS) != null) {
			// Optional leading pipe
			this.expectOptionalToken(PIPE);
			do {
				types.push(this.parseNamedType());
			} while (this.expectOptionalToken(PIPE) != null);
		}
		return types;
	}

	function parseEnumValueDefinition():EnumValueDefinitionNode {
		final start = this.lexer.token;
		final description = this.parseDescription();
		final name = this.parseName();
		final directives = this.parseDirectives(true);
		return {
			kind: Kind.ENUM_VALUE_DEFINITION,
			description: description,
			name: name,
			directives: directives,
			loc: this.loc(start),
		};
	}

	function parseEnumTypeDefinition():EnumTypeDefinitionNode {
		final start = this.lexer.token;
		final description = this.parseDescription();
		this.expectKeyword('enum');
		final name = this.parseName();
		final directives = this.parseDirectives(true);
		final values = this.parseEnumValuesDefinition();
		return {
			kind: ENUM_TYPE_DEFINITION,
			description: description,
			name: name,
			directives: directives,
			values: values,
			loc: this.loc(start),
		};
	}

	function parseEnumValuesDefinition():Array<EnumValueDefinitionNode> {
		return this.optionalMany(BRACE_L, this.parseEnumValueDefinition, BRACE_R);
	}

	function parseInputObjectTypeDefinition():InputObjectTypeDefinitionNode {
		final start = this.lexer.token;
		final description = this.parseDescription();
		this.expectKeyword('input');
		final name = this.parseName();
		final directives = this.parseDirectives(true);
		final fields = this.parseInputFieldsDefinition();
		return {
			kind: Kind.INPUT_OBJECT_TYPE_DEFINITION,
			description: description,
			name: name,
			directives: directives,
			fields: fields,
			loc: this.loc(start),
		};
	}

	function parseInputFieldsDefinition():Array<InputValueDefinitionNode> {
		return this.optionalMany(BRACE_L, this.parseInputValueDef, BRACE_R);
	}

	function parseTypeSystemExtension():TypeSystemExtensionNode {
		final keywordToken = this.lexer.lookahead();
		if (keywordToken.kind == NAME) {
			switch (keywordToken.value) {
				case 'schema':
					return this.parseSchemaExtension();
				case 'scalar':
					return this.parseScalarTypeExtension();
				case 'type':
					return this.parseObjectTypeExtension();
				case 'interface':
					return this.parseInterfaceTypeExtension();
				case 'union':
					return this.parseUnionTypeExtension();
				case 'enum':
					return this.parseEnumTypeExtension();
				case 'input':
					return this.parseInputObjectTypeExtension();
				case _:
					throw this.unexpected(keywordToken);
			}
		}
		throw this.unexpected(keywordToken);
	}

	function parseSchemaExtension():SchemaExtensionNode {
		final start = this.lexer.token;
		this.expectKeyword('extend');
		this.expectKeyword('schema');
		final directives = this.parseDirectives(true);
		final operationTypes = this.optionalMany(BRACE_L, this.parseOperationTypeDefinition, BRACE_R);
		if (directives.length == 0 && operationTypes.length == 0) {
			throw this.unexpected();
		}
		return {
			kind: SCHEMA_EXTENSION,
			directives: directives,
			operationTypes: operationTypes,
			loc: this.loc(start)
		};
	}

	function parseScalarTypeExtension():ScalarTypeExtensionNode {
		final start = this.lexer.token;
		this.expectKeyword('extend');
		this.expectKeyword('scalar');
		final name = this.parseName();
		final directives = this.parseDirectives(true);
		if (directives.length == 0) {
			throw this.unexpected();
		}
		return {
			kind: SCALAR_TYPE_EXTENSION,
			name: name,
			directives: directives,
			loc: this.loc(start),
		};
	}

	function parseObjectTypeExtension():ObjectTypeExtensionNode {
		final start = this.lexer.token;
		this.expectKeyword('extend');
		this.expectKeyword('type');
		final name = this.parseName();
		final interfaces = this.parseImplementsInterfaces();
		final directives = this.parseDirectives(true);
		final fields = this.parseFieldsDefinition();
		if (interfaces.length == 0 && directives.length == 0 && fields.length == 0) {
			throw this.unexpected();
		}
		return {
			kind: Kind.OBJECT_TYPE_EXTENSION,
			name: name,
			interfaces: interfaces,
			directives: directives,
			fields: fields,
			loc: this.loc(start)
		};
	}

	function parseInterfaceTypeExtension():InterfaceTypeExtensionNode {
		final start = this.lexer.token;
		this.expectKeyword('extend');
		this.expectKeyword('interface');
		final name = this.parseName();
		final interfaces = this.parseImplementsInterfaces();
		final directives = this.parseDirectives(true);
		final fields = this.parseFieldsDefinition();
		if (interfaces.length == 0 && directives.length == 0 && fields.length == 0) {
			throw this.unexpected();
		}
		return {
			kind: INTERFACE_TYPE_EXTENSION,
			name: name,
			interfaces: interfaces,
			directives: directives,
			fields: fields,
			loc: this.loc(start),
		};
	}

	function parseUnionTypeExtension():UnionTypeExtensionNode {
		final start = this.lexer.token;
		this.expectKeyword('extend');
		this.expectKeyword('union');
		final name = this.parseName();
		final directives = this.parseDirectives(true);
		final types = this.parseUnionMemberTypes();
		if (directives.length == 0 && types.length == 0) {
			throw this.unexpected();
		}
		return {
			kind: UNION_TYPE_EXTENSION,
			name: name,
			directives: directives,
			types: types,
			loc: this.loc(start)
		};
	}

	function parseEnumTypeExtension():EnumTypeExtensionNode {
		final start = this.lexer.token;
		this.expectKeyword('extend');
		this.expectKeyword('enum');
		final name = this.parseName();
		final directives = this.parseDirectives(true);
		final values = this.parseEnumValuesDefinition();
		if (directives.length == 0 && values.length == 0) {
			throw this.unexpected();
		}
		return {
			kind: ENUM_TYPE_EXTENSION,
			name: name,
			directives: directives,
			values: values,
			loc: this.loc(start),
		};
	}

	function parseInputObjectTypeExtension():InputObjectTypeExtensionNode {
		final start = this.lexer.token;
		this.expectKeyword('extend');
		this.expectKeyword('input');
		final name = this.parseName();
		final directives = this.parseDirectives(true);
		final fields = this.parseInputFieldsDefinition();
		if (directives.length == 0 && fields.length == 0) {
			throw this.unexpected();
		}
		return {
			kind: INPUT_OBJECT_TYPE_EXTENSION,
			name: name,
			directives: directives,
			fields: fields,
			loc: this.loc(start),
		};
	}

	function parseDirectiveDefinition():DirectiveDefinitionNode {
		final start = this.lexer.token;
		final description = this.parseDescription();
		this.expectKeyword('directive');
		this.expectToken(AT);
		final name = this.parseName();
		final args = this.parseArgumentDefs();
		final repeatable = this.expectOptionalKeyword('repeatable');
		this.expectKeyword('on');
		final locations = this.parseDirectiveLocations();
		return {
			kind: DIRECTIVE_DEFINITION,
			description: description,
			name: name,
			arguments: args,
			repeatable: repeatable,
			locations: locations,
			loc: this.loc(start)
		};
	}

	function parseDirectiveLocations():Array<NameNode> {
		// Optional leading pipe
		this.expectOptionalToken(PIPE);
		final locations = [];
		do {
			locations.push(this.parseDirectiveLocation());
		} while (this.expectOptionalToken(PIPE) != null);
		return locations;
	}

	function parseDirectiveLocation():NameNode {
		final start = this.lexer.token;
		final name = this.parseName();
		final location:DirectiveLocation = name.value;
		return switch location {
			case QUERY | MUTATION | SUBSCRIPTION | FIELD | FRAGMENT_DEFINITION | FRAGMENT_SPREAD | INLINE_FRAGMENT | VARIABLE_DEFINITION | SCHEMA | SCALAR |
				OBJECT | FIELD_DEFINITION | ARGUMENT_DEFINITION | INTERFACE | UNION | ENUM | ENUM_VALUE | INPUT_OBJECT | INPUT_FIELD_DEFINITION: name;
			case _: throw this.unexpected(start);
		}
	}

	// Core parsing utility functions

	/**
	 * Returns a location object, used to identify the place in
	 * the source that created a given parsed object.
	 */
	function loc(startToken:Token):Location {
		if (this.options != null && this.options.noLocation != true) {
			return new Location(startToken, this.lexer.lastToken, this.lexer.source);
		}
		return null;
	}

	/**
	 * Determines if the next token is of a given kind
	 */
	function peek(kind:TokenEnum):Bool {
		return this.lexer.token.kind == kind;
	}

	/**
	 * If the next token is of the given kind, return that token after advancing
	 * the lexer. Otherwise, do not change the parser state and throw an error.
	 * @param kind
	 * @return Token
	 */
	function expectToken(kind:TokenEnum):Token {
		final token = this.lexer.token;
		if (token.kind == kind) {
			this.lexer.advance();
			return token;
		}
		throw syntaxError(this.lexer.source, token.start, 'Expected ${getTokenKindDesc(kind)}, found ${getTokenDesc(token)}.');
		return null;
	}

	/**
	 * If the next token is of the given kind, return that token after advancing
	 * the lexer. Otherwise, do not change the parser state and return undefined.
	 */
	function expectOptionalToken(kind:TokenEnum):Token {
		final token = this.lexer.token;
		if (token.kind == kind) {
			this.lexer.advance();
			return token;
		}
		return null;
	}

	/**
	 * If the next token is a given keyword, advance the lexer.
	 * Otherwise, do not change the parser state and throw an error.
	 */
	function expectKeyword(value:String) {
		final token = this.lexer.token;
		if (token.kind == NAME && token.value == value) {
			this.lexer.advance();
		} else {
			throw syntaxError(this.lexer.source, token.start, 'Expected "${value}", found ${getTokenDesc(token)}.');
		}
	}

	/**
	 * If the next token is a given keyword, return "true" after advancing
	 * the lexer. Otherwise, do not change the parser state and return "false".
	 */
	function expectOptionalKeyword(value:String):Bool {
		final token = this.lexer.token;
		if (token.kind == NAME && token.value == value) {
			this.lexer.advance();
			return true;
		}
		return false;
	}

	/**
	 * Helper function for creating an error when an unexpected lexed token
	 * is encountered.
	 */
	function unexpected(?atToken:Token):GraphQLError {
		final token = atToken != null ? atToken : this.lexer.token;
		return syntaxError(this.lexer.source, token.start, 'Unexpected ${getTokenDesc(token)}.');
	}

	/**
	 * Returns a possibly empty list of parse nodes, determined by
	 * the parseFn. This list begins with a lex token of openKind
	 * and ends with a lex token of closeKind. Advances the parser
	 * to the next lex token after the closing token.
	 */
	function any<T>(openKind:TokenEnum, parseFn:() -> T, closeKind:TokenEnum):Array<T> {
		this.expectToken(openKind);
		final nodes = [];
		while (this.expectOptionalToken(closeKind) == null) {
			nodes.push(parseFn());
		}
		return nodes;
	}

	/**
	 * Returns a list of parse nodes, determined by the parseFn.
	 * It can be empty only if open token is missing otherwise it will always
	 * return non-empty list that begins with a lex token of openKind and ends
	 * with a lex token of closeKind. Advances the parser to the next lex token
	 * after the closing token.
	 */
	function optionalMany<T>(openKind:TokenEnum, parseFn:() -> T, closeKind:TokenEnum):Array<T> {
		if (this.expectOptionalToken(openKind) != null) {
			final nodes = [];
			do {
				nodes.push(parseFn());
			} while (this.expectOptionalToken(closeKind) == null);
			return nodes;
		}
		return [];
	}

	/**
	 * Returns a non-empty list of parse nodes, determined by
	 * the parseFn. This list begins with a lex token of openKind
	 * and ends with a lex token of closeKind. Advances the parser
	 * to the next lex token after the closing token.
	 */
	function many<T>(openKind:TokenEnum, parseFn:() -> T, closeKind:TokenEnum):Array<T> {
		this.expectToken(openKind);
		final nodes = [];
		do {
			nodes.push(parseFn());
		} while (this.expectOptionalToken(closeKind) == null);
		return nodes;
	}

	/**
	 * A helper function to describe a token as a string for debugging
	 */
	function getTokenDesc(token:Token):String {
		final value = token.value;
		return getTokenKindDesc(token.kind) + (value != null ? '"${value}"' : '');
	}

	/**
	 * A helper function to describe a token kind as a string for debugging
	 */
	function getTokenKindDesc(kind:TokenEnum):String {
		return Lexer.isPunctuatorTokenKind(kind) ? '"${kind}"' : kind;
	}
}
