package com.coltware.airxlib.db.collection
{
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.utils.Dictionary;
	
	import mx.collections.IList;
	import mx.collections.ISort;
	import mx.collections.ISortField;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.FlexEvent;
	import mx.events.PropertyChangeEvent;
	import mx.events.PropertyChangeEventKind;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.utils.ObjectProxy;
	import mx.utils.ObjectUtil;
	
	public class QueryList extends EventDispatcher implements IList
	{
		private static const log:ILogger = Log.getLogger("com.coltware.airxlib.db.collection.QueryList");
		
		private var _cache_idx:Array;
		private var _cache_dict:Dictionary;
		
		private var _sql_text:String;
		private var _sql_pre_text:String;
		private var _lengthStmt:SQLStatement;
		private var _conn:SQLConnection;
		private var _sort:ISort;
		
		private var _itemClass:Class;
		private var _parameters:Object;
		
		private var _start_func:Function;
		private var _initilizing:Boolean = false;
		
		private var _length:int = -1;
		
		private var _properties:Array;
		
		public function QueryList(target:IEventDispatcher=null)
		{
			super(target);
			_cache_idx = new Array();
			_cache_dict = new Dictionary();
			_parameters = new Object();
		}
		
		public function set text(sql:String):void{
			var _text:String = sql.toUpperCase();
			var pos:int = _text.indexOf("FROM");
			this._sql_pre_text = sql.substr(0,pos);
			this._sql_text = sql.substr(pos);
			
			log.debug("SQL1:[" + this._sql_pre_text  +"]");
			log.debug("SQL2:[" + this._sql_text + "]");
		}
		
		public function get parameters():Object{
			return this._parameters;
		}
		
		public function set sqlConnection(conn:SQLConnection):void{
			this._conn = conn;
		}
		
		public function set itemClass(clz:Class):void{
			if(clz){
				this._itemClass = clz;
				this._properties = ObjectUtil.getClassInfo(clz, null, {includeReadOnly:false}).properties;
			}
		}
		
		public function set sort(s:ISort):void{
			this._sort = s;
		}
		
		public function get length():int
		{
			if(this._length < 0){
				if(this._conn && this._sql_text){
					this._getInternalLength();
				}
				return 0;
			}
			else{
				return this._length;
			}
		}
		
		public function addItem(item:Object):void
		{
		}
		
		public function addItemAt(item:Object, index:int):void
		{
		}
		
		public function getItemAt(index:int, prefetch:int=0):Object
		{
			log.debug("getItemAt..." + index);
			
			var ci:int = _cache_idx.lastIndexOf(index);
			if(ci > -1){
				var obj:Object = _cache_dict[index];
				return obj;
			}
			
			var stmt:SQLStatement = new SQLStatement;
			stmt.sqlConnection = this._conn;
			stmt.addEventListener(SQLErrorEvent.ERROR,_handler_query_error);
			
			var order:String = "";
			if(this._sort && this._sort.fields && this._sort.fields.length > 0){
				var len:int = this._sort.fields.length;
				var _order_list:Array =	new Array();
				for(var i:int = 0; i<len; i++){
					var sf:ISortField = this._sort.fields[i];
					if(sf.descending){
						_order_list.push(sf.name + " DESC");
					}
					else{
						_order_list.push(sf.name + " ASC");
					}
				}
				order = " ORDER BY " + _order_list.join(" , ");
			}
			stmt.text = this._sql_pre_text + this._sql_text +  order +  " LIMIT 1 OFFSET " + index;
			log.debug("sql ..." + stmt.text);
			
			for(var param_key:String in this._parameters){
				stmt.parameters[param_key] = _parameters[param_key];
			}
			
			var uid:String = "_query_list_" + index;
			
			var proxy:ObjectProxy;
			
			if(this._itemClass){
				var msg:Object = new _itemClass();
				//stmt.itemClass = _itemClass;
				proxy = new ObjectProxy(msg,uid);
			}
			else{
				proxy = new ObjectProxy(null,uid);
			}
			var resultFunc:Function = function(evt:SQLEvent):void{
				var result:SQLResult = stmt.getResult();
				var ret:Object;
				if(result.data && result.data[0]){
					ret = result.data[0];
				}
				else{
					return;
				}
				
				var key:String;
				if(_itemClass){
					for(var i:int = 0; i < _properties.length; i++){
						key = _properties[i];
						if(ret.hasOwnProperty(key)){
							proxy[key] = ret[key];
						}
					}
				}
				else{
					log.debug("no item class");
					for(key in ret){
						proxy[key] = ret[key];
					}
				}
				
				_cache_dict[index] = proxy;
				_cache_idx.push(index);
				
				var collectEvent:CollectionEvent = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE);
				collectEvent.kind = CollectionEventKind.REPLACE;
				collectEvent.location = index;
				dispatchEvent(collectEvent);
				
				stmt.removeEventListener(SQLEvent.RESULT,resultFunc);
			}
			stmt.addEventListener(SQLEvent.RESULT,resultFunc);
			stmt.execute();
			return proxy;
		}
		
		public function getItemIndex(item:Object):int
		{
			return 0;
		}
		
		public function itemUpdated(item:Object, property:Object=null, oldValue:Object=null, newValue:Object=null):void
		{
		}
		
		public function removeAll():void
		{
		}
		
		public function removeItemAt(index:int):Object
		{
			return null;
		}
		
		public function setItemAt(item:Object, index:int):Object
		{
			return null;
		}
		
		public function toArray():Array
		{
			return null;
		}
		
		public function start(func:Function = null):void{
			this._start_func = func;
			this._initilizing = true;
			this._getInternalLength();
		}
		
		public function refresh():void{
			
		}
		
		public function dispose():void{
			this._conn = null;
			this._lengthStmt = null;
		}
		
		/**
		 * 内部のlengthを計算するための処理
		 */
		private function _getInternalLength():void{
			if(_lengthStmt){
				_lengthStmt.itemClass = null;
			}
			else{
				_lengthStmt = new SQLStatement();
				_lengthStmt.sqlConnection = this._conn;
				_lengthStmt.addEventListener(SQLEvent.RESULT,_handler_get_total);
				_lengthStmt.addEventListener(SQLErrorEvent.ERROR,_handler_query_error);
			}
			var _pre_text:String = this._sql_pre_text.toLowerCase();
			var distinct:int = _pre_text.indexOf("distinct");
			var count:String = "count(*)";
			if(distinct > 0){
				var pos1:int = _pre_text.indexOf("(",distinct);
				var pos2:int = _pre_text.indexOf(")",distinct);
				count = "count( DISTINCT " + _sql_pre_text.substring(pos1 + 1,pos2) + ")";
			}
			var sql:String  = "SELECT " + count + " as count " + this._sql_text;
			
			var order:String = "";
			if(this._sort && this._sort.fields && this._sort.fields.length > 0){
				var len:int = this._sort.fields.length;
				var _order_list:Array =	new Array();
				for(var i:int = 0; i<len; i++){
					var sf:ISortField = this._sort.fields[i];
					if(sf.descending){
						_order_list.push(sf.name + " DESC");
					}
					else{
						_order_list.push(sf.name + " ASC");
					}
				}
				order = " ORDER BY " + _order_list.join(" , ");
			}
			
			_lengthStmt.text = sql + order;
			log.debug("total sql " + _lengthStmt.text);
			
			for(var param_key:String in this._parameters){
				_lengthStmt.parameters[param_key] = _parameters[param_key];
			}
			
			if(!_lengthStmt.executing){
				_lengthStmt.execute();
			}
		}
		
		private function _handler_get_total(event:SQLEvent):void{
			log.debug("_handler_get_total");
			var result:SQLResult = _lengthStmt.getResult();
			if(result && result.data){
				
				if(this._length < 0 ){
					this._length = result.data[0]["count"];
					
					log.debug("list init complete... " + this._length);
					
					if(this._start_func is Function){
						log.debug("invoked start function");
						this._start_func.call();
						this._start_func = null;
					}
					
					var flexEvent:FlexEvent = new FlexEvent(FlexEvent.INIT_COMPLETE);
					dispatchEvent(flexEvent);
				}
				else{
					this._length = result.data[0]["count"];
				}
				
				log.debug("_handler_get_total ... length is [" + this._length + "]");
				
				var collectEvent:CollectionEvent = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE);
				collectEvent.kind = CollectionEventKind.RESET;
				dispatchEvent(collectEvent);
				
				this._initilizing = false;
			}
		}
		
		private function _handler_query_error(event:SQLErrorEvent):void{
			var stmt:SQLStatement = event.currentTarget as SQLStatement;
			log.warn("SQL Error:" + event.text + "[" + stmt.text  + "]");
			log.warn(event.error.getStackTrace());
		}
	}
}