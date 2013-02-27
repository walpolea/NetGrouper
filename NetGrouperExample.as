package  {
	
	import flash.display.MovieClip;
	import com.andrewwalpole.NetGrouper.NetGrouper;
	import com.andrewwalpole.NetGrouper.NetGrouperEvent;
	import flash.events.MouseEvent;
	
	
	public class NetGrouperExample extends MovieClip {
		
		private var netgrouper:NetGrouper;
		
		private var playerid:String;
		private var player:Player;
		
		private var opponents:Object; //dictionary of Opponents
		
		public function NetGrouperExample() {
						
			netgrouper = new NetGrouper();
			
			//happens when you successfully connect to the group
			netgrouper.addEventListener( NetGrouperEvent.CONNECT, onConnected );
			//happens when someone else connects to the group
			netgrouper.addEventListener( NetGrouperEvent.NEIGHBOR_CONNECT, onNeighborConnected );
			//happens when someone else disconnects from the group
			netgrouper.addEventListener( NetGrouperEvent.NEIGHBOR_DISCONNECT, onNeighborDisconnected );
			//happens when you receive any kind of post from anyone
			netgrouper.addEventListener( NetGrouperEvent.RECEIVE, onReceivePost );
			
			connectLocally();
			//connectCirrus();
			
			
		}
		
		public function connectLocally():void {
			//Connect over a local network (WIFI connections behind multiple firewalls can have issues with this)
			netgrouper.connect( NetGrouper.LOCAL_CONNECTION, "com/andrewwalpole/NetGrouperExample" );
		}
		
		public function connectCirrus():void {
			//Connect over Adobe's Cirrus, you don't need to specify a MulticastIP if you do this, but you need to include your Cirrus Developer Key
			//Get your key here: http://labs.adobe.com/technologies/cirrus/
			netgrouper.connect( NetGrouper.CIRRUS_CONNECTION, "com/andrewwalpole/NetGrouperExample", null, "Your Developer Key" );
		}
		
		private function onConnected( e:NetGrouperEvent ):void {
			
			opponents = {}; //init opponents array
			
			//e.message.sender is your ID!
			playerid = e.message.sender;
			
			createPlayer();
			stage.addEventListener( MouseEvent.MOUSE_MOVE, onMouseMoving );
		}
		
		public function onNeighborConnected( e:NetGrouperEvent ):void {
			
			trace( "SOMEONE CONNECTED WITH ID ", e.message.id );
			addOpponent( e.message.id, e.message.playerx, e.message.playery );
			
		}
		
		public function onNeighborDisconnected( e:NetGrouperEvent ):void {
			if( opponents[e.message.id] ) {
				removeChild(opponents[e.message.id]);
				opponents[e.message.id] = null;
			}
		}
		
		public function onReceivePost( e:NetGrouperEvent ):void {
			
			//e.message.sender is the ID of whoever sent this message
			
			switch( e.message.action ) {
				case "PLAYER_UPDATE":
					opponents[e.message.sender].x = e.message.playerx;
					opponents[e.message.sender].y = e.message.playery;
				break;
			}
		}
		
		private function createPlayer():void {
			player = new Player();
			addChild( player );
		}
		
		public function addOpponent( id:String, ox:Number, oy:Number ):void {
			
			var o:Player = new Player();
			o.x = ox;
			o.y = oy;
			
			addChild( o );
			
			opponents[id] = o; //store the opponent by their id, this makes life easier
		}
		
		private function onMouseMoving( e:MouseEvent ):void {
			//update your view
			player.x = e.stageX;
			player.y = e.stageY;
			
			//update their view by sending a data object, you can send all kinds of data!
			netgrouper.post( { action:"PLAYER_UPDATE", playerx:player.x, playery:player.y } );
			//for real life you might want to post an update based on a timer or something a bit
			//slower than mouse move or enter frame.
		}
		
	}
	
}
