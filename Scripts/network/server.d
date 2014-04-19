module network.server;
version( Server ):
//import utility;

public import action;
import speed, speed.db;
//import vibe.d;
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
	auto connMan = ConnectionManager.open();
	auto gameID = 0;

	connMan.onNewConnection ~= ( shared Connection conn )
	{
		conn.onReceiveData!string ~= ( string msg )
		{
			if( msg == "ready")
			{
				auto turns = Turn.findAll().filter!(turn => turn.gameID == gameID);
				
				foreach( Turn t; turns )
				{
					writeln( "Sending turn: ",  t.toAction);
					connMan.send!Action( t.toAction, ConnectionType.TCP );
				}
			}

			writeln( "Recieved message: ", msg );
			connMan.send!string( "ECHO: " ~ msg, ConnectionType.TCP );
		};

		conn.onReceiveData!Action ~= ( Action action )
		{
			writeln( "Received action: ", action.actionID, ",", action.originID, ",", action.targetID, ",", action.saveToDatabase );
			connMan.send!Action( action, ConnectionType.TCP );

			if( action.saveToDatabase )
			{
				auto sesh = new Turn( action, gameID );
				sesh.save();
				writeln( "Saved session. New count: ", Turn.findAll().length );


				//Turn.findAll().filter!(turn => turn.gameID == gameID);
			}
		};
	};

	connMan.start();
}
