/**
 *  Copyright (c)  2009 coltware@gmail.com
 *  http://www.coltware.com 
 *
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 */
package com.coltware.airxlib.db
{
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.errors.IllegalOperationError;
	import flash.errors.SQLError;
	import flash.events.EventDispatcher;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	
	import mx.collections.ArrayCollection;
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	[Event(name="tableInsert",type="com.coltware.airxlib.db.TableEvent")]
	[Event(name="tableUpdate",type="com.coltware.airxlib.db.TableEvent")]
	[Event(name="tableDelete",type="com.coltware.airxlib.db.TableEvent")]
	[Event(name="tableChangeTotal",type="com.coltware.airxlib.db.TableEvent")]
	[Event(name="tableChange",type="com.coltware.airxlib.db.TableEvent")]
	
	public class Table extends EventDispatcher{
		
		private static const $__debug__:Boolean = false;
		private static const _log:ILogger = Log.getLogger("com.coltware.airxlib.db.Table");
		public static var debug:Boolean = false;
		
		protected var _conn:SQLConnection;
		protected var tableName:String;
		private var fields:Object;
		private var _xml:XML;
		private var _pkey:String;
		protected var _defaultItemClass:Class = null;
		
		public var lastSql:String = "";
		
		
		/*
		*  テーブルレコード数を保持する
		*/
		private var totalNum:Number;
		
		public static var FIELD_INTEGER:int = 1;
		public static var FIELD_TEXT:int = 2;
		public static var FIELD_DATE:int = 3;
		public static var FIELD_AUTO:int = -1;
		
		protected var _field_created_at:String = null;
		protected var _field_updated_at:String = null;
		
		
		/**
		 * 追加時に自動的にDate情報が入るフィールド
		 */ 
		public function setCreatedAtField(name:String):void{
			_field_created_at = name;
		}
		
		public function setUpdatedAtField(name:String):void{
			_field_updated_at = name;
		}
		
		
		
		/**
		 * 更新時に無視するフィールド
		 */
		private var ignoreUpdateField:ArrayCollection;
		
		public function Table() {
			this.ignoreUpdateField = new ArrayCollection();
			
		}
		public function set itemClass(clz:Class):void{
			this._defaultItemClass = clz;
		}
		
		public function get itemClass():Class{
			return this._defaultItemClass;
		}
		
		public function addUpdateIgnoreField(fname:String):void{
			this.ignoreUpdateField.addItem(fname);
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
		/**
		*  定義XMLの設定
		*/
		public function set xml(defxml:XML):void{
			this._xml = defxml;
		}
		
		public function getTableName():String{
			return this.tableName;
		}
		
		public function create():void{
			
			if(this._xml == null){
				throw new IllegalOperationError("xml is null");
			}
			tableName = this._xml.@name;
			fields = new Object();
			for each(var child:XML in this._xml.field){
				var name:String = child.@name;
				var type:String = child.@type;
				if(child.@auto_increment == "true"){
					fields[name] = FIELD_AUTO;
					_pkey = name;
					_log.debug("pkey is " + _pkey);
				}
				else{
					if(child.@primary == "true"){
						_pkey = name;
						_log.debug("pkey is " + _pkey);
					}
					fields[name] = getFieldType(type);
				}
				
			}
			this.afterCreate();
		}
		
		protected function afterCreate():void{
			
		}
		
		protected function insertBefore(item:Object):void{
			
		}
		
		/**
		 *  登録処理
		 */ 
		public function insertItem(raw:Object,func:Function = null):void{
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = _conn;
			
			if(raw == null){
				raw = new Object();
			}
			
			this.insertBefore(raw);
			
			var sql:String = "";
			var flds:Array = new Array();
			var data:Array = new Array();
			for(var fld:String in fields){
				
				if(_field_created_at && fld == _field_created_at){
					data.push(":" + fld);
					flds.push(fld);
					stmt.parameters[":" + fld] = new Date();
				}
				else if(_field_updated_at && fld == _field_updated_at){ 
					data.push(":" + fld);
					flds.push(fld);
					stmt.parameters[":" + fld] = new Date();
				}
				else{
				
				if(fields[fld] > 0 ){
					if(raw[fld] == null){
						// 登録時には NULL　は入れずに DBのdefaultに任せる
						//data.push("NULL");
						//flds.push(fld);
					}
					else{
						if(raw[fld]){
							var k:String = ":" + fld;
							data.push(k);
							flds.push(fld);
						
							stmt.parameters[k] = raw[fld];
							_log.debug(k + " => " + raw[fld]);
						}
					}
				}
				else{
					if($__debug__) _log.debug("field type is " + fld + ":" + fields[fld]);
				}
				}
			}
			sql = "INSERT INTO " + this.tableName + "\n(" +
			flds.join(",") + ") \n" + "VALUES(" + data.join(",") + ")";
			lastSql = sql;
			stmt.text = sql;
			
			var insertFunc:Function = function():void{
				var result:SQLResult = stmt.getResult();
				if(func != null){
					func(result);
				}
				fireInsertEvent(result);
				stmt.removeEventListener(SQLEvent.RESULT,insertFunc);
			};
			stmt.addEventListener(SQLEvent.RESULT,insertFunc);
			stmt.execute();
		}
		
		/**
		 *  INSERT EVENT
		 */
		protected function fireInsertEvent(result:SQLResult):void{
			
			var ne:TableEvent = new TableEvent(TableEvent.INSERT);
			ne.result = result;
			ne.tableObject = this;
			dispatchEvent(ne);
			
			var ch:TableEvent = new TableEvent(TableEvent.CHANGE_TOTAL);
			ch.result = result;
			ch.tableObject = this;
			dispatchEvent(ch);
			
			var evt:TableEvent = new TableEvent(TableEvent.TABLE_CHANGE);
			evt.result = result;
			evt.tableObject = this;
			dispatchEvent(evt);
			
			_log.debug("fireInsertEvent : dispatchInsertEvent - " + result.lastInsertRowID);
		}
		
		/**
		 *  更新処理
		 */
		public function updateSync(raw:Object,where:String,setNull:Boolean = false ):SQLStatement{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = _conn;
			stmt.addEventListener(SQLEvent.RESULT,fireUpdateEvent);
			
			if(raw == null){
				throw new IllegalOperationError("update object is NULL");
			}
			if(where == null || where.length < 1 ){
				throw new IllegalOperationError("where arg is NULL");
			}
			
			var sql:String = "";
			var flds:Array = new Array();
			var data:Array = new Array();
			for(var fld:String in fields){
				
				if(fld == _pkey){
					if(raw[fld] != null){
						stmt.parameters[":" + fld] = raw[fld];
						_log.debug("update [" + fld + "] => " + raw[fld]);
					}
				} 
				else if(fld == _field_created_at){
					// -- Do Nothing
				}
				else if(fld == _field_updated_at){
					data.push(fld + " = :" + fld);
					stmt.parameters[":" + fld] = new Date();
				}
				else{
				
				if(fields[fld] > 0 && !this.ignoreUpdateField.contains(fld)){
					if(raw[fld] == null){
						if(setNull == true){
							data.push(fld + " = NULL");
						}
					}
					else{
						data.push(fld + " = :" + fld);
						stmt.parameters[":" + fld] = raw[fld];
						_log.debug("update [" + fld + "] => " + raw[fld]);
					}
				}
				}
			}
			sql = "UPDATE " + this.tableName + "\n" +
			      " SET " + data.join(",\n") + "\n" +
			      " WHERE " + where;
			
			if($__debug__)_log.debug("sql: " + sql);
			
			lastSql = sql;
			stmt.text = sql;
			stmt.execute();
			return stmt;
		}
		
		protected function fireUpdateEvent(e:SQLEvent):void{
			var stmt:SQLStatement  = e.target as SQLStatement;
			var result:SQLResult = stmt.getResult();
			
			var ne:TableEvent = new TableEvent(TableEvent.UPDATE);
			ne.result = result;
			ne.tableObject = this;
			dispatchEvent(ne);
			
			var chg:TableEvent = new TableEvent(TableEvent.TABLE_CHANGE);
			chg.result = result;
			chg.tableObject = this;
			dispatchEvent(chg);
			
			if($__debug__)_log.debug("dispatchUpdateEvent - " + result.rowsAffected);
		}
		
		/**
		 *  アイテムを削除する
		 */
		public function deleteItem(item:Object,func:Function = null):void{
			
			if(item.hasOwnProperty(this._pkey)){
				var stmt:SQLStatement = new SQLStatement();
				stmt.sqlConnection = this._conn;
				
				var where:String = this._pkey + " = :" + this._pkey;
				var sql:String = "DELETE FROM " + this.tableName + " WHERE " + where;
				
				stmt.text = sql;
				stmt.parameters[":" + this._pkey] = item[this._pkey];
				
				var _deleteItemFunc:Function = function():void{
					var result:SQLResult = stmt.getResult();
					if(func != null){
						func(result);
					}
					fireDeleteEvent(result);
					stmt.removeEventListener(SQLEvent.RESULT,_deleteItemFunc);
				};
				stmt.addEventListener(SQLEvent.RESULT,_deleteItemFunc);
				stmt.execute();
			}
			else{
				// TODO エラー処理
			}
		}
		
		
		public function execDelete(where:String):void{
			if(where == null || where.length < 1 ){
				throw new IllegalOperationError("where is NULL");
			}
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = this._conn;
			stmt.addEventListener(SQLEvent.RESULT,fireDeleteEvent);
			var sql:String = "DELETE FROM " + this.tableName + " WHERE " + where;
			stmt.text = sql;
			lastSql = sql;
			stmt.execute();
		}
		
		/**
		 *   プライマリキーを指定し削除する
		 */ 
		public function execDeleteByPKey(pkey:Number):void{
			var where:String = this._pkey + " = " + pkey;
			this.execDelete(where);
		}
		
		public function fireDeleteEvent(result:SQLResult):void{
			
			var ne:TableEvent = new TableEvent(TableEvent.DELETE);
			ne.result = result;
			ne.tableObject = this;
			dispatchEvent(ne);
			
			var ch:TableEvent = new TableEvent(TableEvent.CHANGE_TOTAL);
			ch.result = result;
			ch.tableObject = this;
			dispatchEvent(ch);
			
			var chg:TableEvent = new TableEvent(TableEvent.TABLE_CHANGE);
			chg.result = result;
			chg.tableObject = this;
			dispatchEvent(chg);
			
			if(debug)_log.debug("dispatchUpdateEvent - " + result.rowsAffected);
		}
		
		/**
		 *  1レコードだけ取得する。
		 * 
		 *  resultFunc で登録した関数の中で、 handleGetRowを呼べば簡単にオブジェクトが取得できます。
		 */
		public function getRow(where:Object,resultFunc:Function,errorFunc:Function = null,clz:Class = null):SQLStatement{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = _conn;
			var ret:Boolean = false;
			
			stmt.addEventListener(SQLEvent.RESULT,resultFunc);
			if(errorFunc != null){
				stmt.addEventListener(SQLErrorEvent.ERROR,errorFunc);
			}
			
			var sql:String = "SELECT * FROM " + this.tableName;
			if(where != null){
				
				if(where is String){
					sql = sql + " WHERE " + where;
				}
				else{
				
				if(where.text != null){
					sql = sql + " WHERE " + where.text;
				}
				if(where.args != null ){
					if(where.args is String){
						stmt.parameters[1] = where.args;
					}
					else if(where.args is Number){
						stmt.parameters[1] = where.args;
					}
					else if(where.args is Array){
						var arr:Array = where.args;
						for(var key:String in arr){
							_log.debug("where args : " + key);
						}
					}
				}
				}
			}
			
			if(clz != null){
				stmt.itemClass = clz;
			}
			
			sql = sql + " LIMIT 1 ";
			stmt.text = sql;
			if($__debug__)_log.debug("SQL " + sql);
			stmt.execute();
			return stmt;
		}
		
		
		/**
		 *  getRow メソッド結果を簡単に取得するメソッド。
		 * SQLEvent.RESULTのイベント処理の中で呼ぶ。
		 * 
		 */
		public function getRowResult(result:SQLResult):Object{
			if(result != null && result.data != null){
				if(result.data.length > 0 ){
					return result.data[0];
				}
				else{
					return null;
				}
			}
			else{
				return null;
			}
		}
		
		
		/**
		 *  シンプルなSQLとDB接続を設定した上でSQLStatmentを返す。
		 *  
		 */  
		public function getStatement(where:String = null,order:String = null):IResultFuture{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = _conn;
			var sql:String = "SELECT * FROM " + this.tableName;
			if(where != null){
				sql = sql + " WHERE " + where;
			}
			if(order != null){
				sql += " ORDER BY " + order;
			}
			stmt.text = sql;
			var future:ResultFuture = new ResultFuture(stmt);
			return future;
		}
		
		/**
		 * テーブルのサイズを返す
		 */
		public function getTotal(where:String = null):IResultFuture{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = _conn;
			var sql:String = "SELECT count(*) FROM " + this.tableName;
			if(where != null){
				sql = sql + " WHERE " + where;
			}
			stmt.text = sql;
			var future:ResultFuture = new ResultFuture(stmt);
			return future;
		}
		
		public function createSimpleStatement(sql:String):SQLStatement{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = _conn;
			stmt.text = sql;
			return stmt;
		}
		
		public function createQueryStatement(stringOrQueryParameter:Object,clz:Class = null):SQLStatement{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = _conn;
			var ret:Boolean = false;
			var field:String = "*";
			
			
			var sql:String = "";
			if(stringOrQueryParameter != null){	
				if(stringOrQueryParameter is String){
					sql = "SELECT * FROM " + this.tableName + " WHERE " + stringOrQueryParameter;
				}
				else{
					var params:QueryParameter = stringOrQueryParameter as QueryParameter;
					if(params){
						if(params.where != null){
							sql = sql + "WHERE " + params.where;
						}
						if(params.args != null ){
							if(params.args is Array){
								if($__debug__) _log.debug("args is Array ");
								var arr:Array = params.args as Array;
								for(var i:int=0; i<arr.length; i++){
									stmt.parameters[i] = params.args[i];
								}
							}
							else if(params.args is String){
								stmt.parameters[0] = params.args;
							}
							else if(params.args is Number){
								stmt.parameters[0] = params.args;
							}
							else if(params.args is Object){
								if($__debug__) _log.debug("args is Object");
								for(var key:String in params.args){
									stmt.parameters[":" + key] = params.args[key];
								}
							}
							else{
								stmt.parameters[0] = params.args;
							}
						}
						
						
						if(params.limit > -1 ){
							sql = sql + " LIMIT " + params.limit;
						}
						if(params.offset > -1){
							sql = sql + " OFFSET " + params.offset;
						}
						
						sql = "SELECT " + params.fields + " FROM " + this.tableName + " " + sql;
					}
				}
			}
			if(sql == null || sql.length < 1){
				sql = "SELECT * FROM " + this.tableName;
			}
			
			if(clz != null){
				stmt.itemClass = clz;
			}
			stmt.text = sql;
			if(debug)_log.debug("[SQL] " + sql);
			return stmt;
		}
		
		/**
		 * すべての結果を取得する
		 */
		public function getAll(itemClass:Class = null,func:Function = null):SQLStatement{
			var stmt:SQLStatement = createQueryStatement(null,itemClass);
			var allFunc:Function = function():void{
				var result:SQLResult = stmt.getResult();
				if(func != null){
					func(result);
				}
				stmt.removeEventListener(SQLEvent.RESULT,allFunc);
			};
			stmt.addEventListener(SQLEvent.RESULT,allFunc);
			stmt.execute();
			return stmt;
		}
		
		public function getList(opts:Object,itemClass:Class = null,func:Function = null):void{
			var stmt:SQLStatement = this.createQueryStatement(opts,itemClass);
			
			var selectFunc:Function = function():void{
				var result:SQLResult = stmt.getResult();
				stmt.removeEventListener(SQLEvent.RESULT,selectFunc);
				func(result);
			};
			stmt.addEventListener(SQLEvent.RESULT,selectFunc);
			stmt.execute();	
		}
		
		
		
		public function handleGetMap(event:SQLEvent,key:String):Object{
			var stmt:SQLStatement = event.target as SQLStatement;
			var result:SQLResult = stmt.getResult();
			if( result != null && result.data != null ){
				var retObj:Object = new Object();
				_log.debug("getMap : found (" + result.data.length + ")");
				var size:int = result.data.length;
				for(var i:int =0 ; i < size; i++){
					var dat:Object = result.data[i];
					if(dat[key] != null){
						var kStr:String = dat[key];
						retObj[kStr] = dat;
					}
				}
				return retObj;
			}
			return null;
		}
		
		/**
		*  登録に成功した場合に、最後に登録されたIDを取得する
		*
		*/
		public function handleLastInsertId(event:SQLEvent):Number{
			var stmt:SQLStatement = event.target as SQLStatement;
			var result:SQLResult = stmt.getResult();
			if(result == null){
				return -1;	
			}
			return result.lastInsertRowID;
		}
		
		/**
		 * シーケンス番号を取得する
		 * 
		 */
		public function nextval(seqName:String):Number{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = this._conn;
			stmt.text = "INSERT INTO seq_" + this.tableName + "_" + seqName + " VALUES(NULL)";
			try{
				stmt.execute();
				return stmt.getResult().lastInsertRowID;
			}
			catch(e:SQLError){
				
			}
			return -1;
		}
		
		
		private function getFieldType(type:String):int{
			type = type.toUpperCase();
			switch(type){
				case "INTEGER":
				case "INT":
				case "BOOLEAN":
				case "BOOL":
					return 	FIELD_INTEGER;
				case "TEXT":
				case "CHAR":
				case "VARCHAR":
					return FIELD_TEXT;
				case "TIMESTAMP":
				case "DATE":
					return FIELD_DATE;
			}
			return -1;
		}
		
		public function debugTrace():void{
			_log.debug("*****  DEBUG TRACE ******");
			_log.debug(" table name : " + this.tableName );
			
		}
	}
}