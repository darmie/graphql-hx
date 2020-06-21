package graphql;

import graphql.Macro.ASSERT;
import graphql.Macro.AssertionFailure;

private typedef Location = {
    line: Int,
    column: Int
}

/**
 * 
 * A representation of source input to GraphQL.
 * `name` and `locationOffset` are optional. They are useful for clients who
 * store GraphQL documents in source files; for example, if the GraphQL input
 * starts at line 40 in a file named Foo.graphql, it might be useful for name to
 * be "Foo.graphql" and location to be `{ line: 40, column: 0 }`.
 * line and column in locationOffset are 1-indexed
 */
class Source {
    public var body:StringSlice;
    public var name:String;
    public var locationOffset:Location;

   

    public function new(body:String, name:String = 'GraphQL request', ?locationOffset:Location) {
        if(locationOffset == null) this.locationOffset = {line: 1, column: 1};
        else this.locationOffset = locationOffset;
        this.body = StringSlice.ofString(body);
        this.name = name;

        var line  = this.locationOffset.line;
        var col = this.locationOffset.column;

        ASSERT(line > 0, 'line in locationOffset is 1-indexed and must be positive.');
        ASSERT(col > 0, 'column in locationOffset is 1-indexed and must be positive.');

    }

    public function toString():String {
        return "Source";
    }
}