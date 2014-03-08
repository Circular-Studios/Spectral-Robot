module game;
import Scripts.controller;

import core, components, utility;

class RobotGhosts : DGame
{
	Controller gc;

	override void onInitialize()
	{
		logInfo( "Initializing..." );
		
		Input.addKeyDownEvent( Keyboard.Escape, ( uint kc ) { currentState = GameState.Quit; } );
		Input.addKeyDownEvent( Keyboard.F5, ( uint kc ) { currentState = GameState.Reset; } );

		gc = new Controller();
	}
	
	override void onUpdate()
	{
		gc.gameObjects.apply( go => go.update() );
	}
	
	override void onDraw()
	{
		gc.gameObjects.apply( go => go.draw() );
	}
	
	override void onShutdown()
	{
		logInfo( "Shutting down..." );
		gc.gameObjects.apply( go => go.shutdown() );
		gc.gameObjects.clearObjects();
	}
	
	override void onSaveState()
	{
		logInfo( "Resetting..." );
	}
}
