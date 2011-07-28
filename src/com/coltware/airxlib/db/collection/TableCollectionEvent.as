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
	import flash.events.Event;
	
	public class TableCollectionEvent extends Event
	{
		public static const TABLE_COLLECTION_FETCH_END:String = "tableCollectionFetchEnd";
		
		private var _index:Number;
		
		public function TableCollectionEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		public function setIndex(num:Number):void{
			this._index = num;
		}
		
		public function get index():Number{
			return _index;
		}
	}
}