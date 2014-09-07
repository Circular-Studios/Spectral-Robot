module game;
import controller, grid, turn, action, ability, unit, camera, tile, aiManager;
import dash;
import speed;

// magical sprinkles
mixin( registerComponents!q{unit} );
mixin( registerComponents!q{grid} );
mixin( registerComponents!q{tile} );
mixin( registerComponents!q{camera} );
mixin ContentImport;

// An easier way to access the game instance
@property RobotGhosts Game()
{
	return cast(RobotGhosts)DGame.instance;
}

/// The base game class
class RobotGhosts : DGame
{
public:
	Controller gc; // the game controller
	Scene level; // The active scene in the engine
	Grid grid; // The grid in the level
	Turn turn; // The turn controller
	Ability[ uint ] abilities; // The abilities
	Unit[] units; // The units
	shared Connection serverConn; // the server connection
	UserInterface ui;
	bool enableAi;
	AiManager ai;

	// Name that game
	@property override string title()
	{
		return "Spectral Robot Task Force";
	}
	
	override void onInitialize()
	{
		logInfo( "Initializing ", title, "..." );
		
		// setup a couple helper keys
		Input.addButtonDownEvent( "QuitToDesktop", ( uint kc ) { currentState = EngineState.Quit; } );
		Input.addButtonDownEvent( "ResetGame", ( uint kc ) { currentState = EngineState.Reset; } );
		
		// initalize stuff
		level = new Scene();
		this.activeScene = level;
		auto g = new GameObject( new Grid );
		grid = g.getComponent!Grid;
		Game.level.addChild( g );
		turn = new Turn();
		gc = new Controller();
		
		// create a camera
		auto cam = level[ "Camera" ].getComponent!AdvancedCamera;
		cam.autoClamp();
		level.camera = cam.camera;
		
		// bind 'r' to server connect
		Input.addButtonDownEvent( "ConnectToServer", kc => connect() );
		
		// create the ui
		uint w, h;
		w = config.find!uint( "Display.Width" );
		h = config.find!uint( "Display.Height" );

		ui = new UserInterface( w, h, config.find!string( "UserInterface.FilePath" ) );

		ai = new AiManager();
	}
	
	/// Connect to the server
	void connect()
	{
		if( serverConn )
			serverConn.close();
		serverConn = Connection.open( config.find!string( "Game.ServerIP" ), false, ConnectionType.TCP );
		serverConn.onReceiveData!string ~= msg => logInfo( "Server Message: ", msg );
		serverConn.onReceiveData!uint ~= numPlayers => turn.setTeam( numPlayers );
		serverConn.onReceiveData!Action ~= action => turn.doAction( action );
		serverConn.send!string( "New connection.", ConnectionType.TCP );
	}
	
	override void onUpdate()
	{
		ui.update();
		try
		{
			if( serverConn )
				serverConn.update();
		}
		catch( Exception e )
		{
			logInfo( "Error: ", e.msg );
		}
	}
	
	override void onDraw()
	{
		ui.draw();
	}
	
	override void onShutdown()
	{
		logInfo( "Shutting down..." );
		if( serverConn )
			serverConn.close();
		level.destroy();
		grid.destroy();
		turn.destroy();
		units.destroy();
		abilities.destroy();
		gc.destroy();
		ui.shutdown();
	}
	
	override void onSaveState()
	{
		logInfo( "Resetting..." );
	}
}
