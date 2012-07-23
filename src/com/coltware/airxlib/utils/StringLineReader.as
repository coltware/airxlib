/**
 *  Copyright (c)  2009 coltware@gmail.com
 *  http://www.coltware.com 
 *  
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 * 
 */
package com.coltware.airxlib.utils
{
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	/**
	 *  IDataInputから１行( CR/CR LF )ずつ読むクラス
	 */
	public class StringLineReader
	{
		private static var log:ILogger = Log.getLogger("com.coltware.airxlib.utils.StringLineReader");
		
		private static const CR:int 	= 0x0D;
		private static const LF:int 	= 0x0A;
		
		private var _input:IDataInput = null;
		private var _pos:int = 0;
		
		// 最後の行（デバッグ等で利用）
		private var _lastLine:String = "";
		
		private var _bufBytes:ByteArray;
		
		public function StringLineReader()
		{
		}
		
		/**
		 * 入力ソースを設定する
		 * 
		 */
		public function set source(input:IDataInput):void{
			_input = input;
		}
		
		public function get source():IDataInput{
			return this._input;
		}
		
		/**
		 * 次の行を取得する
		 * ない場合には、nullが帰る
		 */ 
		public function nextBytes():ByteArray{
			if(_input == null){
				return null;
			}
			
			var b:int;
			var str:String;
			var len:int;
			
			_bufBytes = new ByteArray();
			
			while(_input.bytesAvailable ){
				b = _input.readByte();
				_bufBytes.writeByte(b);
				if(b == LF ){
					_bufBytes.position = 0;
					return _bufBytes;
				}
				else if(b == CR){
					//  次のバイトを見て、LFでなければ返す
					if(_input.bytesAvailable){
						b = _input.readByte();
						_bufBytes.writeByte(b);
						if( b == LF){
							_bufBytes.position = 0;
							return _bufBytes;
						}
					}
				}
			}
			_bufBytes.position = 0;
			return _bufBytes;
		}
		
		public function next(charset:String = "utf-8"):String{
			var bytes:ByteArray = nextBytes();
			if(bytes == null){
				return "";
			}
			bytes.position = 0;
			if(charset == 'utf-8'){
				return bytes.readUTFBytes(bytes.bytesAvailable);
			}
			else{
				return bytes.readMultiByte(bytes.bytesAvailable,charset);
			}
		}
		
		public function lastBytearray():ByteArray{
			_bufBytes.position = 0;
			return _bufBytes;
		}
		
		public function create(size:int):StringLineReader{
			var bytes:ByteArray = new ByteArray();
			_input.readBytes(bytes,0,size);
			bytes.position = 0;
			var reader:StringLineReader = new StringLineReader();
			reader.source = bytes;
			return reader;
		}
		
	}
}