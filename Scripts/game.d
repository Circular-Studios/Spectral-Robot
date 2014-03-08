module game;
import core, components, utility;

class RobotGhosts : DGame
{
	
	override void onInitialize()
	{
		logInfo( "Initializing..." );
		
		Input.addKeyDownEvent( Keyboard.Escape, ( uint kc ) { currentState = GameState.Quit; } );
		Input.addKeyDownEvent( Keyboard.F5, ( uint kc ) { currentState = GameState.Reset; } );
	}
	
	override void onUpdate()
	{
		//goc.apply( go => go.update() );
	}
	
	override void onDraw()
	{
		//goc.apply( go => go.draw() );
	}
	
	override void onShutdown()
	{
		logInfo( "Shutting down..." );
		//goc.apply( go => go.shutdown() );
		//goc.clearObjects();
	}
	
	override void onSaveState()
	{
		logInfo( "Resetting..." );
	}
}
