module network.server;
version( Server ):

public import action;
import speed, speed.db;
//import vibe.d;
import core.thread;
import std.stdio, std.algorithm;

import dvorm;

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


void main()
{
	for( uint gamesPlayed = 0; ; ++gamesPlayed )
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

				/*
				if( msg == "ready")
				{
					auto turns = Turn.findAll().filter!(turn => turn.gameID == gameID);
					
					foreach( Turn t; turns )
					{
						writeln( "Sending turn: ",  t.toAction);
						connMan.send!Action( t.toAction, ConnectionType.TCP );
					}
				}
				*/
			};

			conn.onReceiveData!Action ~= ( Action action )
			{
				writeln( "Received action: ", action.actionID, ",", action.originID, ",", action.targetID, ",", action.saveToDatabase );

				foreach( otherConn; connMan.connections )
				{
					if( cast()otherConn != cast()conn )
						otherConn.send!Action( action, ConnectionType.TCP );
				}

				/*
				if( action.saveToDatabase )
				{
					auto sesh = new Turn( action, gamesPlayed );
					sesh.save();
					writeln( "Saved session. New count: ", Turn.findAll().length );


					//Turn.findAll().filter!(turn => turn.gameID == gamesPlayed);
				}
				8*/
			};
		};

		connMan.start();

		// Wait for all players to disconnect.
		while( numPlayers != 0 ) { }

		connMan.close();
		Thread.sleep( 500.msecs );
	}
}
