package com.coltware.airxlib.db
{
	public interface IResultFuture
	{
		function result(func:Function):void;
		function resultOne(func:Function):void;
	}
}