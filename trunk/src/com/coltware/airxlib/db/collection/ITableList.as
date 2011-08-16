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
	
	import mx.collections.IList;
	import mx.collections.ISort;
	import mx.collections.Sort;

	public interface ITableList extends IList
	{
		/**
		 *  SQLのコネクションを設定する
		 */
		function set sqlConnection(conn:SQLConnection):void;
		
		/**
		 * テーブル名を設定する
		 */
		function set tableName(name:String):void;
		
		/**
		 * アイテムのクラスを設定する
		 */
		function set itemClass(v:Class):void;
		
		/**
		 *  条件を設定する
		 */
		function set queryParameter(v:QueryParameter):void;
		
		/**
		 *  ソートを設定する
		 */
		function set sort(sort:ISort):void;		
	}
}