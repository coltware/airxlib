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
	import com.coltware.airxlib.db.Table;
	import com.coltware.airxlib.db.TableEvent;
	
	import flash.data.SQLConnection;
	import flash.utils.getQualifiedClassName;
	
	import mx.collections.IList;
	import mx.collections.ISort;
	import mx.collections.ListCollectionView;
	import mx.collections.Sort;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.FlexEvent;
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	[Event(name="initComplete", type="mx.events.FlexEvent")]
	
	public class TableCollectionView extends ListCollectionView
	{
		private static const log:ILogger = Log.getLogger("com.coltware.airxlib.db.collection.TableCollectionView");
		
		public static const MODE_FETCH:String = "FETCH";
		public static const MODE_ALL:String = "ALL";
		
		private var _tableList:TableList;
		
		private var _table:Table;
		
		
		public function TableCollectionView(tableNameOrTable:Object , mode:String = "FETCH")
		{
			super(null);
			this.sort = new Sort();
			this.sort.fields = [];
			
			this._tableList = new TableList(mode);
			
			this._tableList.sort = this.sort as Sort;
			
			this._tableList.addEventListener(FlexEvent.INIT_COMPLETE,_handle_list_complete);
			this._tableList.addEventListener(CollectionEvent.COLLECTION_CHANGE,_handle_list_collection_change);
			
			if(tableNameOrTable is Table){
				_table = tableNameOrTable as Table;
				this._tableList.tableName = _table.getTableName();
				this._tableList.sqlConnection = _table.sqlConnection;
				this._tableList.itemClass = _table.itemClass;
				log.debug("table object add trigger..." + _table);
				_table.addEventListener(TableEvent.TABLE_CHANGE, hook_table_chage_total);
			}
			else{
				this._tableList.tableName = tableNameOrTable as String;
			}
		}
		
		
		private function _handle_list_complete(event:FlexEvent):void{
			this.list = this._tableList;
			this.dispatchEvent(event);
		}
		
		private function _handle_list_collection_change(event:CollectionEvent):void{
			this.dispatchEvent(event);
		}
		
		public function start(func:Function = null):void{
			if(!this._tableList.isInitilizing()){
				this._tableList.start(func);
			}
		}
		
		public function get tableList():TableList{
			return this._tableList;
		}
		
		/**
		 *  Itemクラスを設定する
		 */
		public function set itemClass(v:Class):void{
			_tableList.itemClass = v;
		}
		
		public function set sqlConnection(conn:SQLConnection):void{
			_tableList.sqlConnection = conn;
		}
		
		public function set tableName(name:String):void{
			_tableList.tableName = name;
		}
		
		public function set queryParameter(v:QueryParameter):void{
			_tableList.queryParameter = v;
		}
		
		public function get queryParameter():QueryParameter{
			return _tableList.queryParameter;
		}
		
		override public function getItemIndex(item:Object):int{
			
			var ret:int =  list.getItemIndex(item);
			
			log.debug("getItemIndex() => " + ret);
			return ret;
		}
		
		override public function getItemAt(index:int, prefetch:int=0):Object{
			
			var ret:Object =  list.getItemAt(index,prefetch);
			
			if(index != 0 && index == _tableList.length - 1){
				var evt:TableCollectionEvent = new TableCollectionEvent(TableCollectionEvent.TABLE_COLLECTION_FETCH_END);
				evt.setIndex(index);
				this.dispatchEvent(evt);
			}
			
			
			return ret;
		}
		
		public override function set sort(s:ISort):void{
			super.sort = s;
			if(_tableList){
				_tableList.sort = s;
			}
		}
		
		override public function refresh():Boolean{
			
			this._tableList.refresh();
			
			return true;
		}
		
		private function hook_table_chage_total(evt:TableEvent):void{
			log.debug("table change total ...");
			this.refresh();
		}
		
		public function dispose():void{
			log.debug("dispose...");
			if(this._table){
				_table.removeEventListener(TableEvent.TABLE_CHANGE, hook_table_chage_total);
			}
			
			if(this._tableList){
				this._tableList.dispose();
			}
			
			this._tableList = null;
		}
	}
}