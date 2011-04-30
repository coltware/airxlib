/**
 *  Copyright (c)  2009 coltware@gmail.com
 *  http://www.coltware.com 
 *
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 */
package com.coltware.airxlib.schedule {
	
	import 	flash.utils.*;
	import  mx.collections.*;
	import mx.utils.*;
	import flash.events.*;
	
	/**
	 *  作りかけ・・・・・
	 * 
	 *  @private
	 */
	public class ASCronJob extends EventDispatcher{
		
		/**
		* 前回実行した時刻
		*/
		private var _lastExecAt:Date = null;
				
		private var _min:String  		= "*";
		private var _hour:String 		= "*";
		private var _date:String  		= "*";
		private var _dayOfWeek:String 	= "*";
		private var _month:String 		= "*";
		
		private var _handler:Function = null;
		
		public function ASCronJob(){
			this.addEventListener(TimerEvent.TIMER,_timerHandler);
			_lastExecAt = new Date(0);
			this._handler = execute;
		}
		
		public function setSchedule(min:String = "*",hour:String = "*", day:String = "*", month:String = "*", week:String = "*"):void{
			this._min = _parseValue(min,60);
			this._hour = _parseValue(hour,24);
			this._date = _parseValue(day,31);
			this._dayOfWeek = _parseValue(week,7);
			this._month = _parseValue(month,12);
		}
		
		public function setHandler(handler:Function):void{
			this._handler = handler;
		}
		
		protected function execute():void{
			
		}
		
		private function _timerHandler(e:TimerEvent):void{
			if(_isExec()){
				_lastExecAt = new Date();
				if(this._handler is Function){
					this._handler.call();
				}
			}
		}
		
		/**
		*  次に実行すべき日時を設定する
		*/
		private function _isExec():Boolean{
			var now:Date = new Date();
			
			// 1分以上前の実行から経過していれば・・・
			var last:Number = _lastExecAt.getTime();
			var past:Number  = now.getTime() - last;
			if( past > 60*1000){
				if(!_isExecMin(now)){
					return false;
				}
			}
			else {
				return false;
			}
			
			
			if(!_isExecHour(now)){
				return false;
			}
			
			if(!_isExecDate(now)){
				return false;
			}
			
			if(!_isExecDayOfWeek(now)){
				return false;
			}
			
			if(!_isExecMonth(now)){
				return false;
			}
			
			return true;
		}
		
		public function _parseValue(val:String,base:int):String{
		
			if(val == null || val == "*" || val == ""){
				return "*";
			}
			var _val:Number;
			var i:int =0;
			
			var value:String = val.replace("*","0-" + String(base - 1));
			var ret2:Array = new Array();
			
			//  , で区切る
			var __arr:Array = value.split(",");
			var __str:String;
			var len:int = __arr.length;
			for(var a:int=0; a<len; a++){
				__str = __arr[a];
				_val = Number(__str);
				if(_val){
					ret2.push(_val);
				}
				else{		
					if(__str.indexOf("/") > 0){
							var __base2:Number = Number(__str.substr(__str.indexOf("/") + 1));
							if(__base2){
								var mpos:int = __str.indexOf("-");
								if(mpos > 0){
									var sn:Number = Number(__str.substring(0,mpos));
									var en:Number = Number(__str.substring(mpos+1,__str.indexOf("/")));
									
									if(isNaN(sn) || isNaN(en)){
										throw new Error("format error [not numeric] " + val);
									}
									if(en > base){
										throw new Error("format error [base is too big] " + val);
									}
									for(i=0; i<en-sn; i++){
										if(i%__base2 == 0){
											ret2.push(i+sn);
										}
									}
								}
								else{
									throw new Error("format error [range error]" + val);
								}
							}
							else{
								throw new Error("format error [base is zero or not numeric]" + value);
							}
						}
						else{
							var mpos2:int = __str.indexOf("-");
							if(mpos2 > 0){
								var sn2:Number = Number(__str.substring(0,mpos2));
								var en2:Number = Number(__str.substr(mpos2+1));
								if(sn2 && en2){
									if(en2 > base){
										throw new Error("format error [base is too big]" + value);
									}
									for(i=sn2; i<en2+1; i++){
										ret2.push(i);
									}
								}
								else{
									throw new Error("format error " + value);
								}
							}
							else{
								throw new Error("format error " + value);
							}
						}
					}
				}
				return ret2.join(",");
		}
		
		private function _isExecMin(now:Date):Boolean{
			return _isExecTime(_min,now.getMinutes());
		}
		
		private function _isExecHour(now:Date):Boolean{
			return _isExecTime(_hour,now.getHours());
		}
		
		private function _isExecDate(now:Date):Boolean{
			return _isExecTime(_date,now.getDate());
		}
		
		private function _isExecDayOfWeek(now:Date):Boolean{
			return _isExecTime(_dayOfWeek,now.getDay());
		}
		
		private function _isExecMonth(now:Date):Boolean{
			return _isExecTime(_month,now.getMonth() + 1);
		}
		
		/**
		*  実行すべきか？
		*/
		private function _isExecTime(value:String,curTarget:Number):Boolean{
			var __val:Number = 0;
			if(value == null || value == "*" || value == ""){
				//  毎×見るので
				return true;
			}
			else{
				var arr:Array = value.split(",");
				var len:int = arr.length;
				for(var i:int = 0; i<len; i++){
					var v:Number = Number(arr[i]);
					if(!isNaN(v)){
						if(v == curTarget){
							return true;
						}
					}
					else{
						throw new Error("runtime error [format error] (" + arr[i] + ")" + value);
					}
				}
			}
			return false;
		}
		
	}

}