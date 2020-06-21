package graphql;

using StringTools;

class BlockString {
	public static function dedentBlockStringValue(rawString:String):String {
		// Expand a block string's raw value into independent lines.
		var r = ~/\r\n|[\n\r]/g;
		final lines = r.split(rawString);
		// Remove common indentation from all lines but first.
		final commonIndent = getBlockStringIndentation(lines);
		if (commonIndent != 0) {
			for (i in 1...lines.length) {
				lines[i] = lines[i].substr(commonIndent);
			}
		}

		// Remove leading and trailing blank lines.
		while (lines.length > 0 && isBlank(lines[0])) {
			lines.shift();
		}

		while (lines.length > 0 && isBlank(lines[lines.length - 1])) {
			lines.pop();
		}

		// Return a string of the lines joined with U+000A.
		return lines.join('\n');
	}

	public static function getBlockStringIndentation(lines:Array<String>):Int {
		var commonIndent = null;

		for (i in 1...lines.length) {
			final line = lines[i];
			final indent = leadingWhitespace(line);
			if (indent == line.length) {
				continue; // skip empty lines
			}

			if (commonIndent == null || indent < commonIndent) {
				commonIndent = indent;
				if (commonIndent == 0) {
					break;
				}
			}
		}

		return commonIndent == null ? 0 : commonIndent;
	}

	static function leadingWhitespace(str:String) {
		var i = 0;
		while (i < str.length && (str.charAt(i) == ' ' || str.charAt(i) == '\t')) {
			i++;
		}
		return i;
	}

	static function isBlank(str) {
		return leadingWhitespace(str) == str.length;
	}

	public static function printBlockString(value:String, indentation:String = '', preferMultipleLines:Bool = false):String {
		final isSingleLine = value.indexOf('\n') == -1;
		final hasLeadingSpace = value.charAt(0) == ' ' || value.charAt(0) == '\t';
		final hasTrailingQuote = value.charAt(value.length - 1) == '"';
		final hasTrailingSlash = value.charAt(value.length - 1) == '\\';
        final printAsMultipleLines = !isSingleLine || hasTrailingQuote || hasTrailingSlash || preferMultipleLines;
        
        var result = '';
        // Format a multi-line block quote to account for leading space.
        if (printAsMultipleLines && !(isSingleLine && hasLeadingSpace)) {
            result += '\n' + indentation;
        }
        var r = ~/\n/g;
        var re = ~/\n/g;
		if (indentation != '' && re.match(value)) {
			value = re.map(value, function(r) {
				return '\n' + indentation;
			});
			result += value;
		} else {
			result += value;
		}

        if (printAsMultipleLines) {
            result += '\n';
        }
        var reg = ~/"""/g;
		if (reg.match(result)) {
			result = reg.map(result, function(r) {
				return '\\"""';
			});
		}
		return '"""' + result + '"""';
	}
}
