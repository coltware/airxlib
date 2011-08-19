package com.coltware.airxlib.utils
{
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	
	import mx.logging.ILogger;
	import mx.logging.Log;

	public class ISO2022JPCode
	{
		private static const log:ILogger = Log.getLogger("com.coltware.airxlib.utils.ISO2022JPtoSJIS");
		
		private static const CHARSET_ASCII:int = 1;
		private static const CHARSET_JISX0201:int = 2;
		private static const CHARSET_JISX0208:int = 3;
		
		private var _charset:int = CHARSET_ASCII;
		private var _hasOut:Boolean = false;
		private var _out:int;
		private var _input:IDataInput;
		
		private var _buffer:ByteArray;
		
		public function ISO2022JPCode()
		{
			_buffer = new ByteArray();
		}
		
		public function set dataInput(val:IDataInput):void{
			this._input = val;
		}
		
		public function toSJIByteArray():ByteArray{
			var bytes:ByteArray = new ByteArray();
			var b:int = 0;
			while(_input.bytesAvailable){
				b = this.readByte();
				if(b > 0 ){
					bytes.writeByte(b);
				}
			}
			bytes.position = 0;
			return bytes;
		}
		
		public function toUTF8String():String{
			if(_buffer){
				log.debug("buffer size[" + _buffer.length + "]");
				_buffer.position = 0;
				return _buffer.readMultiByte(_buffer.length,"Shift_JIS");
			}
			return "";
		}
		
		public function clear():void{
			if(_buffer){
				_buffer.clear();
			}
		}
		
		public function read():Boolean{
			
			while(_input.bytesAvailable){
				var b:int = this.readByte();
				if(b > 0){
					_buffer.writeByte(b);
				}
				else{
					return false;
				}
			}
			return true;
		}
		
		protected function readByte():int{
			if(_hasOut){
				_hasOut = false;
				return _out;
			}
			
			var in1:int = _input.readByte();
			
			while(in1 == 0x1b){
				in1 = _input.readByte();
				
				if(in1 == 0x28 ){			// '('
					in1 = _input.readByte();
					
					if(in1 == 0x42 || in1 == 0x4a){	// 'B' or 'J'
						_charset = CHARSET_ASCII;
					}
					else if(in1 == 0x49){	// 'I'
						_charset = CHARSET_JISX0201;
					}
					else{
						throw new Error('Unknown code [' + in1 + "]");
					}
				}
				else if(in1 == 0x24){	// '$'
					in1 = _input.readByte();
					if(in1 == 0x40 || in1 == 0x42){	//	'@'  or 'B'
						_charset = CHARSET_JISX0208;
					}
					else{
						throw new Error('Unknown code [' + in1 + "]");
					}
				}
				else{
					throw new Error('Unknown code [' + in1 + "]");
				}
				if(_input.bytesAvailable){
					in1 = _input.readByte();
				}
				else{
					return -1;
				}
			}
			
			if(in1 == 0x0c || in1 == 0x0d){
				_charset = CHARSET_ASCII;
			}
			
			if(in1 < 0x21 || in1 >= 0x7f){
				return in1;
			}
			
			switch(_charset){
				case CHARSET_ASCII:
					return in1;
				case CHARSET_JISX0201:
					return in1 + 0x80;
				case CHARSET_JISX0208:
					var in2:int = _input.readByte();
					if(in2 < 0x21 || in2 >= 0x7f){
						throw new Error('Unknown code [' + in2 + "]");
					}
					
					var out1:int = (in1 + 1)/2 + (	(in1 < 0x5f)?	0x70: 0xb0	);
					var out2:int = in2 + (in1 % 2 == 0 ? 0x7e : in2 < 0x60 ? 0x1f: 0x20);
					
					_out = out2;
					_hasOut = true;
					
					return out1;
				default:
					throw new Error('Unknown JIS Stream');
			}
			
			throw new Error('Unknown JIS Stream');
			
		}
	}
}