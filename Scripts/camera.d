module camera;
import core, utility;

/// Temporary class to move the camera around
shared class Camera : GameObject
{
	this()
	{
	}
	
	override void onUpdate()
	{
		if( Input.getState( "LookUp" ) )
		{
			this.transform.position.z -= 1;
		}
		else if( Input.getState( "LookDown" ) )
		{
			this.transform.position.z += 1;
		}
		
		if( Input.getState( "LookLeft" ) )
		{
			this.transform.position.x -= 1;
		}
		else if( Input.getState( "LookRight" ) )
		{
			this.transform.position.x += 1;
		}
	}
}
