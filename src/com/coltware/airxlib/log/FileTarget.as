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
	import mx.core.mx_internal;
	import mx.logging.targets.LineFormattedTarget;
	import mx.logging.LogEvent;
	import mx.logging.LogEventLevel;
	import flash.filesystem.*;
	
	use namespace mx_internal;
	
	/**
	 *   ファイルにログを書き出すためのクラス.
	 * 
	 * 使い方例）
	 * <pre>
	 * var target:FileTarget = new FileTarget();
	 
	 * target.includeCategory = true;
	 * target.includeDate = true;
	 * target.includeLevel = true;
	 * target.includeTime = true;
	 * target.filters = ["com.coltware.*"];
	 * 
	 * // --- 以下はFileTarget用の設定 ----
	 * target.append   = false;
	 * target.levelSet = [LogEventLevel.DEBUG, LogEventLevel.INFO];
	 * target.directory = File.userDirectory;
	 * target.filename = "debug.log";
	 * //------------------------------------
	 * 
	 * Log.addTarget(debugTarget);
	 * </pre>
	 * 
	 */
	public class FileTarget extends LineFormattedTarget{
		
		private var _dir:File;
		private var _name:String;
		private var _open:Boolean = false;
		private var _stream:FileStream;
		
		private var _levelSet:Array = null;
		
		private var _enableDebug:Boolean = false;
		private var _enableInfo:Boolean  = false;
		private var _enableWarn:Boolean  = false;
		private var _enableError:Boolean = false;
		private var _enableFatal:Boolean = false;
		private var _setMode:Boolean = false;
		
		private var _fileMode:String;
		
		public function FileTarget() {
			super();
			_fileMode = FileMode.APPEND;
		}
		[Inspectable(arrayType="int")]
		/**
		 * 表示するログレベルを指定する.
		 * 
		 * @see mx.logging.LogEventLevel
		*/
		public function set levelSet(arr:Array):void{
			_setMode = true;
			for(var i:int = 0; i<arr.length; i++){
				var m:int = arr[i];
				switch(m){
					case LogEventLevel.FATAL:
						_enableFatal = true;
						break;
					case LogEventLevel.ERROR:
						_enableError = true;
						break;
					case LogEventLevel.WARN:
						_enableWarn = true;
						break;
					case LogEventLevel.INFO:
						_enableInfo = true;
						break;
					case LogEventLevel.DEBUG:
						_enableDebug = true;
						break;
				}
			}
		}
		
		public function set directory(f:File):void{
			if(f.isDirectory){
				_dir = f;
			}
		}
		
		public function set filename(n:String):void{
			if(_name != null && _name != n ){
				if(_stream != null){
					try{
						_stream.close();
					}
					catch(err:Error){
					}
				}
				_name = n;
				this.open();
			}
			_name = n;
		}
		
		public function set append(b:Boolean):void{
			if(b){
				_fileMode = FileMode.APPEND;
			}
			else{
				_fileMode = FileMode.WRITE;
			}
		}
		
		public function open():void{
			_stream = new FileStream();
			var logfile:File = new File(_dir.nativePath + File.separator + _name);
			_stream.openAsync(logfile,_fileMode);
			_open = true;
		}
		
		override public function logEvent(event:LogEvent):void {
			if(_setMode){
				switch(event.level){
					case LogEventLevel.FATAL:
						if(_enableFatal) super.logEvent(event);
						break;
					case LogEventLevel.ERROR:
						if(_enableError) super.logEvent(event);
						break;
					case LogEventLevel.INFO:
						if(_enableInfo) super.logEvent(event);
						break;
					case LogEventLevel.WARN:
						if(_enableWarn) super.logEvent(event);
						break;
					case LogEventLevel.DEBUG:
						if(_enableDebug) super.logEvent(event);
						break;
				}
			}
			else{
				super.logEvent(event);
			}
		}
		
		override mx_internal function internalLog(message:String):void
    	{
    		if(!_open){
    			this.open();
    		}
    		_stream.writeMultiByte(message + File.lineEnding,File.systemCharset);
    	}
	}
}
