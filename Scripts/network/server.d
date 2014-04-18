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
		writeln( "New Connection, ord!string: ", conn.onReceiveData!string.length );
		conn.onReceiveData!string ~= ( string msg )
		{
			writeln( "Recieved message: ", msg );
			conn.send!string( "LOUD AND CLEAR" );
		};
	};

	connMan.start();
}
