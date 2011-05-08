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
	
	import flash.events.*;
	import flash.net.*;
	import flash.utils.*;
	
	import mx.core.mx_internal;
	import mx.logging.*;
	import mx.logging.targets.LineFormattedTarget;
	import mx.utils.StringUtil;
	
	use namespace mx_internal;
	
	/**
	*  ログをSyslogへ飛ばすためのクラス.
	*
	*  メモ：TCP/IPでログを受けられるsyslogサーバに限られます。
	*  また、なぜかたまにAIRが落ちます。（開発時のみご利用ください。）
	* 
	* MEMO: Only TCP/IP Syslog ( UDP : Not support )
	*              Do not use this class for production mode.  
	*
	*  includeDateや、includeTimeの設定は無効になり、必ず日付情報は付加されます。
	*  includeLebelの設定も無効です。以下のpriorityと対応します。
	*  <ul>
	*     <li>LogEventLevel.FATAL は LOG_CRIT(2) </li>
	*     <li>LogEventLevel.ERROR は LOG_ERR(3) </li>
	*     <li>LogEventLevel.WARN  は LOG_WARNING(4)</li>
	*     <li>LogEventLevel.INFO  は LOG_INFO(6)</li>
	*     <li>LogEventLevel.DEBUG は LOG_DEBUG(7)</li>
	*  </ul>
	*  syslogでプログラム名を指定しない場合にはプログラム名にcategoryが使用されます。
	*
	*/
	public class TCPSyslogTarget extends LineFormattedTarget{
		
		
		public static var LOG_LOCAL0:int = 16<<3;
		public static var LOG_LOCAL1:int = 17<<3;
		public static var LOG_LOCAL2:int = 18<<3;
		public static var LOG_LOCAL3:int = 19<<3;
		public static var LOG_LOCAL4:int = 20<<3;
		public static var LOG_LOCAL5:int = 21<<3;
		public static var LOG_LOCAL6:int = 22<<3;
		public static var LOG_LOCAL7:int = 23<<3;

		public static var LOG_EMERG:int = 0;
		public static var LOG_ALERT:int = 1;
		public static var LOG_CRIT:int  = 2;
		public static var LOG_ERR:int   = 3;
		public static var LOG_WARNING:int = 4;
		public static var LOG_NOTICE:int = 5;
		public static var LOG_INFO:int = 6;
		public static var LOG_DEBUG:int = 7;
		
		private static var MONTH:Array = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
		
		private var _host:String;
		private var _port:int = 514;
		private var _facility:int = LOG_LOCAL1;
		private var _socket:Socket;
		
		private var _program:String = null;
		
		
		private var _tag:String = null;
		private var _messages:Array;
		
		private var _timer:Timer;
		
		public function TCPSyslogTarget(host:String,port:int = 514) {
			super();
			this._host = host;
			this._port = port;
			_socket = new Socket();
			_socket.addEventListener(Event.CONNECT,connectHandler);
			_socket.addEventListener(Event.CLOSE,closeByServer);
			_messages = new Array();
			_timer = new Timer(1000,0);
			_timer.addEventListener(TimerEvent.TIMER,_writelog);
		}
		/**
		*  Set syslog program name
		 * 
		*  設定しない場合には自動的にLoggerのcateogryが利用されます。
		*  
		*/
		public function set program(pg:String):void{
			_program = pg;
		}
		
		public function set facility(i:int):void{
			this._facility = i;
		}
		
		/*
		*
		* @private
		*
		*/
		override public function logEvent(event:LogEvent):void
    	{
        	var pri:int;
        	switch(event.level){
        		case LogEventLevel.FATAL:
        			pri =  _facility + LOG_CRIT;
        			break;
        		case LogEventLevel.ERROR:
        			pri = _facility + LOG_ERR;
        			break;
        		case LogEventLevel.WARN:
        			pri = _facility + LOG_WARNING;
        			break;
        		case LogEventLevel.INFO:
        			pri = _facility + LOG_INFO;
        			break;
        		case LogEventLevel.DEBUG:
        			pri = _facility + LOG_DEBUG;
        			break;
        	}
        	var d:Date = new Date();
        	var ds:String = MONTH[d.getMonth()] + " " + doubleDigit(d.getDate()," ") + " " +
        		doubleDigit(d.getHours()) + ":" + 
        		doubleDigit(d.getMinutes()) + ":" +
        		doubleDigit(d.getSeconds());
        	
        	var cat:String = _program;
        	if(cat == null){
        		cat = ILogger(event.target).category;        	
        	}
        	var cat2:String = "";
        	if(includeCategory){
        		cat2 = ILogger(event.target).category + fieldSeparator;
        	}
			var lines:Array = event.message.split("\n");
			if(lines.length == 1){
        		internalLog("<" + pri + ">" + ds + " " + cat + ":" + cat2 + event.message);
			}
			else{
				for(var i:int = 0; i<lines.length; i++){
					var num:String = "[" + (i+1) + "/" + lines.length + "] ";
					internalLog("<" + pri + ">" + ds + " " + cat + ":" + cat2 + num + lines[i]);
				}
			}
    	}
    	
    	/*
    	*
    	* @private
    	*
    	*/
    	private function doubleDigit(num:int,pad:String = "0"):String{
    		if(num < 10){
    			return pad + num.toString();
    		}
    		else{
    			return num.toString();
    		}
    	}
		
		override mx_internal function internalLog(message:String):void
		{
			if(!_socket.connected){
				_socket.connect(_host,_port);
			}
			_messages.push(message);
			
		}
		
		private function connectHandler(e:Event):void{
			_timer.start();
		}
		private function closeByServer(e:Event):void{
			_timer.stop();
		}
		
		private function disconnectAuto():void{
			var len:int = _messages.length;
			if(len == 0 ){
				_timer.stop();
				_socket.close();
			}
		}
		
		private function _writelog(e:TimerEvent):void{
			var len:int = _messages.length;
			for(var i:int=0; i<len; i++){
				var msg:String = _messages.shift();
				msg = StringUtil.trim(msg);
				_socket.writeUTFBytes(msg + "\n");
				_socket.flush();
			}
			disconnectAuto();
		}
	}
}