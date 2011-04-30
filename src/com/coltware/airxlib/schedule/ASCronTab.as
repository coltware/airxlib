/**
 *  Copyright (c)  2009 coltware@gmail.com
 *  http://www.coltware.com 
 *
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 */
package com.coltware.airxlib.schedule {
	
	import flash.utils.*;
	import mx.collections.*;
	import mx.utils.*;
	import flash.events.*
	
	/**
	 *  作りかけ・・・・・
	 * 
	 *  @private
	 */	
	public class ASCronTab extends EventDispatcher{
		
		private var _tasks:ArrayCollection;
		private var _timer:Timer;
		
		/**  
		*  30秒間隔
		*/
		private static var _delay:Number = 1000*30;
	
		private static var _instance:ASCronTab = new ASCronTab();
		
		public function ASCronTab() {
			_tasks = new ArrayCollection();
			_timer = new Timer(_delay,0);
			_timer.addEventListener(TimerEvent.TIMER ,_timerHandler);
		}
		
		public function start():void{
			_timer.start();
		}
		public function stop():void{
			_timer.stop();
		}
		
		public static function getInstance():ASCronTab{
			return _instance;
		}
		
		/**
		*  時間が来ると、指定したtargetのオブジェクトに TimerEvent.TIMER イベントが発行されます
		*/
		public function addASCronJob(job:ASCronJob):String{
			var jobId:String = UIDUtil.getUID(job);
			_tasks.addItem(job);
			return jobId;
		}
		
		public function addHandler(handler:Function,min:String = "*",hour:String = "*", day:String = "*", month:String = "*", week:String = "*"):String{
			var job:ASCronJob = new ASCronJob();
			job.setHandler(handler);
			job.setSchedule(min,hour,day,month,week);
			_tasks.addItem(job);
			var jobId:String = UIDUtil.getUID(job);
			return jobId;
		}
		
		private function _timerHandler(e:TimerEvent):void{
			var now:Date = new Date();
			var len:int = _tasks.length;
			var event:TimerEvent = new TimerEvent(TimerEvent.TIMER);
			for(var i:int =0; i<len; i++){
				var job:ASCronJob = _tasks.getItemAt(i) as ASCronJob;
				if(job){
					job.dispatchEvent(event);
				}
			}
		}
	}

}