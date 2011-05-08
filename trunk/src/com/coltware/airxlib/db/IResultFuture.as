package com.coltware.airxlib.db
{
	public interface IResultFuture
	{
		function result(func:Function):void;
		
		function resultOne(func:Function):void;
		
		function resultRow(func:Function):void;
		
		function setArgs(...args):void;
			
		function getArgs():Array;
		
		function getArgOne():Object;
	}
}