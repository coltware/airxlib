/**
 *  Copyright (c)  2011 coltware@gmail.com
 *  http://www.coltware.com 
 *
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 */
package com.coltware.airxlib.db.collection
{
	import com.coltware.airxlib.db.QueryParameter;
	
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.utils.Dictionary;
	
	import mx.collections.IList;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.core.ClassFactory;
	import mx.core.IPropertyChangeNotifier;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.FlexEvent;
	import mx.events.PropertyChangeEvent;
	import mx.events.PropertyChangeEventKind;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.utils.ObjectProxy;
	import mx.utils.ObjectUtil;
	import mx.utils.UIDUtil;
	
	//-----------------------------------------------------
	//  Events
	//-----------------------------------------------------
	[Event(name="collectionChange", type="mx.events.CollectionEvent")]
	
	public class TableList extends EventDispatcher 
		implements ITableList, IPropertyChangeNotifier
	{
		private static const log:ILogger = Log.getLogger("com.coltware.airxlib.db.collection.TableList");
		
		private var _conn:SQLConnection;
		private var _tableName:String;
		private var _itemClass:Class;
		private var _length:int = -1;
		private var _sort:Sort;
		
		private var _initCacheSize:int = 10;
		
		private var _pageSize:int = 5;
		
		private var _index_uid_prefix:String = "_internal_position";
		
		private var _lengthStmt:SQLStatement;
		
		private var _queryParameter:QueryParameter;
		
		private var _cache_idx:Array;
		private var _cache_dict:Dictionary;
		private var _cacheSize:int = 50;
		
		private var _uid:String;
		
		private var _lastSql:String = "";
		
		private var _initilizing:Boolean = false;
		
		private var _mode:String = "FETCH";
		
		private var _start_func:Function;
		
		/**
		 *  item object properties
		 */
		private var _properties:Array;
		
		public function TableList(mode:String = "FETCH")
		{
			this._mode = mode;
			_cache_idx = new Array();
			_cache_dict = new Dictionary();
		}
		
		public function get uid():String{
			if(_uid === null){
				_uid = UIDUtil.createUID();
			}
			return _uid;
		}
		
		public function set uid(val:String):void{
			this._uid = val;
		}
		
		//  ITableList functions
		
		public function start(func:Function = null):void{
			//  TOTAL件数を計算
			this._start_func = func;
			
			this._initilizing = true;
			if(this._mode == "ALL"){
				this._getInternalAll();
			}
			else{
				this._getInternalLength();
			}
		}
		
		public function isInitilizing():Boolean{
			return this._initilizing;
		}
		
		public function set sqlConnection(conn:SQLConnection):void{
			this._conn = conn;
		}
		/**
		 *  set table name
		 */
		public function set tableName(name:String):void{
			this._tableName = name;
		}
		
		public function set itemClass(v:Class):void{
			if(v){
				this._itemClass = v;
				this._properties = ObjectUtil.getClassInfo(v, null, {includeReadOnly:false}).properties;
			}
		}
		
		public function set queryParameter(v:QueryParameter):void{
			this._queryParameter = v;
		}
		
		public function get queryParameter():QueryParameter{
			return this._queryParameter;
		}
		
		public function set sort(s:Sort):void{
			this._sort = s;
		}
		
		public function get length():int
		{
			if(this._length < 0){
				log.debug("invoked getInternalLength()");
				if(this._initilizing){
					return 0;
				}
				if(this._mode == "ALL"){
					this._getInternalAll();
				}
				else{
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
			throw new Error("addItemAt() doesn't support");
		}
		
		public function addItemAt(item:Object, index:int):void
		{
			throw new Error("addItemAt() doesn't support");
		}
		
		public function getItemIndex(item:Object):int{
			
			if(item.hasOwnProperty("uid")){
				var uid:String = item.uid;
				var pos:int = uid.indexOf(this._index_uid_prefix);
				if(pos > -1){
					var num:String = uid.substr(pos + this._index_uid_prefix.length);
					return parseInt(num);
				}
				else{
					return -1;
				}
			}
			else{
				return -1;
			}
		}
		
		public function getItemAt(index:int, prefetch:int=0):Object
		{
			var ci:int = _cache_idx.lastIndexOf(index);
			if(ci > -1){
				var obj:Object = _cache_dict[index];
				return obj;
			}		
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = this._conn;
			stmt.addEventListener(SQLErrorEvent.ERROR,_handler_query_error);
			
			var order:String = "";
			if(this._sort && this._sort.fields && this._sort.fields.length > 0 ){
				var len:int = this._sort.fields.length;
				var _order_list:Array = new Array();
				for(var i:int = 0; i < len; i++){
					var sf:SortField = this._sort.fields[i];
					if(sf.descending){
						_order_list.push(sf.name + " DESC");
					}
					else{
						_order_list.push(sf.name + " ASC");
					}
				}
				order = " ORDER BY " + _order_list.join(" , ");
			}
			var where:String = this._get_where(stmt);
			
			stmt.text = "SELECT * FROM " + this._tableName + where + " " + order + " LIMIT 1 OFFSET " + index;
			
			this._lastSql = stmt.text;
			
			var proxy:ObjectProxy;
			var uid:String = this._index_uid_prefix + index;
			
			if(_itemClass){
				//log.debug("item class is " + _itemClass);
				var item:Object = new _itemClass();
				stmt.itemClass = _itemClass;
				proxy = new ObjectProxy(item,uid);	
			}
			else{
				proxy = new ObjectProxy(null,uid);
			}
			
			_cache_dict[index] = proxy;
			_cache_idx.push(index);
			
			var resultFunc:Function = function(evt:SQLEvent):void{
				log.debug("getItemAt(" + index + "): " + stmt.text);
				var result:SQLResult = stmt.getResult();
				var ret:Object = result.data[0];
				
				var key:String;
				
				if(_itemClass){
					for(var i:int = 0; i < _properties.length; i++){
						key = _properties[i];
						proxy[key] = ret[key];
					}
				}
				else{
					log.debug("no item class");
					for(key in ret){
						proxy[key] = ret[key];
					}
				}

				var changeEvent:PropertyChangeEvent = new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE);
				changeEvent.kind = PropertyChangeEventKind.UPDATE;
				//changeEvent.property = index; ????
				//changeEvent.source = proxy; ???? 
				
				dispatchEvent(changeEvent);
				
				var collectEvent:CollectionEvent = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE);
				collectEvent.kind = CollectionEventKind.REPLACE;
				collectEvent.location = index;
				
				dispatchEvent(collectEvent);
				
				stmt.removeEventListener(SQLEvent.RESULT,resultFunc);
			}
			stmt.addEventListener(SQLEvent.RESULT,resultFunc);
			//log.debug("sql:" + stmt.text);
			stmt.execute();
			return proxy;
		}
		
		public function itemUpdated(item:Object, property:Object=null, oldValue:Object=null, newValue:Object=null):void
		{
		}
		
		public function removeAll():void
		{
			// NO Support removeAll()
			throw new Error("removeAll()  doesn't support");
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
		
		private function _get_where(stmt:SQLStatement):String{
			var where_array:Array = new Array();
			if(_queryParameter){
				if(_queryParameter.systemWhere){
					where_array.push("(" + _queryParameter.systemWhere + ")");
				}
				if(_queryParameter.where){
					where_array.push(_queryParameter.where);
				}
				
				if(_queryParameter.args){
					if(_queryParameter.args is Array){
						for(var i:int=0; i<_queryParameter.args.length; i++){
							stmt.parameters[i] = _queryParameter.args[i];
						}
					}
					else if(ObjectUtil.isDynamicObject(_queryParameter.args)){
						for(var key:String in _queryParameter.args){
							stmt.parameters[":" + key] = _queryParameter.args[key];
						}
					}
					else{
						stmt.parameters[0] = _queryParameter.args;
					}
				}
			}
			
			if(where_array.length > 0){
				return " WHERE " + where_array.join(" AND ");
			}
			return "";
		}
		
		public function refresh():void{
			this._cache_idx.length = 0;
			this._cache_dict = new Dictionary();
			
			this._getInternalLength();
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
			var sql:String = "SELECT count(*) as count FROM " + this._tableName;
			var where:String = "";
			
			
			if(_queryParameter){
				where = this._get_where(_lengthStmt);
				_lengthStmt.text = sql + where;
			}
			else{
				_lengthStmt.text = sql;
			}
			
			log.debug("_getInternalLength() : get length:" + _lengthStmt.text);
			_lastSql = _lengthStmt.text;
			_lengthStmt.execute();
		}
		
		private function _getInternalAll():void{
			if(!_lengthStmt){
				_lengthStmt = new SQLStatement();
				_lengthStmt.itemClass = this._itemClass;
				_lengthStmt.sqlConnection = this._conn;
				_lengthStmt.addEventListener(SQLEvent.RESULT,_handler_get_all);
				_lengthStmt.addEventListener(SQLErrorEvent.ERROR,_handler_query_error);
			}
			var sql:String = "SELECT * FROM " + this._tableName;
			var where:String = "";
			
			
			if(_queryParameter){
				where = this._get_where(_lengthStmt);
				_lengthStmt.text = sql + where;
			}
			else{
				_lengthStmt.text = sql;
			}
			
			log.debug("_getInternalLength() : get length:" + _lengthStmt.text);
			_lastSql = _lengthStmt.text;
			_lengthStmt.execute();
		}
		
		private function _handler_get_total(evt:SQLEvent):void{
			log.debug("handler_get_total...");
			var result:SQLResult = _lengthStmt.getResult();
			if(result && result.data){
				
				if(this._length < 0 ){
					log.debug("list init complete...");
					this._length = result.data[0]["count"];
					
					//  最初なので、内部キャッシュサイズを取得する
					if(this._initCacheSize > 0 ){
						
					}
					if(this._start_func is Function){
						this._start_func.call();
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
		
		private function _handler_get_all(evt:SQLEvent):void{
			var result:SQLResult = _lengthStmt.getResult();
			if(result && result.data){
				
				var length:int = result.data.length;
				
				for(var i:int = 0; i<length; i++){
					_cache_dict[i] = result.data[i];
					_cache_idx.push(i);
				}
				
				
				
				if(this._length < 0){
					this._length = result.data.length;
					var flexEvent:FlexEvent = new FlexEvent(FlexEvent.INIT_COMPLETE);
					dispatchEvent(flexEvent);
					
					if(this._start_func is Function){
						this._start_func.call();
					}
					
				}
				else{
					this._length = result.data.length;
				}
				
				var collectEvent:CollectionEvent = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE);
				collectEvent.kind = CollectionEventKind.RESET;
				dispatchEvent(collectEvent);
				
				this._initilizing = false;
				
			}
		}
		
		private function _handler_query_error(event:SQLErrorEvent):void{
			log.warn("SQL Error:" + event.text + "[" + this._lastSql  + "]");
			log.warn(event.error.getStackTrace());
		}
		
	}
}