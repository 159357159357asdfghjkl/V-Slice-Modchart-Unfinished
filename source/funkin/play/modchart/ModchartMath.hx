package funkin.play.modchart;

import flixel.math.FlxMath;
import openfl.geom.Vector3D;
import funkin.play.notes.Strumline;
import flixel.math.FlxPoint;

class ModchartMath
{
  public static var ARROW_SIZE:Float = Strumline.NOTE_SPACING;
  public static var SCREEN_HEIGHT:Float = FlxG.height;

  public static var rad:Float = Math.PI / 180.0;
  public static var deg:Float = 180.0 / Math.PI;
  public static var ROWS_PER_BEAT:Int = 48;
  public static var BEATS_PER_MEASURE:Int = 4;

  public static var ROWS_PER_MEASURE:Int = ROWS_PER_BEAT * BEATS_PER_MEASURE;

  public static var MAX_NOTE_ROW:Int = 1 << 30;

  inline public static function scale(x:Float, l1:Float, h1:Float, l2:Float, h2:Float):Float
    return ((x - l1) * (h2 - l2) / (h1 - l1) + l2);

  inline public static function clamp(val:Float, low:Float, high:Float):Float
  {
    return Math.max((low), Math.min((val), (high)));
  }

  inline public static function iClamp(n:Int, l:Int, h:Int):Int
  {
    if (n > h) n = h;
    if (n < l) n = l;
    return n;
  }

  inline public static function mod(x:Float, y:Float):Float // should i use this?
    return x - Math.floor(x / y) * y;

  inline public static function BeatToNoteRow(beat:Float):Int
    return Math.round(beat * ROWS_PER_BEAT);

  inline public static function RowToNoteBeat(row:Int):Float
    return row / ROWS_PER_BEAT;

  public static inline function fastTan(x:Float):Float
    return FlxMath.fastSin(x) / FlxMath.fastCos(x);

  inline public static function fastCsc(x:Float):Float
    return 1 / FlxMath.fastSin(x);

  inline public static function square(angle:Float)
  {
    var fAngle:Float = angle % (Math.PI * 2);
    // Hack: This ensures the hold notes don't flicker right before they're hit.
    if (fAngle < 0.01)
    {
      fAngle += Math.PI * 2;
    }
    return fAngle >= Math.PI ? -1.0 : 1.0;
  }

  public static function triangle(angle:Float)
  {
    var fAngle:Float = angle % (Math.PI * 2.0);
    if (fAngle < 0.0)
    {
      fAngle += Math.PI * 2.0;
    }
    var result = fAngle * (1 / Math.PI);
    if (result < .5)
    {
      return result * 2.0;
    }
    else if (result < 1.5)
    {
      return 1.0 - ((result - .5) * 2.0);
    }
    else
    {
      return -4.0 + (result * 2.0);
    }
  }

  public static function PerspectiveProjection(x:Float, y:Float, z:Float):Vector3D
  {
    var origin:Vector3D = new Vector3D(FlxG.width / 2, FlxG.height / 2);
    var zNear:Float = 0;
    var zFar:Float = 100;
    var zRange:Float = zNear - zFar;
    var FOV:Float = 90.0;
    var tanHalfFOV:Float = Math.tan(rad * (FOV / 2));
    var pos:Vector3D = new Vector3D(x, y, z / 1000).subtract(origin);
    if (pos.z > 0) pos.z = 0;
    var a:Float = (-zNear - zFar) / zRange;
    var b:Float = 2.0 * zFar * zNear / zRange;
    var newZPos:Float = a * -pos.z + b;
    var newXPos:Float = pos.x / (1 / tanHalfFOV) / newZPos;
    var newYPos:Float = pos.y / (1 / tanHalfFOV) / newZPos;
    var vector:Vector3D = new Vector3D(newXPos, newYPos, 1 / newZPos).add(origin);
    return vector;
  }

  inline public static function Quantize(f:Float, fRoundInterval:Float):Float
  {
    return Std.int((f + fRoundInterval / 2) / fRoundInterval) * fRoundInterval;
  }

  public static function rotate3D(axis:Vector3D, angle:Vector3D):Vector3D
  {
    var cosx:Float = Math.cos(angle.x);
    var sinx:Float = Math.sin(angle.x);
    var cosy:Float = Math.cos(angle.y);
    var siny:Float = Math.sin(angle.y);
    var cosz:Float = Math.cos(angle.z);
    var sinz:Float = Math.sin(angle.z);
    var coszcosx:Float = cosz * cosx;
    var sinzcosx:Float = sinz * cosx;
    var coszsinx:Float = sinx * cosz;
    var sinzsinx:Float = sinx * sinz;
    return new Vector3D(axis.x * (cosz * cosy)
      + axis.y * (sinzcosx + coszsinx * siny)
      + axis.z * (sinzsinx - coszcosx * siny),
      axis.x * (-cosy * sinz)
      + axis.y * (coszcosx - sinzsinx * siny)
      + axis.z * (coszsinx + sinzcosx * siny),
      axis.x * siny
      + axis.y * (-sinx * cosy)
      + axis.z * (cosy * cosx));
  }

  public static function RotationXYZ(rotation:Vector3D):Vector3D
  {
    var rX:Float = rotation.x;
    var rY:Float = rotation.y;
    var rZ:Float = rotation.z;
    rX *= Math.PI / 180;
    rY *= Math.PI / 180;
    rZ *= Math.PI / 180;

    var cX:Float = FlxMath.fastCos(rX);
    var sX:Float = FlxMath.fastSin(rX);
    var cY:Float = FlxMath.fastCos(rY);
    var sY:Float = FlxMath.fastSin(rY);
    var cZ:Float = FlxMath.fastCos(rZ);
    var sZ:Float = FlxMath.fastSin(rZ);

    return new Vector3D((cZ * cY)
      + (cZ * sY * sX + sZ * cX)
      + (cZ * sY * cX + sZ * (-sX)),
      ((-sZ) * cY)
      + ((-sZ) * sY * sX + cZ * cX)
      + ((-sZ) * sY * cX + cZ * (-sX)),
      -sY
      + (cY * sX)
      + (cY * cX));
  }
}
