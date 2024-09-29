package funkin.play.notes;

import funkin.data.song.SongData.SongNoteData;
import funkin.play.notes.notestyle.NoteStyle;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxSprite;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.HSVShader;
import flixel.math.FlxPoint;
import openfl.geom.Matrix;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.math.FlxAngle;
import flixel.util.FlxDestroyUtil;
import openfl.Vector;
import openfl.geom.Vector3D;
import funkin.play.modchart.ModchartMath;

class NoteSprite extends FunkinSprite
{
  static final DIRECTION_COLORS:Array<String> = ['purple', 'blue', 'green', 'red'];

  public var rotation:Vector3D = new Vector3D();
  public var holdNoteSprite:SustainTrail;
  public var column:Int = 0;
  public var defaultScale:Array<Float>;
  public var offsetX:Float = 0;
  public var offsetY:Float = 0;
  public var z_index:Float;

  var hsvShader:HSVShader;

  /**
   * The strum time at which the note should be hit, in milliseconds.
   */
  public var strumTime(get, set):Float;

  function get_strumTime():Float
  {
    return this.noteData?.time ?? 0.0;
  }

  function set_strumTime(value:Float):Float
  {
    if (this.noteData == null) return value;
    return this.noteData.time = value;
  }

  /**
   * The length for which the note should be held, in milliseconds.
   * Defaults to 0 for single notes.
   */
  public var length(get, set):Float;

  function get_length():Float
  {
    return this.noteData?.length ?? 0.0;
  }

  function set_length(value:Float):Float
  {
    if (this.noteData == null) return value;
    return this.noteData.length = value;
  }

  /**
   * An extra attribute for the note.
   * For example, whether the note is an "alt" note, or whether it has custom behavior on hit.
   */
  public var kind(get, set):Null<String>;

  function get_kind():Null<String>
  {
    return this.noteData?.kind;
  }

  function set_kind(value:String):String
  {
    if (this.noteData == null) return value;
    return this.noteData.kind = value;
  }

  /**
   * The data of the note (i.e. the direction.)
   */
  public var direction(default, set):NoteDirection;

  function set_direction(value:Int):Int
  {
    if (frames == null) return value;

    animation.play(DIRECTION_COLORS[value] + 'Scroll');

    this.direction = value;
    return this.direction;
  }

  public var noteData:SongNoteData;

  public var isHoldNote(get, never):Bool;

  function get_isHoldNote():Bool
  {
    return noteData.length > 0;
  }

  /**
   * Set this flag to true when hitting the note to avoid scoring it multiple times.
   */
  public var hasBeenHit:Bool = false;

  /**
   * Register this note as hit only after any other notes
   */
  public var lowPriority:Bool = false;

  /**
   * This is true if the note is later than 10 frames within the strumline,
   * and thus can't be hit by the player.
   * It will be destroyed after it moves offscreen.
   * Managed by PlayState.
   */
  public var hasMissed:Bool;

  /**
   * This is true if the note is earlier than 10 frames within the strumline.
   * and thus can't be hit by the player.
   * Managed by PlayState.
   */
  public var tooEarly:Bool;

  /**
   * This is true if the note is within 10 frames of the strumline,
   * and thus may be hit by the player.
   * Managed by PlayState.
   */
  public var mayHit:Bool;

  /**
   * This is true if the PlayState has performed the logic for missing this note.
   * Subtracting score, subtracting health, etc.
   */
  public var handledMiss:Bool;

  public function new(noteStyle:NoteStyle, direction:Int = 0)
  {
    super(0, -9999);
    this.direction = direction;

    this.hsvShader = new HSVShader();

    setupNoteGraphic(noteStyle);

    // Disables the update() function for performance.
    this.active = false;
  }

  function setupNoteGraphic(noteStyle:NoteStyle):Void
  {
    noteStyle.buildNoteSprite(this);

    setGraphicSize(Strumline.STRUMLINE_SIZE);
    updateHitbox();
    defaultScale = [scale.x, scale.y];
    this.shader = hsvShader;
  }

  #if FLX_DEBUG
  /**
   * Call this to override how debug bounding boxes are drawn for this sprite.
   */
  public override function drawDebugOnCamera(camera:flixel.FlxCamera):Void
  {
    if (!camera.visible || !camera.exists || !isOnScreen(camera)) return;

    var gfx = beginDrawDebug(camera);

    var rect = getBoundingBox(camera);
    trace('note sprite bounding box: ' + rect.x + ', ' + rect.y + ', ' + rect.width + ', ' + rect.height);

    gfx.lineStyle(2, 0xFFFF66FF, 0.5); // thickness, color, alpha
    gfx.drawRect(rect.x, rect.y, rect.width, rect.height);

    gfx.lineStyle(2, 0xFFFFFF66, 0.5); // thickness, color, alpha
    gfx.drawRect(rect.x, rect.y + rect.height / 2, rect.width, 1);

    endDrawDebug(camera);
  }
  #end

  public function desaturate():Void
  {
    this.hsvShader.saturation = 0.2;
  }

  public function setHue(hue:Float):Void
  {
    this.hsvShader.hue = hue;
  }

  public override function revive():Void
  {
    super.revive();
    this.visible = true;
    this.alpha = 1.0;
    this.active = false;
    this.tooEarly = false;
    this.hasBeenHit = false;
    this.mayHit = false;
    this.hasMissed = false;

    this.hsvShader.hue = 1.0;
    this.hsvShader.saturation = 1.0;
    this.hsvShader.value = 1.0;
  }

  public override function kill():Void
  {
    super.kill();
  }

  public var skew(default, null):FlxPoint = FlxPoint.get();

  /**
   * Tranformation matrix for this sprite.
   * Used only when matrixExposed is set to true
   */
  public var transformMatrix(default, null):Matrix = new Matrix();

  /**
   * Bool flag showing whether transformMatrix is used for rendering or not.
   * False by default, which means that transformMatrix isn't used for rendering
   */
  public var matrixExposed:Bool = false;

  /**
   * Internal helper matrix object. Used for rendering calculations when matrixExposed is set to false
   */
  var _skewMatrix:Matrix = new Matrix();

  /**
   * WARNING: This will remove this sprite entirely. Use kill() if you
   * want to disable it temporarily only and reset() it later to revive it.
   * Used to clean up memory.
   */
  override public function destroy():Void
  {
    skew = FlxDestroyUtil.put(skew);
    _skewMatrix = null;
    transformMatrix = null;
    // This function should ONLY get called as you leave PlayState entirely.
    // Otherwise, we want the game to keep reusing note sprites to save memory.
    super.destroy();
  }

  override function drawComplex(camera:FlxCamera):Void
  {
    _frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
    _matrix.translate(-origin.x, -origin.y);
    _matrix.scale(scale.x, scale.y);

    if (matrixExposed)
    {
      _matrix.concat(transformMatrix);
    }
    else
    {
      if (bakedRotationAngle <= 0)
      {
        updateTrig();

        if (angle != 0) _matrix.rotateWithTrig(_cosAngle, _sinAngle);
      }

      updateSkewMatrix();
      _matrix.concat(_skewMatrix);
    }

    getScreenPosition(_point, camera).subtractPoint(offset);
    _point.addPoint(origin);
    if (isPixelPerfectRender(camera)) _point.floor();

    _matrix.translate(_point.x, _point.y);
    camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
  }

  function updateSkewMatrix():Void
  {
    _skewMatrix.identity();

    if (skew.x != 0 || skew.y != 0)
    {
      _skewMatrix.b = Math.tan(skew.y * FlxAngle.TO_RAD);
      _skewMatrix.c = Math.tan(skew.x * FlxAngle.TO_RAD);
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

  override public function isSimpleRender(?camera:FlxCamera):Bool
  {
    if (FlxG.renderBlit)
    {
      return super.isSimpleRender(camera) && (skew.x == 0) && (skew.y == 0) && !matrixExposed;
    }
    else
    {
      return false;
    }
  }
}
