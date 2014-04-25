module camera;
import game, grid;
import core, graphics, utility;
import std.algorithm;
import gl3n.linalg, gl3n.math, gl3n.interpolate;


class AdvancedCameraFields
{
	float MoveSpeed;
	uint RotateTime;
	float ZoomSpeed;
	float EdgeDistance;
	float MinHeight;
	float MaxHeight;
}

/// Camera movement around the scene
shared class AdvancedCamera : GameObjectInit!AdvancedCameraFields
{
	float moveSpeed;
	Duration rotateTime;
	float zoomSpeed;
	float edgeDistance;
	float minHeight;
	float maxHeight;
	float minX;
	float maxX;
	float minZ;
	float maxZ;
	bool clamped = false;

	override void onInitialize( AdvancedCameraFields a )
	{
		moveSpeed = a.MoveSpeed;
		rotateTime = a.RotateTime.msecs;
		zoomSpeed = a.ZoomSpeed;
		edgeDistance = a.EdgeDistance;
		minHeight = a.MinHeight;
		maxHeight = a.MaxHeight;

		transform.position.y = (( maxHeight - minHeight ) / 2) + minHeight;
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

		if( clamped )
			clampLookPos();

		if( Input.getState( "ZoomIn" ) )
		{
			transform.position += this.transform.forward * min( ( zoomSpeed * Time.deltaTime ), ( minHeight - transform.position.y ) / this.transform.forward.y );
		}
		else if( Input.getState( "ZoomOut" ) )
		{
			transform.position += -this.transform.forward * min( ( zoomSpeed * Time.deltaTime ), ( maxHeight - transform.position.y ) / -this.transform.forward.y );
		}

		if( Input.getState( "ResetCamera" ) )
		{
			transform.position = startPos;
			transform.rotation = startRot;
		}
	}

	void autoClamp()
	{
		minX = Game.grid.transform.position.x;
		minZ = Game.grid.transform.position.z;
		maxX = minX + ( Game.grid.gridX * TILE_SIZE );
		maxZ = minZ + ( Game.grid.gridY * TILE_SIZE );
		clamped = true;
	}

	shared(vec3) lookatPos()
	{
		return transform.position + ( transform.forward * ( -transform.position.y  / this.transform.forward.y ) );
	}

	void clampLookPos()
	{
		if( lookatPos.x < minX )
		{
			logDebug("Clamping at minX");
			transform.position.x += minX - lookatPos.x;
		}
		if( lookatPos.x > maxX )
		{
			logDebug("Clamping at maxX");
			transform.position.x -= lookatPos.x - maxX;
		}
		if( lookatPos.z < minZ )
		{
			logDebug("Clamping at minZ");
			transform.position.z += minZ - lookatPos.z;
		}
		if( lookatPos.z > maxZ )
		{
			logDebug("Clamping at maxZ");
			transform.position.z -= lookatPos.z - maxZ;
		}
	}

private:
	bool turning;

	vec3 startPos;
	quat startRot;
}
