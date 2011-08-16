package com.coltware.airxlib.db.collection
{
	import flash.data.SQLConnection;
	
	import mx.collections.IList;
	import mx.collections.ISort;
	import mx.collections.ListCollectionView;
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	public class QueryCollectionView extends ListCollectionView
	{
		private static const log:ILogger = Log.getLogger("com.coltware.airxlib.db.collection.QueryCollectionView");
		private var _queryList:QueryList;
		
		public function QueryCollectionView()
		{
			super(null);
			
			_queryList = new QueryList();
			this.list = _queryList;
			
		}
		
		public function start(func:Function = null):void{
			this._queryList.start(func);
		}
		
		public function set sqlConnection(conn:SQLConnection):void{
			_queryList.sqlConnection = conn;
		}
		
		public function set itemClass(clz:Class):void{
			_queryList.itemClass = clz;
		}
		
		public function set text(sql:String):void{
			_queryList.text = sql;
		}
		
		public override function set sort(s:ISort):void{
			super.sort = s;
			_queryList.sort = s;
		}
		
		public function get parameters():Object{
			return _queryList.parameters;
		}
		
		override public function getItemAt(index:int, prefetch:int=0):Object{
			log.debug("get item at...");
			return _queryList.getItemAt(index,prefetch);
		}
		
		override public function refresh():Boolean{
			this._queryList.refresh();
			return true;
		}
	}
}