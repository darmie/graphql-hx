package graphql;

import haxe.ds.ReadOnlyArray;
import graphql.AST.ASTNode;

class GraphQLError /*extends haxe.Exception*/ {

	var message:String;

	/**
	 * An array of { line, column } locations within the source GraphQL document
	 * which correspond to this error.
	 *
	 * Errors during validation often contain multiple locations, for example to
	 * point out two things with the same name. Errors during execution include a
	 * single location, the field which produced the error.
	 *
	 * Enumerable, and appears in the result of JSON.stringify().
	 */
	var locations:ReadOnlyArray<SourceLocation>;

	/**
	 * An array describing the JSON-path into the execution response which
	 * corresponds to this error. Only included for errors during execution.
	 *
	 * Enumerable, and appears in the result of JSON.stringify().
	 */
	var path:ReadOnlyArray<Any>;

	/**
	 * An array of GraphQL AST Nodes corresponding to this error.
	 */
	var nodes:ReadOnlyArray<ASTNode>;

	/**
	 * The source GraphQL document for the first location of this error.
	 *
	 * Note that if this Error represents more than one node, the source may not
	 * represent nodes after the first node.
	 */
	var source:Source;

	/**
	 * An array of character offsets within the source GraphQL document
	 * which correspond to this error.
	 */
	var positions:ReadOnlyArray<Int>;

	/**
	 * The original error thrown from a field resolver during execution.
	 */
	var originalError:Dynamic;

	/**
	 * Extension fields to add to the formatted error.
	 */
	var extensions:Dynamic;

	public function new(message:String, ?nodes:ReadOnlyArray<ASTNode>, ?source:Source, ?positions:ReadOnlyArray<Int>, ?path:ReadOnlyArray<Any>,
			?originalError:Dynamic, ?extensions:Dynamic) {
		this.nodes = nodes;

		this.message = message;

		if (source == null && nodes != null)
			this.source = nodes[0].loc != null ? nodes[0].loc.source : new Source("");

		if (positions == null && nodes != null) {
			this.positions = reduce(nodes, (list : Array<Int>, node : ASTNode) -> {
				if (node.loc != null) {
					list.push(node.loc.start);
				}
				return list;
			}, []);
		}
		if (positions != null && positions.length == 0) {
			this.positions = null;
		}

		if (positions != null && source != null) {
			this.locations = positions.map((pos) -> SourceLocation.getLocation(source, pos));
		} else if (nodes != null) {

			this.locations = reduce(nodes, (list : Array<SourceLocation>, node : ASTNode) -> {
				if (node.loc != null) {
					list.push(SourceLocation.getLocation(node.loc.source, node.loc.start));
				}
				return list;
			}, []);
		}

		// super(message);
	}

	public function toString():String {
		// var s = super.toString();
		return '$message : ${printError(this)}';
	}

	public static function printError(error:GraphQLError) {
		var output = "";

		if (error.nodes != null) {
			for (node in error.nodes) {
				if (node.loc != null) {
					output += '\n\n' + SourceLocation.printLocation(node.loc);
				}
			}
		} else if (error.source != null && error.locations != null) {
			for (location in error.locations) {
				output += '\n\n' + SourceLocation.printSourceLocation(error.source, location);
			}
		}

		return output;
	}

	public function reduce<K, T>(arr:ReadOnlyArray<K>, callback:(acc:Array<T>, v:K) -> Array<T>, accumulator:Array<T>) {
		for (i in 0...arr.length) {
			accumulator = callback(accumulator, arr[i]);
		}
		return accumulator;
	}
}


