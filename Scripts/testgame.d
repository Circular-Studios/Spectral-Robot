module testgame;
import core.dgame, core.gameobjectcollection;
import components;
import utility.output, utility.input;

import std.conv;

@Game!TestGame class TestGame : DGame
{
	GameObjectCollection goc;
	int[][] grid;
	int curX = 0;
	int curY = 0;
	
	override void onInitialize()
	{
		Output.printMessage( OutputType.Info, "Initializing..." );

		Input.addKeyDownEvent( Keyboard.Escape, ( uint kc ) { currentState = GameState.Quit; } );
		Input.addKeyDownEvent( Keyboard.F5, ( uint kc ) { currentState = GameState.Reset; } );

		goc = new GameObjectCollection;
		goc.loadObjects( "" );
	}
	
	override void onUpdate()
	{
		goc.apply( go => go.update() );

		//demo grid movement
		if ( Input.getState!bool( "Up" ) )
		{
			goc["Tile" ~ curX.to!string ~ "-" ~ curY.to!string].material = Assets.get!Material( "poopmat" );
			if (curY < 2)
				curY++;
			goc["Tile" ~ curX.to!string ~ "-" ~ curY.to!string].material = Assets.get!Material( "poopmat_gray" );
		}

		if ( Input.getState!bool( "Down" ) )
		{
			goc["Tile" ~ curX.to!string ~ "-" ~ curY.to!string].material = Assets.get!Material( "poopmat" );
			if (curY > 0)
				curY--;
			goc["Tile" ~ curX.to!string ~ "-" ~ curY.to!string].material = Assets.get!Material( "poopmat_gray" );
		}

		if ( Input.getState!bool( "Left" ) )
		{
			goc["Tile" ~ curX.to!string ~ "-" ~ curY.to!string].material = Assets.get!Material( "poopmat" );
			if (curX > 0)
				curX--;
			goc["Tile" ~ curX.to!string ~ "-" ~ curY.to!string].material = Assets.get!Material( "poopmat_gray" );
		}

		if ( Input.getState!bool( "Right" ) )
		{
			goc["Tile" ~ curX.to!string ~ "-" ~ curY.to!string].material = Assets.get!Material( "poopmat" );
			if (curX < 2)
				curX++;
			goc["Tile" ~ curX.to!string ~ "-" ~ curY.to!string].material = Assets.get!Material( "poopmat_gray" );
		}
	}
	
	override void onDraw()
	{
		goc.apply( go => go.draw() );
	}

	override void onShutdown()
	{
		Output.printMessage( OutputType.Info, "Shutting down..." );
		goc.apply( go => go.shutdown() );
		goc.clearObjects();
	}

	override void onSaveState()
	{
		Output.printMessage( OutputType.Info, "Resetting..." );
	}
}
