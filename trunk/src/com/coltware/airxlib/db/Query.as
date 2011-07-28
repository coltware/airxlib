package com.coltware.airxlib.db
{
	import flash.data.SQLConnection;
	import flash.data.SQLStatement;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class Query extends EventDispatcher
	{
		private var _conn:SQLConnection;
		private var _stmt:SQLStatement;
		
		public function Query(target:IEventDispatcher=null)
		{
			super(target);
			_stmt = new SQLStatement();
		}
		/**
		 *
		 */
		public function set sqlConnection(conn:SQLConnection):void{
			this._conn = conn;
		}
		
		public function get sqlConnection():SQLConnection{
			return this._conn;
		}
		
		public function set text(str:String):void{
			_stmt.text = str;
		}
		
		public function get text():String{
			return _stmt.text;
		}
		
		public function get parameters():Object{
			return this._stmt.parameters;
		}
		
		public function getFuture():IResultFuture{
			this._stmt.sqlConnection = this._conn;
			var future:IResultFuture = new ResultFuture(this._stmt);
			return future;
		}
	}
}