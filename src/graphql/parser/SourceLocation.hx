package graphql.parser;

import graphql.parser.AST.Location;

/**
 * Represents a location in a Source.
 */
typedef TSourceLocation = {
	line:Int,
	column:Int
}

@:forward(line, column)
abstract SourceLocation(TSourceLocation) from TSourceLocation to TSourceLocation {
	inline function new(t:TSourceLocation)
		this = t;

	public static function getLocation(source:Source, position:Int):SourceLocation {
		final lineRegexp = ~/\r\n|[\n\r]/g;
		var line = 1;
		var column = position + 1;
		var match;
		if (lineRegexp.match(source.body) && lineRegexp.matchedPos().pos < position) {
			line += 1;
			column = position + 1 - (lineRegexp.matchedPos().pos + lineRegexp.matched(0).length);
		}
		return {
			line: line,
			column: column
		};
	}

	public static function printLocation(location:Location):String {
		return printSourceLocation(location.source, getLocation(location.source, location.start));
	}

	public static function printSourceLocation(source:Source, sourceLocation:SourceLocation):String {
		return "";
	}
}
