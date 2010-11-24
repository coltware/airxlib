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
	
	import flash.events.*;
	import flash.utils.Dictionary;
	import mx.events.CollectionEvent;
	import mx.collections.ArrayCollection;
	
	/**
	 *   非同期処理や、ユーザイベントなどを依存させて実施するためのクラス.
	 *
	 * <pre>
	 * var flow:JobFlow = new JobFlow();
	 * 
	 * //  何らかの非同期処理をイベントとして登録する
	 * foo.addEventListener(eventName,init);
	 * foo.addEventListener(eventName,exec1);
	 * foo.send();
	 * 
	 * //  init の処理が完了したらexec1を実施する
	 * flow.addDependsListener(exec1,init);
	 * //  exec1 が完了して、なおかつ"FOO"という文字列が満たしたらexec2を実施する
	 * flow.addDependsListener(exec2,exec1,"FOO");
	 * 
	 * private function init(e:Events):void{
	 * 	trace("exec init"); 
	 * 	flow.doneDepend(init); // <-- 終わったことを伝える
	 * }
	 * private functon exec1():void{
	 *   trace("exec exec1");
	 * 	 flow.doneDepend(exec1);
	 *   if(....){
	 * 		flow.doneDepend("FOO");  // <-- exec2 が実行される条件
	 *   }
	 * }
	 * private function exec2():void{
	 * 	 trace("exec exec2");
	 *   flow.doneDepend(exec2);     //  <--  別にどこにも依存していない処理を加えても問題にはならない。
	 * }
	 * 
	 * ////// 実行結果  /////////
	 * exec init
	 * exec exec1
	 * exec exec2
	 * 
	 * </pre>
	*/
	public class JobFlow extends EventDispatcher{
		
		//  後で何かイベントを発行する必要があると思うので、EventDispatcherを継承している
		
		private var _dict:Dictionary;
		private var _dictKeys:ArrayCollection;
		
		public function JobFlow() {
			_dict = new Dictionary();
			_dictKeys = new ArrayCollection();
		}
		
		/**
		*  他の処理依存関数を登録する
		*/
		public function addDependsListener(listener:Function, ... rest):void{
			var depends:ArrayCollection = new ArrayCollection();
			var len:uint = rest.length;
			var arr:Array;
			
			if(len == 1 && rest[0] is Array){
				depends.source = rest[0] as Array;
				len = rest[0].length;
				arr = rest[0];
			}
			else{
				depends.source = rest;
				arr = rest;
			}
			
			//  自分の依存が自分に依存していないかチェック
			for(var i:int = 0; i<len; i++){
				if(arr[i] is Function){
					if(hasDepend(arr[i],listener)){
						throw new Error("Loop depend  !!");
					}
					if(arr[i] == listener){
						//  自分の処理が自分自身に依存している
						throw new Error("Depends on myself !!");
					}
				}
				
			}
			var _org:Array = rest.concat();
			
			_dict[listener] = [depends,_org];
			_dictKeys.addItem(listener);
			
		}
		
		/**
		*  指定した依存関数を削除する
		*/
		public function removeDependsListener(listener:Function):void{
			if(hasDependsListener(listener)){
				_dict[listener] = null;
				delete _dict[listener];
				var ia:int = _dictKeys.getItemIndex(listener);
				if(ia >= 0){
					_dictKeys.removeItemAt(ia);
				}
			}
		}
		
		/**
		*  依存関数が登録されているか
		*/
		public function hasDependsListener(listener:Function):Boolean{
			var ia:int = _dictKeys.getItemIndex(listener);
			if(ia >= 0){
				return true;
			}
			else{
				return false;
			}
		}
		
		/**
		*  依存しているかどうか?
		*/
		public function hasDepend(listener:Function,depend:Object):Boolean{
			
			if(_dict[listener]){
				var arr:ArrayCollection = _dict[listener][0] as ArrayCollection;
				var ia:int = arr.getItemIndex(depend);
				if(ia >= 0){
					return true;
				}
				
			}
			return false;
		}
		
		/**
		*  指定の依存処理が完了したことを通知する
		*/
		public function doneDepend(depend:Object):void{
			for each(var listener:Object in _dictKeys){
				var arrs:ArrayCollection = _dict[listener][0];
				var ia:int = arrs.getItemIndex(depend);
				if(ia >= 0){
					arrs.removeItemAt(ia);
					if(arrs.length < 1 ){
						// すべての依存がなくなったので処理を実行する
						var fire:Function = listener as Function;
						fire();
						
						// 全部消えたら再度、依存をもとに戻す
						_dict[listener][0].source = _dict[listener][1].concat();
					}
				}
			}
		}
		/**
		 * タスクをすべてリセットする.
		 * 
		 * doneDependが何も実行されていない状態にリセットされる。
		 * 
		 */
		public function reset():void{
			for each(var listener:Object in _dictKeys){
				_dict[listener][0].source = _dict[listener][1].concat();
			}
		}
	}
}