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
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	import mx.utils.ObjectProxy;

	public class FutureItem extends ObjectProxy
	{
		private var _get_func:Function;
		private var _item:Object;
		private var _index:int;
		
		public function FutureItem()
		{
		}
	}
}