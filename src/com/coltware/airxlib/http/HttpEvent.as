package com.coltware.airxlib.http
{
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	public class HttpEvent extends Event
	{
		private static var log:ILogger = Log.getLogger("com.coltware.airxlib.http.HttpEvent");
		public static var HTTP_REQUEST:String = "httpRequest";
		
		private var _httpRequest:HttpRequest;
		private var _clientSocket:Socket;
		
		public function HttpEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		public function setRequest(request:HttpRequest):void{
			this._httpRequest = request;
		}
		
		public function setClientSocket(socket:Socket):void{
			this._clientSocket = socket;
		}
		
		public function get request():IHttpRequest{
			return this._httpRequest;
		}
		
		public function get socket():Socket{
			return this._clientSocket;
		}
		
		public function service(response:HttpResponse,close:Boolean = true):void{
			var socket:Socket = this._clientSocket;
			
			response.parseForResponse(socket);
		}
		
		public function write(object:Object):void{
			if(object is HttpResponse){
				
			}
			else if(object is File){
				var file:File = object as File;
				
				log.debug("load file:" + file.nativePath); 
				
				var reader:FileStream = new FileStream();
				reader.open(file,FileMode.READ);
				var pos:int = 0;
				while(reader.bytesAvailable){
					var bytes:ByteArray = new ByteArray();
					var size:int = Math.min(1024,reader.bytesAvailable);
					reader.readBytes(bytes,pos,size);
					pos += bytes.length;
					bytes.position = 0;
					socket.writeBytes(bytes,0,bytes.length);
					socket.flush();
				}
				reader.close();
			}
		}
	}
}