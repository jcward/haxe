/*
 * Copyright (c) 2005-2008, The haXe Project Contributors
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package flash;

#if !as3
private class RealBoot extends Boot, implements Dynamic {
	#if swc
	public function new() {
		super();
	}
	public static function init(mc) {
		flash.Lib.current = mc;
		new RealBoot().init();
	}
	#else
	function new() {
		super();
		if( flash.Lib.current == null ) flash.Lib.current = this;
		start();
	}
	#end
}
#end

class Boot extends flash.display.MovieClip {

	static var tf : flash.text.TextField;
	static var lines : Array<String>;
	static var lastError : flash.errors.Error;

	public static var skip_constructor = false;

	function start() {
		#if (mt && !doc_gen) mt.flash.Init.check(); #end
		#if dontWaitStage
			init();
		#else
			var c = flash.Lib.current;
			try {
				untyped if( c == this && c.stage != null && c.stage.align == "" )
					c.stage.align = "TOP_LEFT";
			} catch( e : Dynamic ) {
				// security error when loading from different domain
			}
			if( c.stage == null )
				c.addEventListener(flash.events.Event.ADDED_TO_STAGE, doInitDelay);
			else if( c.stage.stageWidth == 0 )
				untyped __global__["flash.utils.setTimeout"](start,1);
			else
				init();
		#end
	}

	function doInitDelay(_) {
		flash.Lib.current.removeEventListener(flash.events.Event.ADDED_TO_STAGE, doInitDelay);
		start();
	}

	#if (swc && swf_protected) public #end function init() {
		throw "assert";
	}

	public static function enum_to_string( e : { tag : String, params : Array<Dynamic> } ) {
		if( e.params == null )
			return e.tag;
		var pstr = [];
		for( p in e.params )
			pstr.push(__string_rec(p,""));
		return e.tag+"("+pstr.join(",")+")";
	}

	public static function __instanceof( v : Dynamic, t : Dynamic ) {
		try {
			if( t == Dynamic )
				return true;
			return untyped __is__(v,t);
		} catch( e : Dynamic ) {
		}
		return false;
	}

	public static function __clear_trace() {
		if( tf == null )
			return;
		tf.parent.removeChild(tf);
		tf = null;
		lines = null;
	}

	public static function __set_trace_color(rgb) {
		var tf = getTrace();
		tf.textColor = rgb;
		tf.filters = [];
	}

	public static function getTrace() {
		var mc = flash.Lib.current;
		if( tf == null ) {
			tf = new flash.text.TextField();
			#if flash10_2
			var color = 0xFFFFFF, glow = 0;
			if( mc.stage != null ) {
				glow = mc.stage.color;
				color = 0xFFFFFF - glow;
			}
			tf.textColor = color;
			tf.filters = [new flash.filters.GlowFilter(glow, 1, 2, 2, 20)];
			#end
			var format = tf.getTextFormat();
			format.font = "_sans";
			tf.defaultTextFormat = format;
			tf.selectable = false;
			tf.width = if( mc.stage == null ) 800 else mc.stage.stageWidth;
			tf.autoSize = flash.text.TextFieldAutoSize.LEFT;
			tf.mouseEnabled = false;
		}
		if( mc.stage == null )
			mc.addChild(tf);
		else
			mc.stage.addChild(tf); // on top
		return tf;
	}

	public static function __trace( v : Dynamic, pos : haxe.PosInfos ) {
		var tf = getTrace();
		var pstr = if( pos == null ) "(null)" else pos.fileName+":"+pos.lineNumber;
		if( lines == null ) lines = [];
		lines = lines.concat((pstr +": "+__string_rec(v,"")).split("\n"));
		tf.text = lines.join("\n");
		var stage = flash.Lib.current.stage;
		if( stage == null )
			return;
		while( lines.length > 1 && tf.height > stage.stageHeight ) {
			lines.shift();
			tf.text = lines.join("\n");
		}
	}

	public static function __string_rec( v : Dynamic, str : String ) {
		var cname = untyped __global__["flash.utils.getQualifiedClassName"](v);
		switch( cname ) {
		case "Object":
			var k : Array<String> = untyped __keys__(v);
			var s = "{";
			var first = true;
			for( i in 0...k.length ) {
				var key = k[i];
				if( key == "toString" )
					try return v.toString() catch( e : Dynamic ) {}
				if( first )
					first = false;
				else
					s += ",";
				s += " "+key+" : "+__string_rec(v[untyped key],str);
			}
			if( !first )
				s += " ";
			s += "}";
			return s;
		case "Array":
			if( v == Array )
				return "#Array";
			var s = "[";
			var i;
			var first = true;
			var a : Array<Dynamic> = v;
			for( i in 0...a.length ) {
				if( first )
					first = false;
				else
					s += ",";
				s += __string_rec(a[i],str);
			}
			return s+"]";
		default:
			switch( untyped __typeof__(v) ) {
			case "function": return "<function>";
			}
		}
		return new String(v);
	}

	static function __unprotect__( s : String ) {
		return s;
	}


	static function __init__() untyped {
		var aproto = Array.prototype;
		aproto.copy = function() {
			return __this__.slice();
		};
		aproto.insert = function(i,x) {
			__this__.splice(i,0,x);
		};
		aproto.remove = function(obj) {
			var idx = __this__.indexOf(obj);
			if( idx == -1 ) return false;
			__this__.splice(idx,1);
			return true;
		}
		aproto.iterator = function() {
			var cur = 0;
			var arr : Array<Dynamic> = __this__;
			return {
				hasNext : function() {
					return cur < arr.length;
				},
				next : function() {
					return arr[cur++];
				}
			}
		};
		aproto.setPropertyIsEnumerable("copy", false);
		aproto.setPropertyIsEnumerable("insert", false);
		aproto.setPropertyIsEnumerable("remove", false);
		aproto.setPropertyIsEnumerable("iterator", false);
		String.prototype.charCodeAt = function(i) : Null<Int> {
			var s : String = __this__;
			var x : Float = s.cca(i);
			if( __global__["isNaN"](x) )
				return null;
			return Std.int(x);
		};
	}

}
