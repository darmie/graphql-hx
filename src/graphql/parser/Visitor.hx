package graphql.parser;


/**
 * A visitor is provided to visit, it contains the collection of
 * relevant functions to be called during the visitor's traversal.
 */
typedef ASTVisitor = Visitor<ASTKindToNode>;



typedef EnterLeave<T> = { ?enter: T, ?leave: T};