package com.coltware.airxlib.http
{
	import flash.net.Socket;
	
	import mx.logging.ILogger;
	import mx.logging.Log;

	public class HttpResponse implements IHttpResponse
	{
		private static var log:ILogger = Log.getLogger("com.coltware.airxlib.http.HttpResponse");
		private var _code:int = 200;
		private var _statusMessage:String = "OK";
		private var _headers:Object;
		
		
		public function HttpResponse(code:int,msg:String)
		{
			this._code = code;
			this._statusMessage = msg;
			this._headers = new Object();
		}
		
		public function setHeader(key:String,val:String):void{
			this._headers[key] = val;
		}
		
		public function parseForResponse(socket:Socket):void{
			log.debug("parse respose...[" + socket.bytesAvailable + "] data has...");
			if(!socket.connected){
				log.debug("socket is NOT connected..");
				return;
			}
			socket.writeUTFBytes("HTTP/1.1 ");
			socket.writeUTFBytes(String(_code));
			socket.writeUTFBytes(this._statusMessage);
			socket.writeUTFBytes("\r\n");
			
			for(var key:String in this._headers){
				socket.writeUTFBytes(key + ":");
				socket.writeUTFBytes(this._headers[key]);
				socket.writeUTFBytes("\r\n");
			}
			
			socket.writeUTFBytes("\r\n");
			socket.flush();
		}
	}
}