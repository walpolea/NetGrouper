package com.andrewwalpole.NetGrouper {
	
	import flash.events.EventDispatcher;
	import flash.net.NetGroup;
	import flash.net.NetConnection;
	import flash.events.NetStatusEvent;
	import flash.net.GroupSpecifier;
	
	public class NetGrouper extends EventDispatcher {

		public static const LOCAL_CONNECTION:String = 'localconnection';
		public static const CIRRUS_CONNECTION:String = 'cirrusconnection';
		public static const CIRRUS_SERVER:String = "rtmfp://p2p.rtmfp.net/";
		public static const LOCAL_SERVER:String = "rtmfp:";
		
		
		private var _connected:Boolean;
		private var _connectionType:String;
		private var _gid:String;
		
		public var neighbors:Array;
		public var peerID:String;
		
		private var nc:NetConnection;
		private var gs:GroupSpecifier;
		private var ng:NetGroup;
		
		//If you're gonna use Adobe's Cirrus server make sure you supply your developer key!
		public function NetGrouper( ConnectionType:String = NetGrouper.LOCAL_CONNECTION, GroupID:String = null, MulticastIP:String = "239.0.0.255:30304", DeveloperKey:String = "" ) {
			
			_connected = false;
			if( GroupID != null ) {
				connect( ConnectionType, GroupID, MulticastIP, DeveloperKey );
			}
			
		}
		
		public function connect( ConnectionType:String = NetGrouper.LOCAL_CONNECTION, GroupID:String = null, MulticastIP:String = "239.0.0.255:30304", DeveloperKey:String = "" ):void {
			_connectionType = ConnectionType;
			if( GroupID ) {
				_gid = GroupID;
			} else {
				_gid = "RandomNetGroup"+(int(Math.random()*1000000000)).toString();
			}
			
			trace( _gid );
			
			nc = new NetConnection();
			nc.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			
			if( _connectionType == NetGrouper.LOCAL_CONNECTION ) {
				
				gs = new GroupSpecifier(_gid);
				gs.postingEnabled = true;
				gs.routingEnabled = true;
				gs.ipMulticastMemberUpdatesEnabled = true;
				gs.addIPMulticastAddress(MulticastIP);
				
				nc.connect( NetGrouper.LOCAL_SERVER );
				
			} else if( _connectionType == NetGrouper.CIRRUS_CONNECTION ) {
				
				gs = new GroupSpecifier(_gid);
				gs.serverChannelEnabled = true;
				gs.postingEnabled = true;
				gs.routingEnabled = true;
				
				nc.connect( NetGrouper.CIRRUS_SERVER + DeveloperKey );
			}
		}
		
		private function onNetStatus( e:NetStatusEvent ):void {
			
			switch(e.info.code) {
				
				case "NetConnection.Connect.Success":
					trace('NetConnection Connected');
					setupGroup();
					break;
					
				case "NetGroup.Connect.Success":
					trace('NetGroup Connected');
					_connected = true;
					peerID = ng.convertPeerIDToGroupAddress(nc.nearID);
					if( neighbors ) {
						while( neighbors.length ) {
							neighbors.shift();
						}
					} else {
						neighbors = [];
					}
					dispatchEvent( new NetGrouperEvent( NetGrouperEvent.CONNECT, {sender:peerID, group:e.info.group} ));
					break;
		 		case "NetGroup.SendTo.Notify":
				case "NetGroup.Posting.Notify":
				trace( "got message" );
					receiveMessage( e.info.message );
					break;
				
				case "NetGroup.Neighbor.Connect":
					trace( "Neighbor Connected: ", e.info.neighbor , e.info.peerID );
					dispatchEvent( new NetGrouperEvent( NetGrouperEvent.NEIGHBOR_CONNECT, {id:e.info.neighbor} ));
					addNeighbor( e.info.neighbor, e.info.peerID );
					break;
					
				case "NetGroup.Neighbor.Disconnect":
					trace( "Neighbor Disconnected: ", e.info.neighbor , e.info.peerID );
					dispatchEvent( new NetGrouperEvent( NetGrouperEvent.NEIGHBOR_DISCONNECT, {id:e.info.neighbor} ));
					removeNeighbor( e.info.neighbor );
					break;
			}

		}
		
		public function post( message:Object ):void {
			
			message.sender = ng.convertPeerIDToGroupAddress(nc.nearID);
			
			if( _connected ) {
				if( ng.neighborCount < 14 ) { 
					ng.sendToAllNeighbors( message );
				} else {
					//post is MUCH slower than sendToAllNeighbors but when there are more than 13 connections
					//however post is more reliable than sendToAllNeighbors because not everyone is neighbors
					//above 13 connections.
					ng.post( message );
				}
				dispatchEvent( new NetGrouperEvent( NetGrouperEvent.POST, message ) );
			}
		}
		
		private function receiveMessage( message:Object ):void {
			dispatchEvent( new NetGrouperEvent( NetGrouperEvent.RECEIVE, message ) );
		}
		
		private function setupGroup():void {
			ng = new NetGroup( nc, gs.groupspecWithAuthorizations() );
			ng.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
		}
		
		private function addNeighbor( neighborID:String, peerID:String ):void {
			neighbors.push( { neighborID:neighborID, peerID:peerID } );
		}
		
		private function removeNeighbor( neighborID:String ):void {
			for( var i:int = 0; i < neighbors.length; i++ ) {
				if( neighborID == neighbors[i].neighborID ) {
					neighbors.splice( i, 1 );
					return;
				}
			}
		}
		
		public function getNeighbor( neighborID:String ):Object {
			for( var i:int = 0; i < neighbors.length; i++ ) {
				if( neighborID == neighbors[i].neighborID ) {
					return neighbors[i];
				}
			}
			
			return undefined;
		}
		
		public function disconnect():void {
			ng.close();
		}
		
		
	}
	
}
