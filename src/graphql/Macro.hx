package graphql;

import haxe.macro.Expr;
using haxe.macro.ExprTools;

class Macro {
    macro static public function ASSERT(condition:Expr, message:Expr):Expr {
		var s:String = condition.toString();
		var p = condition.pos;
		var el = [];
		var descs = [];
		function add(e:Expr, s:String) {
			var v = "_tmp" + el.length;
			el.push(macro var $v = $e);
			descs.push(s);
			return v;
		}
		function map(e:Expr) {
			return switch (e.expr) {
				case EConst((CInt(_) | CFloat(_) | CString(_) | CRegexp(_) | CIdent("true" | "false" | "null"))):
					e;
				case _:
					var s = e.toString();
					e = e.map(map);
					macro $i{add(e, s)};
			}
		}
		var e = map(condition);
		var a = [for (i in 0...el.length) macro {expr: $v{descs[i]}, value: $i{"_tmp" + i}}];
		el.push(macro if (!$e)
			@:pos(p) throw new AssertionFailure($message, $a{a}));
		return macro $b{el};
    }

}

private typedef AssertionPart = {
	expr:String,
	value:Dynamic
}

class AssertionFailure {
	public var message(default, null):String;
	public var parts(default, null):Array<AssertionPart>;

	public function new(message:String, parts:Array<AssertionPart>) {
		this.message = message;
		this.parts = parts;
	}

	public function toString() {
		var buf = new StringBuf();
		buf.add("Assertion failure: " + message);
		for (part in parts) {
			buf.add("\n\t" + part.expr + ": " + part.value);
		}
		return buf.toString();
	}
}