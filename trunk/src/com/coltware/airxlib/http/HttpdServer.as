package com.coltware.airxlib.http
{
	import com.coltware.airxlib.utils.StringLineReader;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.ServerSocketConnectEvent;
	import flash.net.ServerSocket;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.utils.StringUtil;
	
	public class HttpdServer extends EventDispatcher
	{
		private static var log:ILogger = Log.getLogger("com.coltware.airxlib.httpd.HttpdServer");
		private var socket:ServerSocket;
		private var clientSocket:Socket;
		
		private var httpRequest:HttpRequest;
		
		public function HttpdServer(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public function start(port:int = 0):void{
			socket = new ServerSocket();
			
			socket.addEventListener(ServerSocketConnectEvent.CONNECT,_connectHandler);
			socket.bind(port);
			
			log.debug("start httpd : " + socket.localAddress + ":" + socket.localPort );
			socket.listen();
		}
		
		public function stop():void{
			socket.close();
			socket = null;
		}
		
		private function _connectHandler(event:ServerSocketConnectEvent):void{
			clientSocket = event.socket;
			clientSocket.addEventListener(ProgressEvent.SOCKET_DATA,_onClientDataEvent);
			clientSocket.addEventListener(IOErrorEvent.IO_ERROR,_onClientIOError);
			clientSocket.addEventListener(Event.CLOSE,_onClientCloseEvent);
			httpRequest = new HttpRequest(event.socket);
		}
		
		private function _onClientIOError(event:IOErrorEvent):void{
			log.warn("ioerror:[" + event.text + "]");
		}
		
		private function _onClientDataEvent(event:ProgressEvent):void{
			log.debug("data ..." + event.bytesLoaded + "/" + event.bytesTotal );
			
			var socket:Socket = event.target as Socket;
			
			if(socket != null){
				log.debug("reading ...");
				var reader:StringLineReader = new StringLineReader();
				reader.source = socket;
				var line:ByteArray = reader.nextBytes();
				try{
					while(line.length > 0 && socket.bytesAvailable){
						httpRequest.parseRequest(line);
						line = reader.nextBytes();
					}
				
					if(event.bytesTotal == 0 || event.bytesLoaded == event.bytesTotal){
						var evt:HttpEvent = new HttpEvent(HttpEvent.HTTP_REQUEST);
						evt.setRequest(httpRequest);
						evt.setClientSocket(socket);
						this.dispatchEvent(evt);
					}
				}
				catch(err:Error){
					log.warn(err.message);
				}
			}
			
		}
		
		private function _onClientCloseEvent(event:Event):void{
			log.debug("client close..");
		}
	}
}