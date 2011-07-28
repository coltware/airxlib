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
	import flash.data.SQLResult;
	import flash.events.Event;

	public class TableEvent extends Event
	{
		/**
		 *  新規にオブジェクトが作成されたときのイベント名
		 */ 
		public static const NEW_OBJECT:String = "newObject";
		
		public static const INSERT:String = "tableInsert";
		public static const UPDATE:String = "tableUpdate";
		public static const DELETE:String = "tableDelete";
		public static const TABLE_CHANGE:String = "tableChange";
		
		//  データのサイズが変わったとき
		public static const CHANGE_TOTAL:String = "changeTotal";
		
		public var tableObject:Table;
		public var result:SQLResult;
		public var item:Object;
		
		private var _rowSize:Number;
		
			
		public function TableEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
			
	}
}