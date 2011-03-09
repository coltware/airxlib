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
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.errors.SQLError;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	public class TableFactory {
		
		private static const $__debug__:Boolean = false;
		
		private var _conn:SQLConnection;	
		private var _xml:XML;
		
		private static const _log:ILogger = Log.getLogger("com.coltware.airxlib.db.TableFactory");
		
		public var lastSql:String = "";
		
		
		public function TableFactory() {
			
		}
		
		/**
		*
		*/
		public function set connection(conn:SQLConnection):void{
			this._conn = conn;
		}
		/**
		*  定義XMLの設定
		*/
		public function set xml(defxml:XML):void{
			this._xml = defxml;
		}
		
		public function dropIfExist():String{
			var tableName:String = this._xml.@name;
			lastSql = "DROP TABLE IF EXISTS " + tableName;
			if($__debug__) _log.debug("SQL : " + lastSql);
			return lastSql;
		}
		
		public function drop(resultFunc:Function = null,errorFunc:Function = null):SQLStatement{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = this._conn;
			stmt.text = dropIfExist();
			if(resultFunc != null){
				stmt.addEventListener(SQLEvent.RESULT,resultFunc);
			}
			if(errorFunc != null){
				stmt.addEventListener(SQLErrorEvent.ERROR,errorFunc);
			}
			stmt.execute();
			return stmt;
		}
		
		public function handleCreate(e:SQLEvent):void{
			var stmt:SQLStatement = e.target as SQLStatement;
			var result:SQLResult = stmt.getResult();
			_log.debug("handleCreate " + result.lastInsertRowID);
		}
		
		
		
		public function create(resultFunc:Function = null,errorFunc:Function = null,ifNotExists:Boolean = false):SQLStatement{
			
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = this._conn;
			stmt.text = createSQL(ifNotExists);
			//stmt.addEventListener(SQLEvent.RESULT,handleCreate);
			if(resultFunc != null){
				stmt.addEventListener(SQLEvent.RESULT,resultFunc);
			}
			if(errorFunc != null){
				stmt.addEventListener(SQLErrorEvent.ERROR,errorFunc);
			}
			try{
				stmt.execute();
			}
			catch(sqlErr:SQLError){
				_log.error("SQL Error :" + stmt.text );
				return null;
			}
			return stmt;
		}
		
		public function createSQL(ifNot:Boolean = false):String{
			var sql:String;
			
			var tableName:String = this._xml.@name;
			
			
			var ifNotStr:String = "";
			if(ifNot == true){
				ifNotStr = " IF NOT EXISTS ";
			}
			
			sql = "CREATE TABLE " + ifNotStr + tableName + "( \n";
			
			var pkey:Boolean  = false;
			var cnt:int = 0;
			
			var pkeyList:Array = new Array();
			
			for each(var child:XML in this._xml.field){
				var name:String = child.@name;
				var type:String = child.@type;
				type = type.toUpperCase();
				
				if(cnt > 0 ){
					sql = sql + ",\n";
				}
				cnt++;
				
				var primary:String = child.@primary;
				var ai:String = child.@auto_increment;
				
				var primaryKey:String = "";
				if((primary == "true" || primary == "TRUE" )){
					if(ai == "true" || ai == "TRUE"){
						primaryKey = " PRIMARY KEY AUTOINCREMENT ";
						pkey = true;
					}
					else{
						pkeyList.push(name);
					}
				}
				var nn:String = child.@required;
				var notNull:String = "";
				if(nn == "true" || nn == "TRUE"){
					notNull = " NOT NULL ";
				}
				
				switch(type){
					case "INTEGER":
					case "INT":
						sql = sql + name + " INTEGER " +primaryKey + notNull;
						break;
					case "VARCHAR":
					case "CAHR":
						sql = sql + name + " VARCHAR(" + child.@size + ")" + notNull;
						break;
					case "TEXT":
						sql = sql + name + " TEXT " + notNull;
						break;
					case "TIMESTAMP":
					case "DATE":
						sql = sql + name + " DATE " + notNull;
						break;
					case "BOOL":
					case "BOOLEAN":
						sql = sql + name + " BOOLEAN " + notNull;
						break;
				}
				
				var def:String = child.@default;
				if(def != null && def.length > 0 ){
					sql = sql + " DEFALUT '" + def + "'";
				}
					
			}
			
			if(pkey == false && pkeyList.length > 0){
				sql = sql + ",\n PRIMARY KEY (" + pkeyList.join(",") + ")";
			}
			
			sql = sql + ");";
			
			// シーケンスがある場合
			for each(var c:XML in this._xml.sequence){
				// TODO シーケンスの作成で、エラー処理がない
				this.createSeq(tableName,c.@name);
			}
			
			if($__debug__) _log.debug("sql : " + sql);
			lastSql = sql;
			return sql;
		}
		
		private function createSeq(tableName:String,fieldName:String):void{
			var n:String = "seq_" + tableName + "_" + fieldName;
			var sql:String = "CREATE TABLE IF NOT EXISTS " + n + "( seq INTEGER PRIMARY KEY AUTOINCREMENT );";
			var stmt:SQLStatement = new SQLStatement();
			stmt.text = sql;
			stmt.sqlConnection = this._conn;
			stmt.execute();
		}
	}
}