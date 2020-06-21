package graphql.parser;

import graphql.parser.TokenEnum;
import graphql.parser.AST.Token;

using graphql.parser.StringSlice;

/**
 * Given a Source object, creates a Lexer for that source.
 * A Lexer is a stateful stream generator in that every time
 * it is advanced, it returns the next token in the Source. Assuming the
 * source lexes, the final Token emitted by the lexer will be of kind
 * EOF, after which the lexer will repeatedly return the same EOF token
 * whenever called.
 */
class Lexer {
	public var source:Source;

	/**
	 * The previously focused non-ignored token.
	 */
	public var lastToken:Token;

	/**
	 * The currently focused non-ignored token.
	 */
	public var token:Token;

	/**
	 * The (1-indexed) line containing the current token.
	 */
	public var line:Int;

	/**
	 * The character offset at which the current line begins.
	 */
	public var lineStart:Int;

	public function new(source:Source) {
		final startOfFileToken = new Token(SOF, 0, 0, 0, 0, null);

		this.source = source;
		this.lastToken = startOfFileToken;
		this.token = startOfFileToken;
		this.line = 1;
		this.lineStart = 0;
	}

	/**
	 * Advances the token stream to the next non-ignored token.
	 */
	public function advance():Token {
		this.lastToken = this.token;
		final token = (this.token = this.lookahead());
		return token;
	}

	/**
	 * Looks ahead and returns the next non-ignored token, but does not change
	 * the state of Lexer.
	 */
	public function lookahead():Token {
		var token = this.token;
		switch token.kind {
			case EOF:
			case _:
				{
					do {
						// Note: next is only mutable during parsing, so we cast to allow this.
						token = (token.next != null) ? token.next : ((token : Dynamic).next = readToken(cast this, token));
					} while (token.kind == COMMENT);
				}
		}
		return token;
	}

	public static function isPunctuatorTokenKind(kind:TokenEnum):Bool {
		return (kind == BANG || kind == DOLLAR || kind == AMP || kind == PAREN_L || kind == PAREN_R || kind == SPREAD || kind == COLON || kind == EQUALS
			|| kind == AT || kind == BRACKET_L || kind == BRACKET_R || kind == BRACE_L || kind == PIPE || kind == BRACE_R);
	}

	function printCharCode(code):Dynamic {
		return ( // NaN/undefined represents access beyond the end of the file.
			false /* Math.isNaN(code) */ ?EOF : // Trust JSON for ASCII.
			code < 0x007f ? haxe.Json.stringify(String.fromCharCode(code)) : // Otherwise print the escaped form.
			'"\\u${StringSlice.ofString('00' + String.fromCharCode(code).toUpperCase()).slice(4...0)}"' // escaping madness
		);
	}

	/**
	 * Gets the next token from the source starting at the given position.
	 *
	 * This skips over whitespace until it finds the next lexable token, then lexes
	 * punctuators immediately or calls the appropriate helper function for more
	 * complicated tokens.
	 */
	public function readToken(lexer:Lexer, prev:Token):Token {
		var source = lexer.source;
		var body = source.body;
		var bodyLength = body.length;

		var pos = positionAfterWhitespace(body, prev.end, lexer);
		var line = lexer.line;
		var col = 1 + pos - lexer.lineStart;

		if (pos >= bodyLength) {
			return new Token(EOF, bodyLength, bodyLength, line, col, prev);
		}

		var code = body.charCodeAt(pos);

		// SourceCharacter
		switch (code) {
			// !
			case 33:
				return new Token(BANG, pos, pos + 1, line, col, prev);
			// #
			case 35:
				return readComment(source, pos, line, col, prev);
			// $
			case 36:
				return new Token(DOLLAR, pos, pos + 1, line, col, prev);
			// &
			case 38:
				return new Token(AMP, pos, pos + 1, line, col, prev);
			// (
			case 40:
				return new Token(PAREN_L, pos, pos + 1, line, col, prev);
			// )
			case 41:
				return new Token(PAREN_R, pos, pos + 1, line, col, prev);
			// .
			case 46:
				if (body.charCodeAt(pos + 1) == 46 && body.charCodeAt(pos + 2) == 46) {
					return new Token(SPREAD, pos, pos + 3, line, col, prev);
				}
			/* break; */
			// :
			case 58:
				return new Token(COLON, pos, pos + 1, line, col, prev);
			// =
			case 61:
				return new Token(EQUALS, pos, pos + 1, line, col, prev);
			// @
			case 64:
				return new Token(AT, pos, pos + 1, line, col, prev);
			// [
			case 91:
				return new Token(BRACKET_L, pos, pos + 1, line, col, prev);
			// ]
			case 93:
				return new Token(BRACKET_R, pos, pos + 1, line, col, prev);
			// {
			case 123:
				return new Token(BRACE_L, pos, pos + 1, line, col, prev);
			// |
			case 124:
				return new Token(PIPE, pos, pos + 1, line, col, prev);
			// }
			case 125:
				return new Token(BRACE_R, pos, pos + 1, line, col, prev);
			// A-Z _ a-z
			case 65 | /*CFT*/ 66 | /*CFT*/ 67 | /*CFT*/ 68 | /*CFT*/ 69 | /*CFT*/ 70 | /*CFT*/ 71 | /*CFT*/ 72 | /*CFT*/ 73 | /*CFT*/ 74 | /*CFT*/ 75 |
				/*CFT*/ 76 | /*CFT*/ 77 | /*CFT*/ 78 | /*CFT*/ 79 | /*CFT*/ 80 | /*CFT*/ 81 | /*CFT*/ 82 | /*CFT*/ 83 | /*CFT*/ 84 | /*CFT*/ 85 | /*CFT*/ 86 |
				/*CFT*/ 87 | /*CFT*/ 88 | /*CFT*/ 89 | /*CFT*/ 90 | /*CFT*/ 95 | /*CFT*/ 97 | /*CFT*/ 98 | /*CFT*/ 99 | /*CFT*/ 100 | /*CFT*/ 101 | /*CFT*/
				102 | /*CFT*/ 103 | /*CFT*/ 104 | /*CFT*/ 105 | /*CFT*/ 106 | /*CFT*/ 107 | /*CFT*/ 108 | /*CFT*/ 109 | /*CFT*/ 110 | /*CFT*/ 111 | /*CFT*/
				112 | /*CFT*/ 113 | /*CFT*/ 114 | /*CFT*/ 115 | /*CFT*/ 116 | /*CFT*/ 117 | /*CFT*/ 118 | /*CFT*/ 119 | /*CFT*/ 120 | /*CFT*/ 121 | /*CFT*/ 122:
				return readName(source, pos, line, col, prev);
			// - 0-9
			case 45 | /*CFT*/ 48 | /*CFT*/ 49 | /*CFT*/ 50 | /*CFT*/ 51 | /*CFT*/ 52 | /*CFT*/ 53 | /*CFT*/ 54 | /*CFT*/ 55 | /*CFT*/ 56 | /*CFT*/ 57:
				return readNumber(source, pos, code, line, col, prev);
			// "
			case 34:
				if (body.charCodeAt(pos + 1) == 34 && body.charCodeAt(pos + 2) == 34) {
					return readBlockString(source, pos, line, col, prev, lexer);
				}
				return readString(source, pos, line, col, prev);
		}

		throw syntaxError(source, pos, unexpectedCharacterMessage(code));
	}

	/**
	 * Report a message that an unexpected character was encountered.
	 */
	function unexpectedCharacterMessage(code) {
		if (code < 0x0020 && code != 0x0009 && code != 0x000a && code != 0x000d) {
			return 'Cannot contain the invalid character ${printCharCode(code)}.';
		}

		if (code == 39) {
			// '
			return ("Unexpected single quote character ('), did you mean to use " + 'a double quote (")?');
		}

		return 'Cannot parse the unexpected character ${printCharCode(code)}.';
	}

	/**
	 * Reads from body starting at startPosition until it finds a non-whitespace
	 * character, then returns the position of that character for lexing.
	 */
	function positionAfterWhitespace(body:String, startPosition:Int, lexer:Lexer):Int {
		var bodyLength = body.length;
		var position = startPosition;
		while (position < bodyLength) {
			var code = body.charCodeAt(position);
			// tab | space | comma | BOM
			if (code == 9 || code == 32 || code == 44 || code == 0xfeff) {
				++position;
			} else if (code == 10) {
				// new line
				++position;
				++lexer.line;
				lexer.lineStart = position;
			} else if (code == 13) {
				// carriage return
				if (body.charCodeAt(position + 1) == 10) {
					position += 2;
				} else {
					++position;
				}
				++lexer.line;
				lexer.lineStart = position;
			} else {
				break;
			}
		}
		return position;
	}

	/**
	 * Reads a comment token from the source file.
	 *
	 * #[\u0009\u0020-\uFFFF]*
	 */
	public function readComment(source:Source, start, line, col, prev):Token {
		var body = source.body;
		var code;
		var position = start;

		do {
			code = body.charCodeAt(++position);
		} while (!false /* Math.isNaN(code) */ && // SourceCharacter but not LineTerminator
				(code > 0x001f || code == 0x0009));

		return new Token(COMMENT, start, position, line, col, prev, body.slice(start + 1 ...position));
	}

	/**
	 * Reads a number token from the source file, either a float
	 * or an int depending on whether a decimal point appears.
	 *
	 * Int:   -?(0|[1-9][0-9]*)
	 * Float: -?(0|[1-9][0-9]*)(\.[0-9]+)?((E|e)(+|-)?[0-9]+)?
	 */
	public function readNumber(source:Source, start:Int, firstCode, line:Int, col:Int, prev):Token {
		var body = source.body;
		var code = firstCode;
		var position = start;
		var isFloat = false;

		if (code == 45) {
			// -
			code = body.charCodeAt(++position);
		}

		if (code == 48) {
			// 0
			code = body.charCodeAt(++position);
			if (code >= 48 && code <= 57) {
				throw syntaxError(source, position, 'Invalid number, unexpected digit after 0: ${printCharCode(code)}.');
			}
		} else {
			position = readDigits(source, position, code);
			code = body.charCodeAt(position);
		}

		if (code == 46) {
			// .
			isFloat = true;

			code = body.charCodeAt(++position);
			position = readDigits(source, position, code);
			code = body.charCodeAt(position);
		}

		if (code == 69 || code == 101) {
			// E e
			isFloat = true;

			code = body.charCodeAt(++position);
			if (code == 43 || code == 45) {
				// + -
				code = body.charCodeAt(++position);
			}
			position = readDigits(source, position, code);
			code = body.charCodeAt(position);
		}

		// Numbers cannot be followed by . or NameStart
		if (code == 46 || isNameStart(code)) {
			throw syntaxError(source, position, 'Invalid number, expected digit but got: ${printCharCode(code)}.');
		}

		return new Token(isFloat ? FLOAT : INT, start, position, line, col, prev, body.slice(start...position));
	}

	/**
	 * Reads a string token from the source file.
	 *
	 * "([^"\\\u000A\u000D]|(\\(u[0-9a-fA-F]{4}|["\\/bfnrt])))*"
	 */
	public function readString(source:Source, start, line, col, prev):Token {
		var body = source.body;
		var position = start + 1;
		var chunkStart = position;
		var code = 0;
		var value = '';

		while (position < body.length
			&& !Math.isNaN((code = body.charCodeAt(position)))
			&& // not LineTerminator
			code != 0x000a
			&& code != 0x000d) {
			// Closing Quote (")
			if (code == 34) {
				value += body.slice(chunkStart...position);
				return new Token(STRING, start, position + 1, line, col, prev, value);
			}

			// SourceCharacter
			if (code < 0x0020 && code != 0x0009) {
				throw syntaxError(source, position, 'Invalid character within String: ${printCharCode(code)}.');
			}

			++position;
			if (code == 92) {
				// \
				value += body.slice(chunkStart...position - 1);
				code = body.charCodeAt(position);
				switch (code) {
					case 34:
						value += '"';
					/* break; */
					case 47:
						value += '/';
					/* break; */
					case 92:
						value += '\\';
					/* break; */
					case 98:
						value += '\u0008' /* backspace? Haxe doesnt like \b */;
					/* break; */
					case 102:
						value += '\u000C' /* form feed? Haxe doesnt like \f */;
					/* break; */
					case 110:
						value += '\n';
					/* break; */
					case 114:
						value += '\r';
					/* break; */
					case 116:
						value += '\t';
					/* break; */
					case 117: // u
						var charCode = uniCharCode(body.charCodeAt(position + 1), body.charCodeAt(position + 2), body.charCodeAt(position + 3),
							body.charCodeAt(position + 4));
						if (charCode < 0) {
							throw syntaxError(source, position, 'Invalid character escape sequence: ' + '\\u${body.slice(position + 1...position + 5)}.');
						}
						value += String.fromCharCode(charCode);
						position += 4;
					/* break; */
					default:
						throw syntaxError(source, position, 'Invalid character escape sequence: ${String.fromCharCode(code)}.');
				}
				++position;
				chunkStart = position;
			}
		}

		throw syntaxError(source, position, 'Unterminated string.');
	}

	/**
	 * Reads a block string token from the source file.
	 *
	 * """("?"?(\\"""|\\(?!=""")|[^"\\]))*"""
	 */
	public function readBlockString(source:Source, start, line, col, prev, lexer):Token {
		var body = source.body;
		var position = start + 3;
		var chunkStart = position;
		var code = 0;
		var rawValue = '';

		while (position < body.length && !Math.isNaN((code = body.charCodeAt(position)))) {
			// Closing Triple-Quote (""")
			if (code == 34 && body.charCodeAt(position + 1) == 34 && body.charCodeAt(position + 2) == 34) {
				rawValue += body.slice(chunkStart...position);
				return new Token(BLOCK_STRING, start, position + 3, line, col, prev, BlockString.dedentBlockStringValue(rawValue));
			}

			// SourceCharacter
			if (code < 0x0020 && code != 0x0009 && code != 0x000a && code != 0x000d) {
				throw syntaxError(source, position, 'Invalid character within String: ${printCharCode(code)}.');
			}

			if (code == 10) {
				// new line
				++position;
				++lexer.line;
				lexer.lineStart = position;
			} else if (code == 13) {
				// carriage return
				if (body.charCodeAt(position + 1) == 10) {
					position += 2;
				} else {
					++position;
				}
				++lexer.line;
				lexer.lineStart = position;
			} else if ( // Escape Triple-Quote (\""")
				code == 92
				&& body.charCodeAt(position + 1) == 34
				&& body.charCodeAt(position + 2) == 34
				&& body.charCodeAt(position + 3) == 34) {
				rawValue += body.slice(chunkStart...position) + '"""';
				position += 4;
				chunkStart = position;
			} else {
				++position;
			}
		}

		throw syntaxError(source, position, 'Unterminated string.');
	}

	/**
	 * Returns the new position in the source after reading digits.
	 */
	public function readDigits(source:Source, start, firstCode) {
		var body = source.body;
		var position = start;
		var code = firstCode;
		if (code >= 48 && code <= 57) {
			// 0 - 9
			do {
				code = body.charCodeAt(++position);
			} while (code >= 48 && code <= 57); // 0 - 9
			return position;
		}
		throw syntaxError(source, position, 'Invalid number, expected digit but got: ${printCharCode(code)}.');
	}

	/**
	 * Converts four hexadecimal chars to the integer that the
	 * string represents. For example, uniCharCode('0','0','0','f')
	 * will return 15, and uniCharCode('0','0','f','f') returns 255.
	 *
	 * Returns a negative number on error, if a char was invalid.
	 *
	 * This is implemented by noting that char2hex() returns -1 on error,
	 * which means the result of ORing the char2hex() will also be negative.
	 */
	function uniCharCode(a, b, c, d) {
		return ((char2hex(a) << 12) | (char2hex(b) << 8) | (char2hex(c) << 4) | char2hex(d));
	}

	/**
	 * Converts a hex character to its integer value.
	 * '0' becomes 0, '9' becomes 9
	 * 'A' becomes 10, 'F' becomes 15
	 * 'a' becomes 10, 'f' becomes 15
	 *
	 * Returns -1 on error.
	 */
	function char2hex(a) {
		return a >= 48 && a <= 57 ? a - 48 // 0-9
			: a >= 65 && a <= 70 ? a - 55 // A-F
			: a >= 97 && a <= 102 ? a - 87 // a-f
			: -1;
	}

	/**
	 * Reads an alphanumeric + underscore name from the source.
	 *
	 * [_A-Za-z][_0-9A-Za-z]*
	 */
	public function readName(source:Source, start, line, col, prev):Token {
		var body = source.body;
		var bodyLength = body.length;
		var position = start + 1;
		var code = 0;
		while (position != bodyLength && !Math.isNaN((code = body.charCodeAt(position))) && (code == 95 || // _
			(code >= 48 && code <= 57) || // 0-9
			(code >= 65 && code <= 90) || // A-Z
			(code >= 97 && code <= 122)) // a-z
		) {
			++position;
		}
		return new Token(NAME, start, position, line, col, prev, body.slice(start...position));
	}

	public function syntaxError(source:Source, position:Int, msg:String):GraphQLError {
		return Parser.syntaxError(source, position, msg);
	}

	// _ A-Z a-z
	function isNameStart(code):Bool {
		return (code == 95 || (code >= 65 && code <= 90) || (code >= 97 && code <= 122));
	}
}
