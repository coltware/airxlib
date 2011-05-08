/**
 *  Copyright (c)  2009 coltware@gmail.com
 *  http://www.coltware.com 
 *
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 */
package com.coltware.airxlib.job
{
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.Socket;
	import flash.utils.setTimeout;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	/**
	 *  Socketに特化した非同期処理をFIFOで実施するためのクラス
	 * 
	 */
	public class SocketJobSync extends JobSync
	{
		private static var log:ILogger = Log.getLogger("com.coltware.airxlib.job.SocketJobSync");
		
		protected var _isConnected:Boolean = false;
		
		protected var _sock:Object;
		private var _host:String;
		private var _port:int;
		
		protected var _idleTimeout:int = 5000;
		
		[Event(name="ioError",type="flash.events.IOErrorEvent")]
		[Event (name="securityError",type="flash.events.SecurityErrorEvent")]
		
		[Event(name="jobStackEmpty",type="com.coltware.airxlib.job.JobEvent")]
		[Event(name="jobIdleTimeout",type="com.coltware.airxlib.job.JobEvent")]
		[Event(name="jobInitFailure",type="com.coltware.airxlib.job.JobEvent")]
		
		
		public function SocketJobSync(target:IEventDispatcher=null)
		{
			super(target);
			this.addEventListener(JobEvent.JOB_STACK_EMPTY,handleJobEmpty);
		}
		
		/**
		 *  接続するホストの名称もしくはIPを設定します
		 */
		public function set host(h:String):void{
			this._host = h;
		}
		/**
		 *  接続するポート番号を指定します。
		 */
		public function set port(p:int):void{
			this._port = p;
		}
		
		/**
		 *  Socketオブジェクトを使用しない場合に設定します。
		 *  SSLなどで接続する場合に、拡張されてSocket等を設定してください。
		 *  Objectとなっていますが、Socketクラスと同じpublicメソッド等をサポートしている必要があります
		 */
		public function set socketObject(socket:Object):void{
			var add:Boolean = false;
			if(this._sock){
				//  現在、すでに別のSocketがある場合
				_sock.removeEventListener(ProgressEvent.SOCKET_DATA,handleData);
				_sock.removeEventListener(Event.CONNECT,connectHandler);
				_sock.removeEventListener(IOErrorEvent.IO_ERROR,ioerrorHandler);
				_sock.removeEventListener(SecurityErrorEvent.SECURITY_ERROR,securityHandler);
				_sock.removeEventListener(Event.CLOSE,socketClosing);
				add = true;
			}
			this._sock = socket;
			
			if(add){
				_sock.addEventListener(ProgressEvent.SOCKET_DATA,handleData);
				_sock.addEventListener(IOErrorEvent.IO_ERROR,ioerrorHandler);
				_sock.addEventListener(SecurityErrorEvent.SECURITY_ERROR,securityHandler);
				_sock.addEventListener(Event.CLOSE,socketClosing);
			}
			
		}
		
		public function setIdleTimeout(msec:int):void{
			this._idleTimeout = msec;
		}
		
		public function connect():void{
			if(_sock == null){
				_sock = new Socket();
				if(_sock.hasOwnProperty("timeout")){
					_sock.timeout = 5000;
				}
			}
			
			if(this._isConnected){
				log.debug("socket already opened");
			}
			else{
				_sock.addEventListener(ProgressEvent.SOCKET_DATA,handleData);
				_sock.addEventListener(Event.CONNECT,connectHandler);
				_sock.addEventListener(IOErrorEvent.IO_ERROR,ioerrorHandler);
				_sock.addEventListener(SecurityErrorEvent.SECURITY_ERROR,securityHandler);
				_sock.addEventListener(Event.CLOSE,socketClosing);
				try{
					_sock.connect(this._host,this._port);
				}
				catch(e:IOError){
					log.warn("catch ioerror: " + e);
					var ioErrEvent:IOErrorEvent = new IOErrorEvent(IOErrorEvent.IO_ERROR,true,false,e.message);
					this.dispatchEvent(ioErrEvent);
				}
				log.debug("connect invoked " + this._host + "(" + this._port + ")");
			}
		}
		
		public function disconnect():void{
			if(_isConnected){
				log.info("disconnect(): disconnecting socket ..." + _jobStack.length);
				_sock.removeEventListener(ProgressEvent.SOCKET_DATA,handleData);
				_sock.removeEventListener(IOErrorEvent.IO_ERROR,ioerrorHandler);
				_sock.removeEventListener(Event.CLOSE,socketClosing);
				if(_sock.connected){
					log.info("disconnecting socket ...DONE");
					_isConnected = false;
					_serviceReady = false;
					this.dispatchEvent(new Event(Event.CLOSE));
					try{
						if(_sock.connected)
							_sock.close();
					}
					catch(e:Error){
						log.warn("socket close failed : " + e.message);
					}
				}
			}
		}
		
		/**
		 * サーバから切断された時の処理
		 */
		protected function socketClosing(e:Event):void{
			_isConnected = false;
			log.debug("socket closed from server " + this.isServiceReady);
			_sock.removeEventListener(Event.CLOSE,socketClosing);
			_sock.removeEventListener(ProgressEvent.SOCKET_DATA,handleData);
			_sock.removeEventListener(IOErrorEvent.IO_ERROR,ioerrorHandler);
			//  サーバから接続を閉じられたときには、何も処理をしない
			_sock.addEventListener(SecurityErrorEvent.SECURITY_ERROR,nullHandler);
			_sock.addEventListener(IOErrorEvent.IO_ERROR,nullHandler);
			this._serviceReady = false;
			this.internalSocketClosing();
			
			this.dispatchEvent(new Event(Event.CLOSE));
		}
		
		/**
		 * 内部的にソケットがクローズされたときの処理
		 */
		protected function internalSocketClosing():void{
			
		}
		
		protected function nullHandler(e:SecurityErrorEvent):void{
			log.debug("nullHandler : " + e);
			_sock.removeEventListener(SecurityErrorEvent.SECURITY_ERROR,nullHandler);
		}
		
		protected function connectHandler(ce:Event):void{
			log.debug(this._host + " connected");
			this._isConnected = true;
			_sock.removeEventListener(Event.CONNECT,connectHandler);
			_sock.removeEventListener(SecurityErrorEvent.SECURITY_ERROR,securityHandler);
			
			//  接続イベントを通知する
			this.dispatchEvent(ce);
		}
		
		/**
		 *  ioErrorが発生したときに呼ばれるメソッドです
		 */
		protected function ioerrorHandler(io:IOErrorEvent):void{
			log.warn("io error: " + io);
			this.dispatchEvent(io);
		}
		
		protected function securityHandler(e:SecurityErrorEvent):void{
			
			if(_isConnected){
				log.warn("security error[connected] " + e);
				this.dispatchEvent(e);
			}
			else{
				log.warn("security error[init_failure] " + e);
				var ee:JobEvent = new JobEvent(JobEvent.JOB_INIT_FAILURE);
				this.dispatchEvent(ee);
			}
		}
		/**
		 * この処理をOverrideする
		 * 
		 */
		protected function handleData(pe:ProgressEvent):void{
			log.fatal("you should override this method [handleData]");
		}
		
		protected function handleJobEmpty(e:JobEvent):void{
			//log.debug("job is empty");
			if(_idleTimeout > 0 ){
				setTimeout(fireIdleTimeout,_idleTimeout,this._jobCnt);
			}
		}
		
		protected function fireIdleTimeout(cnt:int):void{
			if(_isConnected && this._jobCnt == cnt && _jobStack.length == 0){
				//  アイドルだったという事で・・・
				log.debug("idle timeout [" + cnt + "] ");
				var evt:JobEvent = new JobEvent(JobEvent.JOB_IDLE_TIMEOUT);
				this.dispatchEvent(evt);
			}
		}
	}
}