package graphql.parser;

enum abstract TokenEnum(String) from String to String {
    var SOF;
    var EOF;
    var BANG;
    var DOLLAR;
    var AMP;
    var PAREN_L;
    var PAREN_R;
    var SPREAD;
    var COLON;
    var EQUALS;
    var AT;
    var BRACKET_L;
    var BRACKET_R;
    var BRACE_L;
    var BRACE_R;
    var PIPE;
    var NAME;
    var INT;
    var FLOAT;
    var STRING;
    var BLOCK_STRING;
    var COMMENT;
}