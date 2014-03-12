module camera;
import core, utility;

/// Temporary class to move the camera around
class Camera : GameObject
{
	this()
	{
	}
	
	override void onUpdate()
	{
		if( Input.getState( "LookUp" ) )
		{
			this.transform.position.z -= 1;
			this.camera._viewMatrixIsDirty = true;
		}
		else if( Input.getState( "LookDown" ) )
		{
			this.transform.position.z += 1;
			this.camera._viewMatrixIsDirty = true;
		}
		
		if( Input.getState( "LookLeft" ) )
		{
			this.transform.position.x -= 1;
			this.camera._viewMatrixIsDirty = true;
		}
		else if( Input.getState( "LookRight" ) )
		{
			this.transform.position.x += 1;
			this.camera._viewMatrixIsDirty = true;
		}
		
	}
}
