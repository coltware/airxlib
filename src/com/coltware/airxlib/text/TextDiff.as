/**
 *  Copyright (c)  2009 coltware@gmail.com
 *  http://www.coltware.com 
 *
 *  License: LGPL v3 ( http://www.gnu.org/licenses/lgpl-3.0-standalone.html )
 *
 * @author coltware@gmail.com
 */
package com.coltware.airxlib.text {
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	use namespace text_internal;
	
	public class TextDiff {
		
		private static const log:ILogger = Log.getLogger("com.coltware.airxlib.text.TextDiff");
		
        public static const V_INIT:int = 0;
        public static const V_X:int = 1;
        public static const V_Y:int = 2;
        
        public function TextDiff() {
            
        }
        
        public function execute(str1:String,str2:String):Array{
        	
          var ret:Array = new Array();
          var point:Object = get_endPoint(str1,str2);
          var diff_string:String = "";
          
          var curNode:TextNode;
          
          if(point){
             while(point.parent != null){
                  var parent:Object = point.parent;
                  var diff_x:int = point.x - parent.x;
                  var diff_y:int = point.y - parent.y;
                  var same_len:int = Math.min(diff_x,diff_y);
                  
                  var diffChar:String;
                  
                  for(var i:int = 0; i < same_len; i++){
                  	var sameNode:TextNode;
                  	if(curNode != null && curNode.$type == TextNode.SAME_TEXT){
                  		sameNode        = curNode;
                  		sameNode.$start = point.x - i - 1;
                  		sameNode.$text  = str1.charAt(sameNode.$start) + sameNode.$text;
                  	}
                  	else{
                        sameNode =  new TextNode();
                        sameNode.$type = TextNode.SAME_TEXT;
                        sameNode.$end     = point.x - i - 1;
                        sameNode.$start   = point.x - i - 1;
                        sameNode.$text = str1.charAt(sameNode.$start);
                        ret.push(sameNode);
                        curNode = sameNode;
                  	}
                  }
                  
                  if( diff_y < diff_x ){
                  	var diffFromNode:TextNode;// = new TextNode();
                  	if(curNode != null && curNode.$type == TextNode.DEL_TEXT){
                  		diffFromNode          = curNode;
                  		diffFromNode.$start   = parent.x;
                  		diffFromNode.$text = str1.charAt(parent.x) + diffFromNode.$text;
                  	}
                  	else{
                  	   diffFromNode = new TextNode();
                       diffFromNode.$type = TextNode.DEL_TEXT;
                       diffFromNode.$end     = parent.x;
                       diffFromNode.$start   = parent.x;
                       diffFromNode.$text = str1.charAt(parent.x);
                       ret.push(diffFromNode);
                  	}
                    curNode = diffFromNode;
                  }
                  else if(diff_x < diff_y ){
                  	var diffToNode:TextNode = new TextNode();
                  	if(curNode != null && curNode.$type == TextNode.ADD_TEXT){
                  		diffToNode = curNode;
                        diffToNode.$start = parent.y;
                        diffToNode.$text  = str2.charAt(parent.y) + diffToNode.$text;
                  	}
                  	else{
                        diffToNode = new TextNode();
                        diffToNode.$type = TextNode.ADD_TEXT;
                        diffToNode.$end     = parent.y;
                        diffToNode.$start   = parent.y;
                        diffToNode.$text = str2.charAt(parent.y);
                        ret.push(diffToNode);
                  	}
                    curNode = diffToNode;
                  }
                  point = parent;
             }
             return ret.reverse();
          }
          return ret.reverse();
        }
        
        public function get_vstat(v_minus:Object, v_plus:Object):int{
          if((v_minus == null) && (v_plus == null)){
            return V_INIT;
          }
          if(v_minus == null){
            return V_X;
          }
          if(v_plus == null){
            return V_Y;
          }
          if(v_minus.x < v_plus.x){
            return V_X;
          }
          else{
            return V_Y;
          }
        }
        
        public function get_endPoint(str1:String,str2:String):Object{
            var v:Object = new Object;
            var offset:int = str2.length + 1;
            
            var total:int = str1.length + str2.length;
            for(var d:int = 0; d <= total; d++){
                 var k_max:int = ( d <= str1.length ) ? d : ( str1.length - ( d - str1.length) );
                 var k_min:int = ( d <= str2.length ) ? d : ( str2.length - ( d - str2.length) );
                 
                 for(var k:int = -k_min; k <= k_max; k+=2 ){
                     var index:int = offset + k;
                     var x:int;
                     var y:int;
                     var parent:Object;
                     
                     switch(get_vstat(v[index-1],v[index+1])){
                         case V_INIT:
                             x = 0;
                             y = 0;
                             parent = new Object();
                             parent.x = 0;
                             parent.y = 0;
                             parent.parent = null;
                             break;
                         case V_X:
                             x = v[index+1].x;
                             y = v[index+1].y + 1;
                             parent = v[index+1];
                             break;
                         case V_Y:
                             x = v[index-1].x + 1;
                             y = v[index-1].y;
                             parent = v[index-1];
                             break;
                            
                     }
                     while(((x < str1.length) && ( y < str2.length)) &&  ( str1.charAt(x) == str2.charAt(y))){
                        x++;
                        y++;
                     }
                     var vobj:Object = new Object();
                     vobj.x = x;
                     vobj.y = y;
                     vobj.parent = parent;
                     v[index] = vobj;
                     
                     if((str1.length <= x) && (str2.length <= y )){
                        return v[index];
                     }
                 }
            }
        return null;    
        }
    }
}