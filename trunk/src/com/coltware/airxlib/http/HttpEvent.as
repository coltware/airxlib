package com.coltware.airxlib.http
{
	import flash.events.Event;
	import flash.net.Socket;
	
	public class HttpEvent extends Event
	{
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
	}
}