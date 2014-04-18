module network.server;
version( Server ):
//import utility;

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
	};

	connMan.start();
}
