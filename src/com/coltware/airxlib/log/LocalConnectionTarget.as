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
	import flash.events.SecurityErrorEvent;
	import flash.events.StatusEvent;
	import flash.net.LocalConnection;
	
	import mx.core.mx_internal;
	import mx.logging.ILogger;
	import mx.logging.LogEvent;
	import mx.logging.targets.LineFormattedTarget;
	
	use namespace mx_internal;
	/**
	 *  Output Log using LocalConnection
	 */
	public class LocalConnectionTarget extends LineFormattedTarget
	{
		private var lc:LocalConnection;
		private var _publisherID:String = "FAE4A34E3B9A50C5A7E6E79F93A68DF6BF48437E.1";
		private var _domain:String 		= "app#FlexLog";
		private var _name:String 		= "coltware.log";
		
		private var _connName:String = "";
		//private var _name:String = "app#Flexlog:coltware.log";
		
		public function LocalConnectionTarget()
		{
			super();
			try{
				lc = new LocalConnection();
				lc.addEventListener(SecurityErrorEvent.SECURITY_ERROR,securityError);
				lc.addEventListener(StatusEvent.STATUS,handleStatus);
			}
			catch(e:Error){
				trace("new .." + e.message);
			}
			this._setConnName();
		}
		
		private function securityError(e:SecurityErrorEvent):void{
			trace("security error");
		}
		
		private function handleStatus(e:StatusEvent):void{
			if(e.level == "status"){
				//trace("send ok");
			}
			else{
				//trace("status error :" + e.level + "/" + lc.domain);
				
			}
		}
		
		public function set serverName(n:String):void{
			_name = n;
			this._setConnName();
		}
		
		public function set publisherId(v:String):void{
			_publisherID = v;
			this._setConnName();
		}
		
		private function _setConnName():void{
			this._connName = this._domain + "." + this._publisherID + ":" + this._name;
		}
		
		
		
		override public function logEvent(event:LogEvent):void
    	{
        	var date:String = ""
        	var d:Date = new Date();
     		var level:int = event.level;
     		var category:String = ILogger(event.target).category;
     		try{
     			if(lc)
        			lc.send(_connName,"write",d,level,category,event.message);
       		}
       		catch(e:Error){
       			trace("logEvent: " + e.message);
       		}   
    	}
	}
}