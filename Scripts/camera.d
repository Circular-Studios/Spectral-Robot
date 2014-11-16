module camera;
import game, grid, tile;
import dash;
import std.algorithm;
import gl3n.linalg, gl3n.math, gl3n.interpolate;

/// Camera movement around the scene
class AdvancedCamera : Component
{
public:
  alias owner this;
  @rename( "MoveSpeed" )
  float moveSpeed;
  @rename( "RotateTime" )
  uint rotateTimeMsecs;
  @ignore
  Duration rotateTime;
  @rename( "ZoomSpeed" )
  float zoomSpeed;
  @rename( "EdgeDistance" )
  float edgeDistance;
  @rename( "MinHeight" )
  float minHeight;
  @rename( "MaxHeight" )
  float maxHeight;
  @ignore
  {
    float minX;
    float maxX;
    float minZ;
    float maxZ;
    bool clamped = false;
  }
  @rename( "RotateDegrees" )
  float rotateDegrees;
  @rename( "MouseEdgeScroll" )
  bool mouseEdgeScroll;

  override void initialize()
  {
    rotateTime = rotateTimeMsecs.msecs;
    transform.position.y = ( ( maxHeight - minHeight ) / 2 ) + minHeight;
    startPos = transform.position;
    startRot = transform.rotation;

    auto obj = this;
    Input.addAxisEvent( "Zoom", ( newVal )
    {
      static float prev = 0.0f;
      if( newVal > prev )
      {
        obj.transform.position += obj.transform.forward * min( ( zoomSpeed * Time.deltaTime ), ( minHeight - obj.transform.position.y ) / obj.transform.forward.y );
      }
      else if( newVal < prev )
      {
        obj.transform.position += -obj.transform.forward * min( ( zoomSpeed * Time.deltaTime ), ( maxHeight - obj.transform.position.y ) / -obj.transform.forward.y );
      }

      prev = newVal;
    } );
  }

  override void update()
  {
    if( Input.getState( "LookLeft" ) && !turning )
    {
      turning = true;
      auto startTime = Time.totalTime;

      auto prevFace = transform.forward;
      prevFace *= -transform.position.y / prevFace.y;

      auto lookPos = transform.position + prevFace;
      auto nextFace = prevFace * quat.identity.rotatey( -rotateDegrees.radians );
      auto prevRot = transform.rotation;
      auto nextRot = prevRot.rotatey( -rotateDegrees.radians );
      prevRot = transform.rotation;

      scheduleTimedTask( rotateTime,
      {
        auto curFaceXZ = slerp( prevFace.xz, nextFace.xz,
                 min( ( Time.totalTime - startTime ) / rotateTime.toSeconds , 1.0f ) );

        auto curFace = vec3( curFaceXZ.x, prevFace.y, curFaceXZ.y );
        owner.transform.position = lookPos - curFace;

        owner.transform.rotation = slerp( prevRot, nextRot, min( ( Time.totalTime - startTime ) / rotateTime.toSeconds , 1.0f ) );
        if( Time.totalTime - startTime >= rotateTime.toSeconds ) turning = false;
      } );
    }
    if( Input.getState( "LookRight" ) && !turning )
    {
      turning = true;
      auto startTime = Time.totalTime;

      auto prevFace = transform.forward;
      prevFace *= -transform.position.y / prevFace.y;

      auto lookPos = transform.position + prevFace;
      auto nextFace = prevFace * quat.identity.rotatey( rotateDegrees.radians );
      auto prevRot = transform.rotation;
      auto nextRot = prevRot.rotatey( rotateDegrees.radians );
      prevRot = transform.rotation;
      scheduleTimedTask( rotateTime,
      {
        auto curFaceXZ = slerp( prevFace.xz, nextFace.xz,
                 min( ( Time.totalTime - startTime ) / rotateTime.toSeconds , 1.0f ) );

        auto curFace = vec3( curFaceXZ.x, prevFace.y, curFaceXZ.y );
        owner.transform.position = lookPos - curFace;

        owner.transform.rotation = slerp( prevRot, nextRot, min( ( Time.totalTime - startTime ) / rotateTime.toSeconds , 1.0f ) );
        if( Time.totalTime - startTime >= rotateTime.toSeconds ) turning = false;
      } );
    }

    // Mouse & Keyboard movement
    vec2 mouse = Input.mousePos;
    // Left
    if( ( mouseEdgeScroll && mouse.x < edgeDistance ) || Input.getState( "Left" ) )
    {
      auto moveVec = -transform.right;
      moveVec.y = 0;
      moveVec.normalize();
      moveVec *= moveSpeed * Time.deltaTime;
      transform.position += moveVec;
    }
    // Bottom
    if( ( mouseEdgeScroll && mouse.y < edgeDistance ) || Input.getState( "Down" ) )
    {
      auto moveVec = -transform.forward;
      moveVec.y = 0;
      moveVec.normalize();
      moveVec *= moveSpeed * Time.deltaTime;
      transform.position += moveVec;
    }
    // Right
    if( ( mouseEdgeScroll && mouse.x > Graphics.width - edgeDistance ) || Input.getState( "Right" ) )
    {
      auto moveVec = transform.right;
      moveVec.y = 0;
      moveVec.normalize();
      moveVec *= moveSpeed * Time.deltaTime;
      transform.position += moveVec;
    }
    // Top
    if( ( mouseEdgeScroll && mouse.y > Graphics.height - edgeDistance ) || Input.getState( "Up" ) )
    {
      auto moveVec = transform.forward;
      moveVec.y = 0;
      moveVec.normalize();
      moveVec *= moveSpeed * Time.deltaTime;
      transform.position += moveVec;
    }

    if( clamped )
      clampLookPos();

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

  vec3 lookatPos()
  {
    return transform.position + ( transform.forward * ( -transform.position.y  / transform.forward.y ) );
  }

  void clampLookPos()
  {
    if( lookatPos.x < minX )
    {
      trace( "Clamping at minX" );
      transform.position.x += minX - lookatPos.x;
    }
    if( lookatPos.x > maxX )
    {
      trace( "Clamping at maxX" );
      transform.position.x -= lookatPos.x - maxX;
    }
    if( lookatPos.z < minZ )
    {
      trace( "Clamping at minZ" );
      transform.position.z += minZ - lookatPos.z;
    }
    if( lookatPos.z > maxZ )
    {
      trace( "Clamping at maxZ" );
      transform.position.z -= lookatPos.z - maxZ;
    }
  }

private:
  bool turning;
  vec3 startPos;
  quat startRot;
}
