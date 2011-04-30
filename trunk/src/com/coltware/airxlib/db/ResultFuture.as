package com.coltware.airxlib.db
{
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	
	import mx.logging.ILogger;
	import mx.logging.Log;

	public class ResultFuture implements IResultFuture
	{
		private static const log:ILogger = Log.getLogger("com.coltware.airxlib.db.ResultFuture");
		
		private var _stmt:SQLStatement;
		private var _resultFunc:Function;
		private var _exec:Boolean = false;
		private var _error:Boolean = false;
		
		private var _type:String;
		
		public function ResultFuture(stmt:SQLStatement)
		{
			this._stmt = stmt;
			this._stmt.addEventListener(SQLEvent.RESULT,resultHandler);
			this._stmt.addEventListener(SQLErrorEvent.ERROR,errorHandler);
		}
		
		
		public function result(func:Function):void
		{
			this._resultFunc = func;
			log.debug("execute..." + this._stmt.text);
			this._stmt.execute();
		}
		
		public function resultOne(func:Function):void{
			this._type = "one";
			this.result(func);
		}
		
		public function resultRow(func:Function):void{
			this._type = "row";
			this.result(func);
		}
		
		private function resultHandler(event:SQLEvent):void{
			log.debug("resultHandler...");
			var result:SQLResult = this._stmt.getResult();
			if(this._type == "one"){
				if(result.data.length == 1){
					var ret:Object = result.data[0];
					var exec:Boolean = false;
					for(var key:String in ret){
						if(exec == false){
							this._resultFunc(ret[key]);
							this._resultFunc = null;
							exec = true;
						}
					}
				}
			}
			else if(this._type == "row"){
				if(result.data){
					if(result.data.length == 1){
						this._resultFunc(result.data[0]);
					}
					else{
						this._resultFunc(null);
					}
				}
				else{
					this._resultFunc(null);
				}
				
			}
			else{
				this._resultFunc(result);
			}
		}
		private function errorHandler(event:SQLErrorEvent):void{
			_resultFunc = null;
			_error = true;
		}
	}
}