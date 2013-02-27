package com.andrewwalpole.NetGrouper {
	
	import flash.events.Event;
	
	public class NetGrouperEvent extends Event {

		public static const POST:String = "NetGrouperEventPost";
		public static const RECEIVE:String = "NetGrouperEventReceive";
		public static const CONNECT:String = "NetGrouperConnected";
		public static const NEIGHBOR_CONNECT:String = "NetGrouperNeighborConnect";
		public static const NEIGHBOR_DISCONNECT:String = "NetGrouperNeighborDisconnect";
		public static const DISCONNECT:String = "NetGrouperDisconnected";

		public var message:Object;

		public function NetGrouperEvent( type:String, msg:Object, bubbles:Boolean = false, cancelable:Boolean = false) {
			super( type, bubbles, cancelable );
			message = msg;
		}
		
		public override function clone():Event {
            return new NetGrouperEvent(type, this.message, bubbles, cancelable);
        }
       
        public override function toString():String {
            return formatToString("NetGrouperEvent", "message", "type", "bubbles", "cancelable");
        }


	}
	
}
