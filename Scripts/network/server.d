module network.server;
version( Server ):

public import action;
import speed, speed.db;
//import vibe.d;
import core.thread;
import std.stdio, std.algorithm, std.concurrency;
import dvorm;
import vibe.d;

uint gamesPlayed;
uint numPlayers;
shared ConnectionManager connMan;

@dbName("turn")
class Turn
{
	uint gameID;
	uint actionID;
	uint originID;
	uint targetID;

	this( Action action, uint gameID )
	{
		setId();

		this.gameID = gameID;
		actionID = action.actionID;
		originID = action.originID;
		targetID = action.targetID;
	}

	Action toAction()
	{
		return Action( actionID, originID, targetID, true );
	}

	mixin SpeedModel!Turn;
}

static this()
{
	databaseConnection = DbConnection( DbType.Mongo, "127.0.0.1", ushort.init, null, null, "spectral" );
}

shared static this()
{
	auto settings = new HTTPServerSettings;
	settings.port = 9090;

	listenHTTP(settings, &handleRequest);
}

void handleRequest( HTTPServerRequest req, HTTPServerResponse res )
{
	writeln( "New http request." );
	res.writeBody( "Number of games played: " ~ ( gamesPlayed + 1 ).to!string ~ "\nNumber of active players: " ~ connMan.connections.length.to!string ~ ".", "text/plain" );
}

void main()
{
	for( gamesPlayed = 0; ; ++gamesPlayed )
	{
		numPlayers = 0;
		connMan = ConnectionManager.open();

		connMan.onNewConnection ~= ( shared Connection conn )
		{
			numPlayers++;
			writeln( "Now have ", numPlayers, " players." );
			conn.onReceiveData!string ~= ( string msg )
			{
				writeln( "Recieved message: ", msg );
				connMan.send!string( "ECHO: " ~ msg, ConnectionType.TCP );
				conn.send!uint( numPlayers );
				writeln( "numPlayers: ", numPlayers );

				if( msg == "ready")
				{
					auto turns = Turn.findAll().filter!(turn => turn.gameID == gamesPlayed);
					
					foreach( Turn t; turns )
					{
						writeln( "Sending turn: ",  t.toAction);
						conn.send!Action( t.toAction, ConnectionType.TCP );
					}
				}
			};

			conn.onReceiveData!Action ~= ( Action action )
			{
				writeln( "Received action: ", action.actionID, ",", action.originID, ",", action.targetID, ",", action.saveToDatabase );

				foreach( otherConn; connMan.connections )
				{
					if( cast()otherConn != cast()conn )
						otherConn.send!Action( action, ConnectionType.TCP );
				}

				if( action.saveToDatabase )
				{
					auto sesh = new Turn( action, gamesPlayed );
					sesh.save();
					writeln( "Saved session. New count: ", Turn.findAll().length );
				}
			};
		};

		connMan.start();

		// Wait for first player to connect.
		writeln( "Waiting for first player..." );
		while( connMan.connections.length == 0 )
		{
			processEvents();
		}

		writeln( "Player connected, now waiting for all connections to close." );
		// Wait for all players to disconnect.
		while( connMan.connections.length != 0 )
		{
			processEvents();
		}

		writeln( "All connections lost. restarting." );
		connMan.close();
		Thread.sleep( 500.msecs );
	}
}
