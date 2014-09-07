module aiManager;
import game, unit, turn, ability, effect, grid, tile, action;
import dash.core, dash.utility;

class AiManager
{

	AiPlayer[] _aiPlayers;

	this()
	{
		_aiPlayers = new AiPlayer[]( 2 );
		_aiPlayers[ 0 ] = new AiPlayer( Team.Robot );
		_aiPlayers[ 1 ] = new AiPlayer( Team.Wolf );
	}

	void startTurn(Team activeTeam)
	{
		for( int i = 0; i < 2; i++ )
		{
			if ( _aiPlayers[ i ]._team == activeTeam && activeTeam == Team.Wolf)
			{
				_aiPlayers[ i ].doTurn();
			}
		}
	}

}

class AiPlayer
{
	Team _team;
	Team _enemyTeam;
	bool deathMarch;
	int maxJumpDistance;

	this(Team team)
	{
		_team = team;
		_enemyTeam = Team.Robot;
		if( _enemyTeam == _team ) _enemyTeam = Team.Wolf;

		deathMarch = true;
		maxJumpDistance = 5;
	}

	void doTurn()
	{
		if( deathMarch )
		{
			Unit[] teamUnits = Game.turn.getUnitsOnTeam( _team );

			// Iterate through units
			for( int i = 0; i < teamUnits.length; i++ )
			{
				// if no unit exists, skip it
				if( teamUnits[i] is null ) continue;

				Tile currentTile = Game.grid.getTileByID( teamUnits[i].position );

				int x = currentTile.x();
				int y = currentTile.y();

				Tile destinationTile;
				
				// move to the next valid tile
				int j = 0;
				do
				{
					y++;
					if( !Game.grid.isTileOpen( x, y ) ) continue;
					destinationTile = Game.grid.tiles[ x ][ y ];
				}

				// continue if: less than three attempts
				// 				and tile isn't open for movement
				while( j++ < maxJumpDistance && ( destinationTile is null || !teamUnits[i].checkMove( destinationTile.toID() ) ) );
				
				// if we're not within
				if ( destinationTile !is null )
				{
					Game.turn.sendAction( Action( 0, teamUnits[i].ID, destinationTile.toID(), true ) );
					teamUnits[i].move( destinationTile.toID() );
				}

				Unit[] enemyUnits = Game.turn.getUnitsOnTeam( _enemyTeam );
				for( int k = 0; k < enemyUnits.length; k++ )
				{
					uint abilityID = teamUnits[ i ].abilities[ 1 ];
					if( enemyUnits[k] !is null && Game.abilities[ abilityID ].checkRange( enemyUnits[k].position, teamUnits[i].position ) )
					{
						uint originID = teamUnits[i].ID;
						if( teamUnits[i].useAbility( abilityID, enemyUnits[k].position ) )
							Game.turn.sendAction( Action( abilityID, originID, enemyUnits[k].position, true ) );
					}
				}
			}

			// End turn
			Game.turn.sendAction( Action( 9, 0, 0, true ) );
			Game.turn.switchActiveTeam();
		}
	}
}