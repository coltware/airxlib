/**
 *  Copyright (c)  2009 coltware@gmail.com
 *  http://www.coltware.com 
 *
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 */
package com.coltware.airxlib.text {
	
	import com.coltware.airxlib.text.*;
    use namespace text_internal;
	
	public class TextNode {
		
		public static const SAME_TEXT:int = 1;
		public static const DEL_TEXT:int = 2;
		public static const ADD_TEXT:int   = 3;
		
		text_internal var $type:int;
    	text_internal var $start:int;
    	text_internal var $end:int;
		text_internal var $text:String;

		public function TextNode() {
		}
		
		public function getType():int{
			return $type;
		}
		
		public function get text():String{
			return $text;
		}
		
		public function toString():String{
			var str:String = $type + ":[" + $text + "](" + $start + "," + $end + ")";
			return str;
		}
	}
}