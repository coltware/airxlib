/**
 *  Copyright (c)  2011 coltware@gmail.com
 *  http://www.coltware.com 
 *
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 */
package com.coltware.airxlib.db
{
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	public class QueryParameter
	{
		
		private static const log:ILogger = Log.getLogger("com.coltware.commons.db.QueryParameter");
		
		/**
		 *  WHERE
		 */
		public var where:String = null;
		public var systemWhere:String = null;
		public var order:String = null;
		public var limit:int = -1;
		public var offset:int = -1;
		public var fields:String = "*";
		/**
		 *  引数となる値
		 */
		public var args:Object;
		
		private var _cond:Array;
		private var _argsArr:Array;
		
		public function QueryParameter(){
			_cond = new Array();
			_argsArr = new Array();
		}
		
		public function parseSearchString(field:String,searchStrs:String):void{
			var arr:Array = searchStrs.split(/\s+/);
			
			for(var i:int = 0; i< arr.length; i++){
				var str:String = arr[i];
				var ch:String = str.charAt(0);
				var key:String = "key" + i;
				var c:String;
				if(ch == "-"){
					_argsArr.push("%" + str.substr(1) + "%");
					c = field + " NOT LIKE ?";
					_cond.push(c);
				}
				else{
					_argsArr.push("%"+str+"%");
					c = field + " LIKE ?";
					_cond.push(c);
				}
			}
			where = _cond.join(" AND ");
			args = _argsArr;
			log.debug("args " + _argsArr.join("*"));
		}
		
		public function clear():void{
			_cond = new Array();
			_argsArr = new Array();
		}
		
	}
}