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
	import mx.collections.ListCollectionView;
	import mx.collections.Sort;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.FlexEvent;
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	public class TableCollectionView extends ListCollectionView
	{
		private static const log:ILogger = Log.getLogger("com.coltware.airxlib.db.collection.TableCollectionView");
		
		private var _tableList:TableList;
		
		public function TableCollectionView(tableNameOrTable:Object)
		{
			super(null);
			this.sort = new Sort();
			this.sort.fields = [];
			
			this._tableList = new TableList();
			this._tableList.sort = this.sort;
			
			this._tableList.addEventListener(FlexEvent.INIT_COMPLETE,_handle_list_complete);
			
			if(tableNameOrTable is Table){
				var t:Table = tableNameOrTable as Table;
				this._tableList.tableName = t.getTableName();
				this._tableList.sqlConnection = t.sqlConnection;
				this._tableList.itemClass = t.itemClass;
				log.debug("table object add trigger..." + t);
				t.addEventListener(TableEvent.TABLE_CHANGE, hook_table_chage_total);
			}
			else{
				this._tableList.tableName = tableNameOrTable as String;
			}
		}
		
		private function _handle_list_complete(event:FlexEvent):void{
			this.list = this._tableList;
			this.dispatchEvent(event);
		}
		
		public function start():void{
			if(!this._tableList.isInitilizing()){
				this._tableList.start();
			}
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
			return ret;
		}
		
		override public function refresh():Boolean{
			
			this._tableList.refresh();
			
			return true;
		}
		
		private function hook_table_chage_total(evt:TableEvent):void{
			log.debug("table chang total ...");
			this.refresh();
		}
	}
}