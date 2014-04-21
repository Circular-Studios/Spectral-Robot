module camera;
import core, graphics, utility;
import std.algorithm;
import gl3n.linalg, gl3n.math, gl3n.interpolate;

/// Camera movement around the scene
shared class AdvancedCamera : GameObject
{
	float moveSpeed = 150;
	Duration rotateTime = 400.msecs;
	float edgeDistance = 50;
	float minHeight = 50;
	float maxHeight = 200;

	override void initialize( Object o)
	{
		startPos = transform.position;
		startRot = transform.rotation;
	}
	
	override void onUpdate()
	{	
		if( Input.getState("LookLeft") && !turning )
		{
			turning = true;
			auto startTime = Time.totalTime;

			auto prevFace = transform.forward;
			prevFace *= -transform.position.y / prevFace.y;

			auto lookPos = transform.position + prevFace;
			auto nextFace = prevFace * quat.identity.rotatey( -90.radians );
			auto prevRot = transform.rotation;
			auto nextRot = prevRot.rotatey( -90.radians );
			prevRot = transform.rotation;
			
			scheduleTimedTask( rotateTime, 
			{
				auto curFaceXZ = slerp( prevFace.xz, nextFace.xz, 
				       	min( ( Time.totalTime - startTime ) / rotateTime.toSeconds , 1.0f ) );

				auto curFace = shared vec3( curFaceXZ.x, prevFace.y, curFaceXZ.y );
				transform.position = lookPos - curFace;

				transform.rotation = slerp( prevRot, nextRot, min( ( Time.totalTime - startTime ) / rotateTime.toSeconds , 1.0f ) );
				if( Time.totalTime - startTime >= rotateTime.toSeconds ) turning = false;
			} );
		}
		if( Input.getState("LookRight") && !turning )
		{
						turning = true;
			auto startTime = Time.totalTime;

			auto prevFace = transform.forward;
			prevFace *= -transform.position.y / prevFace.y;
			
			auto lookPos = transform.position + prevFace;
			auto nextFace = prevFace * quat.identity.rotatey( 90.radians );
			auto prevRot = transform.rotation;
			auto nextRot = prevRot.rotatey( 90.radians );
			prevRot = transform.rotation;
			scheduleTimedTask( rotateTime, 
			{
				auto curFaceXZ = slerp( prevFace.xz, nextFace.xz, 
				       	min( ( Time.totalTime - startTime ) / rotateTime.toSeconds , 1.0f ) );

				auto curFace = shared vec3( curFaceXZ.x, prevFace.y, curFaceXZ.y );
				transform.position = lookPos - curFace;

				transform.rotation = slerp( prevRot, nextRot, min( ( Time.totalTime - startTime ) / rotateTime.toSeconds , 1.0f ) );
				if( Time.totalTime - startTime >= rotateTime.toSeconds ) turning = false;
			} );
		}

		shared vec2 mouse = Input.mousePos;
		// Left of the screen
		if( mouse.x < edgeDistance )
		{
			auto moveVec = -this.transform.right;
			moveVec.y = 0;
			moveVec.normalize();
			moveVec *= moveSpeed * Time.deltaTime;
			this.transform.position += moveVec;
		} // Bottom of the screen
		if( mouse.y < edgeDistance )
		{
			auto moveVec = -this.transform.forward;
			moveVec.y = 0;
			moveVec.normalize();
			moveVec *= moveSpeed * Time.deltaTime;
			this.transform.position += moveVec;
		} // Right
		if( mouse.x > Graphics.width - edgeDistance )
		{
			auto moveVec = this.transform.right;
			moveVec.y = 0;
			moveVec.normalize();
			moveVec *= moveSpeed * Time.deltaTime;
			this.transform.position += moveVec;
		} // Top
		if( mouse.y > Graphics.height - edgeDistance )
		{
			auto moveVec = this.transform.forward;
			moveVec.y = 0;
			moveVec.normalize();
			moveVec *= moveSpeed * Time.deltaTime;
			this.transform.position += moveVec;
		}

	}

private:
	bool turning;

	vec3 startPos;
	quat startRot;
}
