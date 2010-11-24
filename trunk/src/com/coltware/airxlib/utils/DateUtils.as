/**
 *  Copyright (c)  2009 coltware@gmail.com
 *  http://www.coltware.com 
 *  
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 * 
 */
package com.coltware.airxlib.utils
{
	
	/**
	 *  日付の表示をPHPのdate関数のようにしたいということを実現するクラス
	 * 
	 *  ただし、実装されていないものもあるので、注意してください。
	 */
	public class DateUtils {
		
		public static var UTC:Boolean = false;
		
		public static const DAY_SHORT_NAMES:Array 		= ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
		public static const DAY_FULL_NAMES:Array  		= ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
		public static const MONTH_SHORT_NAMES:Array 	= ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
		public static const MONTH_FULL_NAMES:Array		= ["January", "February", "March", "April","May", "June", "July", "August","September", "October", "November", "December"];
		
		
		/**
		 * フォーマットで与えられたように日付を出力する
		 * 
		 * <pre>
		 * var now:Date = new Date();
		 * 
		 * //  以下の２つはほぼ同じ（date == null の場合には内部でnew Date()を実施している
		 * dateToString("y/m/d",now);
		 * dateToString("y/m/d");
		 * 
		 * </pre>
		 * 
		 * formatとして使える文字
		 *
		 * 日
		 * <ul>
		 * <li>d: 日 (01から31)</li>
		 * <li>D: 曜日(MonからSun, ただし、第３引数の opts["D"][Array]で変更することも可能)</li>
		 * <li>j: 日 (1から31 - 先頭に0がない)</li>
		 * <li>l(小文字L): 曜日(Sunday から Saturday, ただし、第３引数で変更可能）</li>
		 * <li>w: 曜日(数値、0-日曜から6-土曜)</li>
		 * </ul>
		 * 
		 * 月
		 * <ul>
		 * <li>F: (January - December)</li>
		 * <li>m:月 01-12</li>
		 * <li>M:月 (Jan-Dec, ただし、第３引数で変更可能)</li>
		 * <li>n:月 1-12(先頭に0はない)</li>
		 * <li>t:指定した付きの日数 28-31</li>
		 * </ul>
		 * <li>i</li>
		 * </ul>
		 *
		 * 年
		 * <ul>
		 *   <li>Y:年 4桁の数字</li>
		 *   <li>y:年 2桁の数字 99や09</li>
		 * </ul>
		 *
		 * 時
		 * <ul>
		 *   <li>a: amまたはpm</li>
		 *   <li>A: AMまたはPM</li>
		 *   <li>g: 時:12時間単位。先頭にゼロをつけない</li>
		 *   <li>G: 時:24時間単位。先頭にゼロをつけない</li>
		 *   <li>h: 時:12時間単位。01-12</li>
		 *   <li>H: 時:24時間単位。01-24</li>
		 *   <li>i: 分:先頭にゼロをつける 00-59</li>
		 *   <li>s: 秒:先頭にゼロをつける 00-59</li>
		 * </ul>
		 *
		 * タイムゾーン
		 * <ul>
		 *   <li>O: GMTとの時差( +0200 )</li>
		 *   <li>P: GMTとの時差( +02:00 )</li>
		 * </ul>
		 *
		 * 全ての日付/時刻
		 *
		 * <ul>
		 *   <li>c: ISO8601日付 2004-02-12T15:19:21+09:00</li>
		 *   <li>r: RFC2822形式 Thu, 21 Dec 2000 16:01:07 +0900</li>
		 * </ul>
		 */
		public static function dateToString(format:String,dateOrNumber:Object = null,opts:Object = null):String{
			var ret:String = "";
			var date:Date;
			if(dateOrNumber == null){
				date = new Date();
			}
			else{
				if(dateOrNumber is Number){
					date = new Date();
					date.setTime(dateOrNumber);
				}
				else if(dateOrNumber is Date){
					date = dateOrNumber as Date;
				}
				else{
					date = new Date();
				}
			}
			var escape:Boolean = false;
			var len:int = format.length;
			var pre:String = "";
			for(var i:int=0; i<len; i++){
				var ch:String = format.charAt(i);
				
				if(escape){
					if(ch == " "){
						escape = false;
					}
					if(ch == "\\"){
						if(pre == "\\"){
							ret += ch;
							ch = "";
						}
					}
					else{
						ret += ch;
					}
				}
				else
				switch(ch){
					case "d":
						var _date:Number;
						(UTC)? _date = date.dateUTC: _date = date.date;
						if(_date < 10 ){
							ret += "0";
						}
						ret += _date;
						break;
					case "D":
						var day:Number;
						(UTC)? day = date.dateUTC : day = date.day;
						if(opts != null && opts.hasOwnProperty("D")){
							ret += opts["D"][day];
						}
						else{
							ret += DAY_SHORT_NAMES[day];
						}
						break;
					case "j":
						ret += (UTC)? date.dateUTC: date.date;
						break;
					case "l":
						if(opts != null && opts.hasOwnProperty("l")){
							ret += opts["l"][date.day];
						}
						else{
							ret += DAY_FULL_NAMES[date.day];
						}
						break;
					case "w":
						ret += date.day;
						break;
					case "F":
						if(opts != null && opts.hasOwnProperty("F")){
							ret += opts["F"][date.month];
						}
						else{
							ret += MONTH_FULL_NAMES[date.month];
						}
						break;
					case "m":
						var m:int = (UTC)? date.monthUTC: date.month;
						m = m + 1;
						if(m<10){
							ret += "0";
						}
						ret += m;
						break;
					case "M":
						if(opts != null && opts.hasOwnProperty("M")){
							ret += opts["M"][date.month];
						}
						else{
							ret += MONTH_SHORT_NAMES[date.month];
						}
						break;
					case "n":
						var n:int = (UTC)? date.monthUTC : date.month;
						n += 1;
						ret += n;
						break;
					case "t":
						ret += getLastDay(date);
						break;
					case "Y":
						(UTC)?  ret+= date.fullYearUTC : ret += date.fullYear;
						break;
					case "y":
						var y:String = (UTC)? String(date.fullYearUTC) : String(date.fullYear);
						ret += y.substr(2);
						break;
					case "a":
						if(date.hours > 11 ){
							if(opts != null && opts.hasOwnProperty("a")){
								ret += opts["a"][1];
							}
							else{
								ret += "pm";
							}
						}
						else{
							if(opts != null && opts.hasOwnProperty("a")){
								ret += opts["a"][0];
							}
							else{
								ret += "am";
							}
						}
						break;
					case "A":
						if(date.hours > 11 ){
							if(opts != null && opts.hasOwnProperty("A")){
								ret += opts["A"][1];
							}
							else{
								ret += "PM";
							}
						}
						else{
							if(opts != null && opts.hasOwnProperty("A")){
								ret += opts["A"][0];
							}
							else{
								ret += "AM";
							}
						}
						break;
					case "g":
						var g:int = date.hours;
						if(date.hours > 11){
							g = g - 12;
						}
						ret += g;
						break;
					case "G":
						ret += date.hours;
						break;
					case "h":
						var h:int = (UTC)? date.hoursUTC : date.hours;
						if(h > 11 ){
							h = h -12;
						}
						if(h < 10){
							ret += "0";
						}
						ret += h;
						break;
					case "H":
						var _hour:Number = (UTC)? date.hoursUTC: date.hours;
						if(_hour < 10){
							ret += "0";
						}
						ret += _hour;
						break;
					case "i":
						var _min:Number = (UTC)? date.minutesUTC: date.minutes;
						if(_min < 10){
							ret += "0";
						}
						ret += _min;
						break;
					case "s":
						var _sec:Number = (UTC)? date.secondsUTC: date.seconds;
						if(_sec < 10){
							ret += "0";
						}
						ret += _sec;
						break;
					case "O":
						ret += _gmt(date,"");
						break;
					case "P":
						ret += _gmt(date);
						break;
					case "c":
						ret += DateUtils.dateToString("Y-m-dTH:i:sP",date);
						break;
					case "r":
						ret += DateUtils.dateToString("D, d M Y H:i:s O",date);
						break;
					case "\\":
						escape = true;
						break;
					default:
						ret += ch;
						break;
				}
				pre = ch;
			}
			return ret;
		}
		
		/**
		 *  指定された月の最後の日を返す.
		 *
		 */
		public static function getLastDay(dateOrYear:Object, month:int = -1):int{
			var dd:Date;
			if(dateOrYear is Date){
				dd = new Date(dateOrYear.fullYear,dateOrYear.month + 1,1,0,0,0,0);
			}
			else{
				var year:Number = Number(dateOrYear);
				if(month == -1){
					throw new Error("required second argument"); 
				}
				dd = new Date(year,month + 1,1,0,0,0,0);
			}
			var t:Number = dd.getTime();
			t = t -  1000;
			dd.setTime(t);
			return dd.date;
		}
		
		/**
		*
		*  基本的には Date.parse() 関数と同様。ただし、hintに文字列を入れることでparse関数で対応していないものも対応
		*
		*  現在、hintに使える文字列は
		*
		*  c: ISO8601形式
		*  r:  RFC2822
		*/
		public static function strToTime(str:String,hint:String = null):Number{
			try{
				var t:Number = Date.parse(str);
				if(isNaN(t)){
					if(hint == "c"){
						// ISO8601 形式
						var p:Array = str.match(/^(\d{4})-(\d{2})-(\d{2})T([0-9:]*)([.0-9]*)(.)(.*)$/);
						if(p[6] == "Z"){
							// UTC
							str = p[1] + "/" + p[2] + "/" + p[3] + " " + p[4] + " UTC-0000";
						}
						else{
							str = p[1] + "/" + p[2] + "/" + p[3] + " " + p[4] + " GMT" + p[6] + p[7].replace(":","");
						}
						t = Date.parse(str);
					}
					else if(hint == "r"){
						var pos:int = str.indexOf("(");
						if(pos){
							str = str.substr(0,pos);
							t = Date.parse(str);
						}
					}
				}
				return t;
			}
			catch(err:Error){
				return NaN;
			}
			return NaN;
		}
		
		private static function _gmt(d:Date,glue:String = ":"):String{
			var diff:Number = d.getTimezoneOffset()/60;
			var str:String;
			diff = diff * -1;
			if(diff > 9 ){
				str = "+" + String(diff) + glue + "00";
			}
			else if(diff > 0 ){
				str = "+0" + String(diff) + glue + "00";
			}
			else if(diff == 0){
				str = "+00" + glue + "00";
			}
			else if(diff < -9 ){
				str = String(diff) + glue + "00";
			}
			else{
				str = "-0" + String(diff * -1) + glue + "00";
			}
			return str;
		}
	}
}