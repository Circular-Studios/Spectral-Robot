module network.server;
version( Server ):
//import utility;

import action;
import speed;//, speed.db;
//import vibe.d;
import core.thread;
import std.stdio, std.string;

void main()
{
	while( true )
	{
		uint numPlayers = 0;
		auto connMan = ConnectionManager.open();

		connMan.onNewConnection ~= ( shared Connection conn )
		{
			numPlayers++;
			conn.onReceiveData!string ~= ( string msg )
			{
				writeln( "Recieved message: ", msg );
				connMan.send!string( "ECHO: " ~ msg, ConnectionType.TCP );
				conn.send!uint( numPlayers );
				writeln( "numPlayers: ", numPlayers );
			};

			conn.onReceiveData!Action ~= ( Action action )
			{
				writeln( "Received action: ", action.actionID, ",", action.originID, ",", action.targetID, ",", action.saveToDatabase );

				foreach( otherConn; connMan.connections )
				{
					if( cast()otherConn != cast()conn )
						otherConn.send!Action( action, ConnectionType.TCP );
				}
			};
		};

		connMan.start();

		// Hit enter to restart.
		if( readln().chomp().toLower() == "exit" )
		{
			connMan.close();
			return;
		}

		connMan.close();
		Thread.sleep( 500.msecs );
	}
}
