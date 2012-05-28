package com.coltware.airxlib.http
{
	public interface IHttpRequest
	{
		function get url():String;
		function get method():String;
		
		function getHeader(key:String):String;
	}
}