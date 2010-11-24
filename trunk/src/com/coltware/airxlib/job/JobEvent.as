/**
 *  Copyright (c)  2009 coltware@gmail.com
 *  http://www.coltware.com 
 *  
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 * 
 */
package com.coltware.airxlib.job
{
	import flash.events.Event;

	public class JobEvent extends Event
	{
		public static const JOB_STACK_EMPTY:String = "jobStackEmpty";
		public static const JOB_IDLE_TIMEOUT:String = "jobIdleTimeout";
		
		/**
		 *  初期化に失敗した場合のエラー
		 */
		public static const JOB_INIT_FAILURE:String = "jobInitFailure";
		
		public function JobEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}