package funkin.play.modchart;

import flixel.math.FlxMath;
import openfl.geom.Vector3D;
import funkin.play.notes.Strumline;

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

  inline public static function fmodf(x:Float, y:Float):Float // should i use this?
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

  // shortcut some steps
  public static function UpdatePerspective(x:Float, y:Float, z:Float):Vector3D
  {
    var tanHalfFOV:Float = Math.tan(rad * 45);
    var pos:Vector3D = new Vector3D(x - FlxG.width / 2, y - FlxG.height / 2, z / 1000 - 1);
    if (pos.z > 0) pos.z = 0;
    var newXPos:Float = pos.x * (1 / tanHalfFOV) / -pos.z + FlxG.width / 2;
    var newYPos:Float = pos.y / (1 / tanHalfFOV) / -pos.z + FlxG.height / 2;
    var zScale:Float = 1 / -pos.z;
    return new Vector3D(newXPos, newYPos, zScale);
  }

  public static function CalculateDrunkAngle(time:Float, speed:Float, col:Int, offset:Float, col_frequency:Float, y_offset:Float, period:Float,
      offset_frequency:Float):Float
  {
    return time * (1 + speed) + col * ((offset * col_frequency) + col_frequency) + y_offset * ((period * offset_frequency) + offset_frequency) / SCREEN_HEIGHT;
  }

  public static function CalculateBumpyAngle(y_offset:Float, offset:Float, period:Float):Float
  {
    return (y_offset + (100.0 * offset)) / ((period * 16.0) + 16.0);
  }

  public static function CalculateDigitalAngle(y_offset:Float, offset:Float, period:Float):Float
  {
    return Math.PI * (y_offset + (1.0 * offset)) / (ARROW_SIZE + (period * ARROW_SIZE));
  }

  inline public static function Quantize(f:Float, fRoundInterval:Float):Float
  {
    return Std.int((f + fRoundInterval / 2) / fRoundInterval) * fRoundInterval;
  }

  public static function RotationXYZ(rX:Float, rY:Float, rZ:Float):Vector3D
  {
    rX = rX * (Math.PI / 180);
    rY = rY * (Math.PI / 180);
    rZ = rZ * (Math.PI / 180);
    var cX:Float = Math.cos(rX);
    var sX:Float = Math.sin(rX);
    var cY:Float = Math.cos(rY);
    var sY:Float = Math.sin(rY);
    var cZ:Float = Math.cos(rZ);
    var sZ:Float = Math.sin(rZ);
    return new Vector3D(cZ * cY
      + (cZ * sY * sX + sZ * cX)
      + (cZ * sY * cX + sZ * (-sX)),
      (-sZ) * cY
      + ((-sZ) * sY * sX + cZ * cX)
      + ((-sZ) * sY * cX + cZ * (-sX)),
      -sY
      + cY * sX
      + cY * cX);
  }
}
