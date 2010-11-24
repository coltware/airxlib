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
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	/**
	 *  非同期処理のタスクをFIFOで処理するためのクラスです.
	 * 
	 *  <p>たとえば、Socket処理などはデータの書き込みの応答は非同期処理としてデータを受信します。
	 * この時、サーバからの応答コードを見てから次の処理が必要な場合などでも、
	 * このクラスを使うことで、処理を連続して記述することが可能になります。
	 * </p>
	 * 
	 * <p>ただし、このクラスは必ずoverrideされることが前提となっております。
	 * override するメソッドは execメソッドです。
	 * </p>
	 * 
	 * <p>
	 * <pre>
	 * class CustomJobSync extends JobSync{
	 *   
	 *    override  protected function exec(job:Object):void{
	 *       foo.addEventListener(type,asyncFunc);
	 *    }
	 *    private function asyncFunc(e:Event):void{
	 *       //  JOBが完了したなら ( If job finished.... )
	 *       this.commitJob();
	 *    }
	 * 
	 * }
	 * </pre>
	 * 実際の使い方
	 * <pre>
	 * var sync:CustomJobSync = new CustomJobSync();
	 * sync.serviceReady();  //  サービスが開始して大丈夫なことを伝える
	 * 
	 * //  一連の流れの処理を記述する。
	 * //  記述上、イベント処理の結果判断などの処理が記述されないのでどのような処理をしているかがわかりやすくなる。
	 * 
	 * 
	 * sync.addJob(new Object());
	 * sync.addJob(new Object());
	 * </pre>
	 */
	public class JobSync extends EventDispatcher
	{
		private static var log:ILogger = Log.getLogger("com.coltware.airxlib.job.JobSync");
		
		/**
		 * JOBスタックの変化をみているか?
		 */ 
		private var _watching:Boolean = false;
		
		/**
		 * JOBを実行中か
		 */
		private var _executing:Boolean = false;
		protected var _jobStack:ArrayCollection;
		
		/**
		 * サービスが利用できる状態か？
		 */
		private var _serviceReady:Boolean = false;
		
		/**
		 * 現在実施中のジョブ
		 */
		protected var currentJob:Object = null;
		
		/**
		 *  ブロッキングMode
		 */
		protected var blockingMode:Boolean = false;
		private var _blockingStack:Array;
		
		protected var _jobCnt:int = 0;
		
		[Event(name="jobStackEmpty",type="com.coltware.airxlib.job.JobEvent")]
		
		public function JobSync(target:IEventDispatcher=null)
		{
			super(target);
			_jobStack = new ArrayCollection();
		}
		
		/**
		 * ジョブをスタートさせる前にこの処理を実行します。
		 * 
		 * この処理はSocketで接続をオープンした場合で、
		 * サーバからのOKをみてその結果、JOBの実行をする場合など、
		 * いつからJOBを実行してよいのかがわからない場合があります。
		 * そこでそのメソッドを実行してサービスを開始して問題ない状態にあることをを知らせます。
		 * 
		 * <p>特に、すぐにJOBを実行してもよい場合でも、このメソッドは実行する必要があります。</p>
		 */
		public function serviceReady():void{
			this._serviceReady = true;
			log.debug("prepared to accept job ....");
			//  ここですでにJOBがたまっているならば 
			if(_jobStack.length > 0 ){
				log.debug("job size is [" + _jobStack.length + "]");
				this.internalExec();
			}
			else{
				_jobStack.addEventListener(CollectionEvent.COLLECTION_CHANGE,internalExec,false,0,true);
				_watching = true;
			}
		}
		/**
		 * 現在、サービスが利用できるかどうか？
		 * 利用できる場合には事前に serviceReady()を実行している必要があります
		 * 
		 *  @see serviceRady()
		 */
		public function get isServiceReady():Boolean{
			return this._serviceReady;
		}
		/**
		 * 次の処理を登録する
		 * 
		 * <p>実際に登録したObjectをどのように処理するかはexecメソッド内で定義する必要があります。</p>
		 * 
		 */
		protected function addJob(job:Object):void{
			
			if(this.blockingMode){
				log.debug("block addJob + " + job);
				_blockingStack.push(job);
			}
			else{
				log.debug("addJob + " + job);
				_jobStack.addItem(job);
				this._jobCnt++;
			}
		}
		
		/**
		 *  現在のJOBスタックの指定位置に追加する。
		 *  通常は必要ないが、ある処理の後にどうしても、認証処理が必要に必要になってしまった・・・など。
		 * 
		 */
		protected function addJobAt(job:Object,index:int):void{
			_jobStack.addItemAt(job,index);
		}
		
		
		/**
		 * 内部で使用する処理を実施するためのメソッド
		 * 
		 */
		protected function internalExec(ce:CollectionEvent = null):void{
			if(_jobStack.length > 0){
				if(_watching){
					_jobStack.removeEventListener(CollectionEvent.COLLECTION_CHANGE,internalExec);
					_watching = false;
				}
				var job:Object = _jobStack.removeItemAt(0);
				this._executing = true;
				this.currentJob = job;
				if(job is IBlockable){
					if((job as IBlockable).isBlock()){
						this.blockingMode = true;
						this._blockingStack = new Array();
					}
				}
				this.exec(job);
			}
		}
		
		/**
		 * ここで非同期処理を実行する処理を実装してください
		 * 
		 * <p>例）</p>
		 * <pre>
		 * override public function exec(job:Object):void{
		 *     socket.writeUTFBytes(".....");
		 * }
		 * </pre>
		 * <p>のように定義し、データを受信し次に処理をしてよければその処理の中で
		 * commitJob()で完了を通知する。すると、次のJOBを実行しだす。
		 * </p>
		 */
		protected function exec(job:Object):void{
			// 非同期処理を実装する
		}
		
		/**
		 *  ジョブの終了時にこのメソッドを実行する。
		 * 
		 * 通常は、addEventListerner(type,function)のfunction の中でこの処理を実行します。
		 * 
		 */
		protected function commitJob():void{
			log.debug("commit job :[" + _jobStack.length + "]");
			
			if(this.blockingMode){
				if(this._blockingStack.length > 0 ){
					log.debug("move block stack to normal stack [" + this._blockingStack.length +"]");
					var _job:Object;
					while(_job = _blockingStack.pop()){
						this._jobStack.addItemAt(_job,0);
						this._jobCnt++;
					}
				}
				this.blockingMode = false;
			}
			
			this.currentJob = null;
			this._executing = false;
			this.internalExec();
			if(this._executing == false && this._watching == false && _jobStack.length < 1 ){
				//  変更後にイベントを実行できるように登録する
				this._watching = true;
				_jobStack.addEventListener(CollectionEvent.COLLECTION_CHANGE,internalExec,false,0,true);
				var e:JobEvent = new JobEvent(JobEvent.JOB_STACK_EMPTY);
				this.dispatchEvent(e);
			}
		}
		/**
		 *  現在残っているJOBの数を返す
		 */
		protected function get numberOfJobs():int{
			return _jobStack.length;
		}
		protected function clearJobs():void{
			_jobStack.removeAll();
		}
	}
}