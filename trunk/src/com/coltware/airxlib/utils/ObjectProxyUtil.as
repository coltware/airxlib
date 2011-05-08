package com.coltware.airxlib.utils
{
	import flash.utils.flash_proxy;
	
	import mx.utils.ObjectProxy;

	use namespace flash_proxy;
	
	public class ObjectProxyUtil
	{
		public static function getObject(obj:Object):Object{
			if(obj is ObjectProxy){
				var tmp:ObjectProxy = obj as ObjectProxy;
				return tmp.object();
			}
			else{
				return obj;
			}
		}
	}
}