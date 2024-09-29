package funkin.play.notes;

import funkin.play.notes.notestyle.NoteStyle;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxSprite;
import funkin.play.notes.NoteSprite;
import openfl.Vector;
import openfl.geom.Vector3D;
import funkin.play.modchart.ModchartMath;

/**
 * The actual receptor that you see on screen.
 */
class StrumlineNote extends flixel.addons.effects.FlxSkewedSprite
{
  public var isPlayer(default, null):Bool;

  public var direction(default, set):NoteDirection;

  var confirmHoldTimer:Float = -1;

  static final CONFIRM_HOLD_TIME:Float = 0.1;

  public var column:Int = 0;
  public var defaultScale:Array<Float>;
  public var offsetX:Float;
  public var offsetY:Float;
  public var z_index:Float;
  public var rotation:Vector3D = new Vector3D();

  function set_direction(value:NoteDirection):NoteDirection
  {
    this.direction = value;
    return this.direction;
  }

  public function new(noteStyle:NoteStyle, isPlayer:Bool, direction:NoteDirection)
  {
    super(0, 0);

    this.isPlayer = isPlayer;

    this.direction = direction;

    setup(noteStyle);

    this.animation.callback = onAnimationFrame;
    this.animation.finishCallback = onAnimationFinished;

    // Must be true for animations to play.
    this.active = true;
  }

  function onAnimationFrame(name:String, frameNumber:Int, frameIndex:Int):Void {}

  function onAnimationFinished(name:String):Void
  {
    // Run a timer before we stop playing the confirm animation.
    // On opponent, this prevent issues with hold notes.
    // On player, this allows holding the confirm key to fall back to press.
    if (name == 'confirm')
    {
      confirmHoldTimer = 0;
    }
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    centerOrigin();

    if (confirmHoldTimer >= 0)
    {
      confirmHoldTimer += elapsed;

      // Ensure the opponent stops holding the key after a certain amount of time.
      if (confirmHoldTimer >= CONFIRM_HOLD_TIME)
      {
        confirmHoldTimer = -1;
        playStatic();
      }
    }
  }

  function setup(noteStyle:NoteStyle):Void
  {
    noteStyle.applyStrumlineFrames(this);
    noteStyle.applyStrumlineAnimations(this, this.direction);

    this.setGraphicSize(Std.int(Strumline.STRUMLINE_SIZE * noteStyle.getStrumlineScale()));
    this.updateHitbox();
    defaultScale = [scale.x, scale.y];
    noteStyle.applyStrumlineOffsets(this);

    this.playStatic();
  }

  public function playAnimation(name:String = 'static', force:Bool = false, reversed:Bool = false, startFrame:Int = 0):Void
  {
    this.animation.play(name, force, reversed, startFrame);

    centerOffsets();
    centerOrigin();
  }

  public function playStatic():Void
  {
    this.active = false;
    this.playAnimation('static', true);
  }

  public function playPress():Void
  {
    this.active = true;
    this.playAnimation('press', true);
  }

  public function playConfirm():Void
  {
    this.active = true;
    this.playAnimation('confirm', true);
  }

  public function isConfirm():Bool
  {
    return getCurrentAnimation().startsWith('confirm');
  }

  public function holdConfirm():Void
  {
    this.active = true;

    if (getCurrentAnimation() == "confirm-hold")
    {
      return;
    }
    else if (getCurrentAnimation() == "confirm")
    {
      if (isAnimationFinished())
      {
        this.confirmHoldTimer = -1;
        this.playAnimation('confirm-hold', false, false);
      }
    }
    else
    {
      this.playAnimation('confirm', false, false);
    }
  }

  /**
   * Returns the name of the animation that is currently playing.
   * If no animation is playing (usually this means the sprite is BROKEN!),
   *   returns an empty string to prevent NPEs.
   */
  public function getCurrentAnimation():String
  {
    if (this.animation == null || this.animation.curAnim == null) return "";
    return this.animation.curAnim.name;
  }

  public function isAnimationFinished():Bool
  {
    return this.animation.finished;
  }

  public static final DEFAULT_OFFSET:Int = 13;

  /**
   * Adjusts the position of the sprite's graphic relative to the hitbox.
   */
  function fixOffsets():Void
  {
    // Automatically center the bounding box within the graphic.
    this.centerOffsets();

    if (getCurrentAnimation() == "confirm")
    {
      // Move the graphic down and to the right to compensate for
      // the "glow" effect on the strumline note.
      this.offset.x -= DEFAULT_OFFSET;
      this.offset.y -= DEFAULT_OFFSET;
    }
    else
    {
      this.centerOrigin();
    }
  }

  override function draw():Void
  {
    // from troll engine but much worse
    if (alpha == 0 || graphic == null || !exists || !visible) return;
    for (camera in cameras)
    {
      if (camera.exists && camera != null)
      {
        if (!camera.visible || camera.alpha == 0) continue;
        var wid:Float = frame.frame.width * scale.x;
        var h:Float = frame.frame.height * scale.y;
        var topLeft:Vector3D = new Vector3D(-wid / 2, -h / 2);
        var topRight:Vector3D = new Vector3D(wid / 2, -h / 2);
        var bottomLeft:Vector3D = new Vector3D(-wid / 2, h / 2);
        var bottomRight:Vector3D = new Vector3D(wid / 2, h / 2);

        /*var rotatedLT:Vector3D = ModchartMath.RotationXYZ(topLeft, new Vector3D(rotation.x, rotation.y, rotation.z));
          var rotatedRT:Vector3D = ModchartMath.RotationXYZ(topRight, new Vector3D(rotation.x, rotation.y, rotation.z));
          var rotatedLB:Vector3D = ModchartMath.RotationXYZ(bottomLeft, new Vector3D(rotation.x, rotation.y, rotation.z));
          var rotatedRB:Vector3D = ModchartMath.RotationXYZ(bottomRight, new Vector3D(rotation.x, rotation.y, rotation.z)); */
        var rotatedLT:Vector3D = ModchartMath.rotateVector3(topLeft, rotation.x, rotation.y, rotation.z);
        var rotatedRT:Vector3D = ModchartMath.rotateVector3(topRight, rotation.x, rotation.y, rotation.z);
        var rotatedLB:Vector3D = ModchartMath.rotateVector3(bottomLeft, rotation.x, rotation.y, rotation.z);
        var rotatedRB:Vector3D = ModchartMath.rotateVector3(bottomRight, rotation.x, rotation.y, rotation.z);
        rotatedLT = ModchartMath.PerspectiveProjection(rotatedLT.add(new Vector3D(x, y, rotation.w - 1000))).subtract(new Vector3D(x, y, rotation.w));
        rotatedRT = ModchartMath.PerspectiveProjection(rotatedRT.add(new Vector3D(x, y, rotation.w - 1000))).subtract(new Vector3D(x, y, rotation.w));
        rotatedLB = ModchartMath.PerspectiveProjection(rotatedLB.add(new Vector3D(x, y, rotation.w - 1000))).subtract(new Vector3D(x, y, rotation.w));
        rotatedRB = ModchartMath.PerspectiveProjection(rotatedRB.add(new Vector3D(x, y, rotation.w - 1000))).subtract(new Vector3D(x, y, rotation.w));
        var vertices:Vector<Float> = new Vector<Float>(8, false, [
          width / 2 + rotatedLT.x,
          height / 2 + rotatedLT.y,
          width / 2 + rotatedRT.x,
          height / 2 + rotatedRT.y,
          width / 2 + rotatedLB.x,
          height / 2 + rotatedLB.y,
          width / 2 + rotatedRB.x,
          height / 2 + rotatedRB.y
        ]);
        var uvtData:Vector<Float> = new Vector<Float>(8, false, [
          frame.uv.x,
          frame.uv.y,
          frame.uv.width,
          frame.uv.y,
          frame.uv.x,
          frame.uv.height,
          frame.uv.width,
          frame.uv.height
        ]);
        var indices:Vector<Int> = new Vector<Int>(6, true, [0, 1, 2, 1, 2, 3]);
        getScreenPosition(_point, camera);
        camera.drawTriangles(graphic, vertices, indices, uvtData, null, _point, blend, true, antialiasing, null, shader);
      }
    }
    #if FLX_DEBUG
    if (FlxG.debugger.drawDebug) drawDebug();
    #end
  }

  override public function destroy():Void
  {
    rotation = null;
    super.destroy();
  }
}
