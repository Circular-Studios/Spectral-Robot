module network.server;
version( Server ):
//import utility;

import action;
import speed, speed.db;
//import vibe.d;
import std.stdio;

void main()
{
	auto connMan = ConnectionManager.open();

	connMan.onNewConnection ~= ( shared Connection conn )
	{
		conn.onReceiveData!string ~= ( string msg )
		{
			writeln( "Recieved message: ", msg );
			connMan.send!string( "ECHO: " ~ msg, ConnectionType.TCP );
		};

		conn.onReceiveData!Action ~= ( Action action )
		{
			writeln( "Received action: ", action.actionID, ",", action.originID, ",", action.targetID, ",", action.saveToDatabase );
			connMan.send!Action( action, ConnectionType.TCP );
		};
	};

	connMan.start();
}
