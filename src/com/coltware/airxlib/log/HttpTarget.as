/**
 *  Copyright (c)  2009 coltware@gmail.com
 *  http://www.coltware.com 
 *  
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 * 
 */
package com.coltware.airxlib.log
{
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	
	import mx.core.mx_internal;
	import mx.logging.targets.LineFormattedTarget;
	
	use namespace mx_internal;
	
	/**
	 *   Status: Developing 
	 */ 
	public class HttpTarget extends LineFormattedTarget
	{
		
		private var _messages:Array;
		private var _loader:URLLoader;
		/**
		 *  最大何行ためるか？
		 */
		private var _maxLine:int = 100;
		/**
		 *  何秒間遅延させるか？
		 */
		private var _sync:int = 0;
		
		private var _writing:Boolean = false;
		
		private var _url:String = "http://hostname/http/log.php";
		/**
		 *  HTTPのリクエストでログを投げる
		 */
		public function HttpTarget()
		{
			super();
			_messages = new Array();
			_loader = new URLLoader();
		}
		
		public function set url(val:String):void{
			this._url = val;
		}
		
		override mx_internal function internalLog(message:String):void
		{
			_messages.push(message);
			if(_sync > 0 ){
			}
			else{
			}
			
		}
		private function _writelog(e:TimerEvent = null):void{
			_writing = true;
			var req:URLRequest = new URLRequest(_url);
			req.method = URLRequestMethod.POST;
			_loader.load(req);
		}
	}
}