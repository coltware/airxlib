package com.coltware.airxlib.http
{
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.utils.StringUtil;

	public class HttpRequest implements IHttpRequest
	{
		private static const log:ILogger = Log.getLogger("com.coltware.airxlib.http.HttpRequest");
		
		private var _parseFirst:Boolean = false;
		private var _method:String;
		private var _url:String;
		private var _protocol:String;
		
		private var _headers:Object;
		private var _clientSocket:Socket;
		
		public function HttpRequest(socket:Socket)
		{
			this._headers = new Object();
			this._clientSocket = socket;
		}
		
		public function get method():String{
			return this._method;
		}
		
		public function get url():String{
			return this._url;
		}
		
		public function getClientSocket():Socket{
			return this._clientSocket;
		}
		
		public function getHeader(key:String):String{
			var k:String = key.toLowerCase();
			if(this._headers[k]){
				return this._headers[k];
			}
			else{
				return "";
			}
		}
		
		public function parseRequest(bytes:ByteArray):void{
			bytes.position = 0;
			if(_parseFirst == false){
				this.parseFirstLine(bytes);
				this._parseFirst = true;
			}
			else{
				this.parseMimeHeaders(bytes);
			}
		}
		
		private function parseFirstLine(bytes:ByteArray):void{
			var line:String = bytes.readUTFBytes(bytes.length);
			var params:Array = line.split(/\s/,3);
			if(params.length == 3){
				this._method = params[0];
				this._url    = params[1];
				this._parseFirst = params[2];
			}
		}
		
		private function parseMimeHeaders(bytes:ByteArray):void{
			var ch:int = bytes.readByte();
			if(ch > 32 ){
				bytes.position = 0;
				var line:String = bytes.readUTFBytes(bytes.length);
				var pos:int = line.indexOf(":");
				var key:String = line.substr(0,pos).toLowerCase();
				var val:String = line.substring(pos+1);
				this._headers[key] = StringUtil.trim(val);
			}
			else{
				// TODO: 前のヘッダの続き
			}
		}
		
	}
}