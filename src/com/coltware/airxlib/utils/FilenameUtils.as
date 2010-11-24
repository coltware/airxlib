/**
 *  Copyright (c)  2009 coltware@gmail.com
 *  http://www.coltware.com 
 *  
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 * 
 */
package com.coltware.airxlib.utils
{
	import flash.filesystem.File;

	public class FilenameUtils
	{

		public static function getExtension(name:String):String{
			var pos:int = name.lastIndexOf(".");
			if(pos > -1){
				return name.substring(pos+1);
			}
			else{
				return "";
			}
		}
		
		public static function isExtension(ext:String,list:Array):Boolean{
			if(ext.length == 0){
				return false;
			}
			for each(var target:String in list){
				if(ext == target){
					return true;
				}
			}
			return false;
		}
	}
}