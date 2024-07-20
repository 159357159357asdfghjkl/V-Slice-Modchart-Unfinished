package funkin.play.modchart;

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.math.FlxAngle;
import openfl.geom.Vector3D;

/**
 * Read Me:
 * I'm new to haxe so the code is weird,
 * it is in a mess,
 * don't expect it too much!
 * --but who can optimize it or rewrite this shit
 *
 */
class Modchart
{
  public var modList:Map<String, Float> = new Map<String, Float>();

  public var altname:Map<String, String> = new Map<String, String>();

  public static var ROWS_PER_BEAT:Int = 48;
  public static var BEATS_PER_MEASURE:Int = 4;
  // its 48 in ITG but idk because FNF doesnt work w/ note rows
  public static var ROWS_PER_MEASURE:Int = ROWS_PER_BEAT * BEATS_PER_MEASURE;

  public static var MAX_NOTE_ROW:Int = 1 << 30; // from Stepmania

  final ARROW_SIZE = 112;
  final STEPMANIA_ARROW_SIZE = 64;
  final SCREEN_HEIGHT = FlxG.height;

  inline function scale(x:Float, l1:Float, h1:Float, l2:Float, h2:Float):Float
    return ((x - l1) * (h2 - l2) / (h1 - l1) + l2);

  inline function clamp(val:Float, low:Float, high:Float):Float
  {
    return Math.max((low), Math.min((val), (high)));
  }

  inline function BeatToNoteRow(beat:Float):Int
    return Math.round(beat * ROWS_PER_BEAT);

  inline function RowToNoteBeat(row:Int):Float
    return row / ROWS_PER_BEAT;

  public inline function fastTan(x:Float):Float
    return FlxMath.fastSin(x) / FlxMath.fastCos(x);

  inline function fastCsc(x:Float):Float
    return 1 / FlxMath.fastSin(x);

  inline function square(angle:Float)
  {
    var fAngle:Float = angle % (Math.PI * 2);
    // Hack: This ensures the hold notes don't flicker right before they're hit.
    if (fAngle < 0.01)
    {
      fAngle += Math.PI * 2;
    }
    return fAngle >= Math.PI ? -1.0 : 1.0;
  }

  function triangle(angle:Float)
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

  public static function toRadian(x:Float):Float
    return x * Math.PI / 180.0;

  public static function toDegree(x:Float):Float
    return x * 180.0 / Math.PI;

  // https://ogldev.org/www/tutorial12/tutorial12.html
  public static function UpdatePerspective(x:Float, y:Float, z:Float):Vector3D
  {
    /*static var zNear:Float = 0;
        static var zFar:Float = 100;
        static var FOV:Float = 90.0;
        var z1:Float = z / 30000 - 1;
        var ar:Float = FlxG.width / FlxG.height;
        var zRange:Float = zNear - zFar;
        var tanHalfFOV:Float = Math.tan(toRadian(FOV / 2.0));
        var zPosition:Float = ((-zNear - zFar) / zRange) * z1 + (2.0 * zFar * zNear / zRange);
        return new Vector3D((x * (1.0 / (tanHalfFOV * ar))) / -zPosition, (y / (1.0 / tanHalfFOV)) / -zPosition, -zPosition);
      return new Vector3D(x, y, z); */
    var zNear:Float = 0;
    var zFar:Float = 100;
    var zRange:Float = zNear - zFar;
    var tanHalfFOV:Float = Math.tan(Math.PI / 4);
    var zpos:Float = z;
    zpos -= 1;
    var zPerspectiveOffset:Float = (zpos + (2 * zFar * zNear / zRange));
    var xPerspective:Float = x * (1 / tanHalfFOV);
    var yPerspective:Float = y / (1 / tanHalfFOV);
    xPerspective /= -zPerspectiveOffset;
    yPerspective /= -zPerspectiveOffset;
    return new Vector3D(xPerspective + (FlxG.width / 2), yPerspective + (FlxG.height / 2), -zPerspectiveOffset);
  }

  function selectTanType(angle:Float, is_cosec:Float)
  {
    if (is_cosec != 0) return fastCsc(angle);
    else
      return fastTan(angle);
  }

  var dim_x:Int = 0;
  var dim_y:Int = 1;
  var dim_z:Int = 2;
  var expandSeconds:Float = 0;
  var tanExpandSeconds:Float = 0;

  public function CalculateNoteYPos(conductor:Conductor, strumTime:Float, vwoosh:Bool = true, scrollSpeed:Float):Float
  {
    var vwoosh:Float = 1.0;
    return
      Constants.PIXELS_PER_MS * (conductor.songPosition - strumTime - Conductor.instance.inputOffset) * scrollSpeed * vwoosh * (Preferences.downscroll ? 1 : -1);
  }

  function CalculateDrunkAngle(time:Float, speed:Float, col:Int, offset:Float, col_frequency:Float, y_offset:Float, period:Float, offset_frequency:Float):Float
  {
    return time * (1 + speed) + col * ((offset * col_frequency) + col_frequency) + y_offset * ((period * offset_frequency) + offset_frequency) / SCREEN_HEIGHT;
  }

  function CalculateBumpyAngle(y_offset:Float, offset:Float, period:Float):Float
  {
    return (y_offset + (100.0 * offset)) / ((period * 16.0) + 16.0);
  }

  function CalculateDigitalAngle(y_offset:Float, offset:Float, period:Float):Float
  {
    return Math.PI * (y_offset + (1.0 * offset)) / (ARROW_SIZE + (period * ARROW_SIZE));
  }

  inline function Quantize(f:Float, fRoundInterval:Float):Float
  {
    return Std.int((f + fRoundInterval / 2) / fRoundInterval) * fRoundInterval;
  }

  public function initMods()
  {
    var mods:Array<String> = [
      'boost', 'brake', 'wave', 'waveperiod', 'parabolay', 'boomerang', 'expand', 'expandperiod', 'drunk', 'drunkspeed', 'drunkoffset', 'drunkperiod',
      'tandrunk', 'tandrunkspeed', 'tandrunkoffset', 'tandrunkperiod', 'drunkz', 'drunkzspeed', 'drunkzoffset', 'drunkzperiod', 'tandrunkz', 'tandrunkzspeed',
      'tandrunkzoffset', 'tandrunkzperiod', 'tanexpand', 'tanexpandperiod', 'tipsy', 'tipsyspeed', 'tipsyoffset', 'tantipsy', 'tantipsyspeed',
      'tantipsyoffset', 'tornado', 'tornadooffset', 'tornadoperiod', 'tantornado', 'tantornadooffset', 'tantornadoperiod', 'tornadoz', 'tornadozoffset',
      'tornadozperiod', 'tantornadoz', 'tantornadozoffset', 'tantornadozperiod', 'mini', 'movex', 'movey', 'movez', 'movexoffset', 'moveyoffset',
      'movezoffset', 'xmod', 'cmod', 'mmod', 'randomspeed', 'reverse', 'split', 'alternate', 'cross', 'centered', 'swap', 'attenuatex', 'attenuatey',
      'attenuatez', 'beat', 'beatoffset', 'beatmult', 'beatperiod', 'beaty', 'beatyoffset', 'beatymult', 'beatyperiod', 'beatz', 'beatzoffset', 'beatzmult',
      'beatzperiod', 'bumpyx', 'bumpyxoffset', 'bumpyxperiod', 'tanbumpyx', 'tanbumpyxoffset', 'tanbumpyxperiod', 'bumpy', 'bumpyoffset', 'bumpyperiod',
      'tanbumpy', 'tanbumpyoffset', 'tanbumpyperiod', 'flip', 'invert', 'zigzag', 'zigzagoffset', 'zigzagperiod', 'zigzagz', 'zigzagzoffset', 'zigzagzperiod',
      'sawtooth', 'sawtoothperiod', 'sawtoothz', 'sawtoothzperiod', 'parabolax', 'parabolaz', 'digital', 'digitalsteps', 'digitaloffset', 'digitalperiod',
      'tandigital', 'tandigitalsteps', 'tandigitaloffset', 'tandigitalperiod', 'digitalz', 'digitalzsteps', 'digitalzoffset', 'digitalzperiod', 'tandigitalz',
      'tandigitalzsteps', 'tandigitalzoffset', 'tandigitalzperiod', 'square', 'squareoffset', 'squareperiod', 'squarez', 'squarezoffset', 'squarezperiod',
      'bounce', 'bounceoffset', 'bounceperiod', 'bouncez', 'bouncezoffset', 'bouncezperiod', 'xmode', 'tiny', 'tipsyx', 'tipsyxspeed', 'tipsyxoffset',
      'tantipsyx', 'tantipsyxspeed', 'tantipsyxoffset', 'tipsyz', 'tipsyzspeed', 'tipsyzoffset', 'tantipsyz', 'tantipsyzspeed', 'tantipsyzoffset', 'drunky',
      'drunkyspeed', 'drunkyoffset', 'drunkyperiod', 'tandrunky', 'tandrunkyspeed', 'tandrunkyoffset', 'tandrunkyperiod', 'invertsine', 'cosecant',
      'stealthpastreceptors'
    ];

    for (i in 0...4)
    {
      mods.push('reverse$i');
      mods.push('movex$i');
      mods.push('movey$i');
      mods.push('movez$i');
      mods.push('movexoffset$i');
      mods.push('moveyoffset$i');
      mods.push('movezoffset$i');
      mods.push('tiny$i');
      mods.push('bumpy$i');

      modList.set('xmod$i', 1);
      modList.set('cmod$i', -1);
    }
    for (mod in mods)
      modList.set(mod, 0);

    modList.set('xmod', 1);
    modList.set('cmod', -1);
    altname.set('land', 'brake');
    altname.set('dwiwave', 'expand');
    altname.set('converge', 'centered');

    // in the groove 2 mod name
    altname.set('accel', 'boost');
    altname.set('decel', 'brake');
    altname.set('drift', 'drunk');
    altname.set('float', 'tipsy');
  }

  function mod(s:String):Bool
    return modList.exists(s) && get(s) != 0;

  function get(s:String)
    return modList.get(s);

  public function exist(s:String):Bool
    return modList.exists(s) || altname.exists(s);

  public function getRealName(s:String)
    return altname.exists(s) ? altname.get(s) : s;

  var beatFactor:Array<Float> = [];

  function UpdateTipsy(time:Float, offset:Float, speed:Float, col:Int, ?tan:Float = 0)
  {
    var time_times_timer:Float = time * ((speed * 1.2) + 1.2);
    var arrow_times_mag:Float = ARROW_SIZE * 0.4;
    return (tan == 0 ? FlxMath.fastCos(time_times_timer + (col * ((offset * 1.8) + 1.8))) * arrow_times_mag : selectTanType(time_times_timer
      + (col * ((offset * 1.8) + 1.8)), get('cosecant')) * arrow_times_mag);
  }

  public function update(elapsed:Float):Void
  {
    var lastTime:Float = 0;
    var time:Float = Conductor.instance.songPosition / 1000 * 4294.967296 / 1000000; // fast time math
    expandSeconds += time - lastTime;
    expandSeconds %= ((Math.PI * 2) / (get('expandperiod') + 1));
    tanExpandSeconds += time - lastTime;
    tanExpandSeconds %= ((Math.PI * 2) / (get('tanexpandperiod') + 1));

    UpdateBeat(dim_x, Conductor.instance.currentBeat, get('beatoffset'), get('beatmult'));

    // Update BeatY
    UpdateBeat(dim_y, Conductor.instance.currentBeat, get('beatyoffset'), get('beatymult'));

    // Update BeatZ
    UpdateBeat(dim_z, Conductor.instance.currentBeat, get('beatzoffset'), get('beatzmult'));
    lastTime = time;
  }

  function UpdateBeat(d:Int, beat:Float, beat_offset:Float, beat_mult:Float)
  {
    var fAccelTime:Float = 0.2;
    var fTotalTime:Float = 0.5;
    var fBeat:Float = ((beat + fAccelTime + beat_offset) * (beat_mult + 1));
    var bEvenBeat:Bool = (Std.int(fBeat) % 2) != 0;
    beatFactor[d] = 0;
    if (fBeat < 0) return;
    // -100.2 -> -0.2 -> 0.2
    fBeat -= Math.floor(fBeat);
    fBeat += 1;
    fBeat -= Math.floor(fBeat);
    if (fBeat >= fTotalTime) return;
    if (fBeat < fAccelTime)
    {
      beatFactor[d] = scale(fBeat, 0.0, fAccelTime, 0.0, 1.0);
      beatFactor[d] *= beatFactor[d];
    }
    else
      /* fBeat < fTotalTime */ {
      beatFactor[d] = scale(fBeat, fAccelTime, fTotalTime, 1.0, 0.0);
      beatFactor[d] = 1 - (1 - beatFactor[d]) * (1 - beatFactor[d]);
    }
    if (bEvenBeat) beatFactor[d] *= -1;
    beatFactor[d] *= 20.0;
  }

  function CalculateTornadoOffsetFromMagnitude(dimension:Int, col_id:Int, magnitude:Float, effect_offset:Float, period:Float, xOffset:Array<Float>,
      field_zoom:Float, y_offset:Float, ?tan:Float = 0):Float
  {
    var minTornado:Float = 0;
    var maxTornado:Float = 0;

    var per:Int = 4;
    var wide_field:Bool = per > 4;
    var max_player_col:Int = per - 1;
    for (dimension in 0...3)
    {
      var width:Int = 3;
      // wide_field only matters for x, which is dimension 0. -Kyz
      if (dimension == 0 && wide_field)
      {
        width = 2;
      }
      for (col in 0...3)
      {
        var start_col:Int = col - width;
        var end_col:Int = col + width;
        start_col = Std.int(clamp(start_col, 0, max_player_col));
        end_col = Std.int(clamp(end_col, 0, max_player_col));
        minTornado = FlxMath.MAX_VALUE_FLOAT;
        maxTornado = FlxMath.MIN_VALUE_FLOAT;
        for (i in start_col...end_col)
        {
          // Using the x offset when the dimension might be y or z feels so
          // wrong, but it provides min and max values when otherwise the
          // limits would just be zero, which would make it do nothing. -Kyz
          minTornado = Math.min(xOffset[col_id], minTornado);
          maxTornado = Math.max(xOffset[col_id], maxTornado);
        }
      }
    }
    //
    var tornado_position_scale_to_low:Float = -1;
    var tornado_position_scale_to_high:Float = 1;
    var tornado_offset_frequency:Float = 6;
    var tornado_offset_scale_from_low:Float = -1;
    var tornado_offset_scale_from_high:Float = 1;
    var real_pixel_offset:Float = xOffset[col_id] * field_zoom;
    var position_between:Float = scale(real_pixel_offset, minTornado * field_zoom, maxTornado * field_zoom, tornado_position_scale_to_low,
      tornado_position_scale_to_high);
    var rads:Float = Math.acos(position_between);
    var frequency:Float = tornado_offset_frequency;
    rads += (y_offset + effect_offset) * ((period * frequency) + frequency) / SCREEN_HEIGHT;
    var processed_rads:Float = (tan == 0 ? FlxMath.fastCos(rads) : selectTanType(rads, get('cosecant')));
    var adjusted_pixel_offset:Float = scale(processed_rads, tornado_offset_scale_from_low, tornado_offset_scale_from_high, minTornado * field_zoom,
      maxTornado * field_zoom);
    return (adjusted_pixel_offset - real_pixel_offset) * magnitude;
  }

  public function GetYOffset(conductor:Conductor, time:Float, speed:Float, vwoosh:Bool, iCol:Int):Float
  {
    var fScrollSpeed:Float = speed;
    if (mod('expand'))
    {
      var fExpandMultiplier:Float = scale(FlxMath.fastCos(expandSeconds * 3 * (get('expandperiod') + 1)), -1, 1, 0.75, 1.75);
      fScrollSpeed *= scale(get('expand'), 0, 1, 1, fExpandMultiplier);
    }
    if (mod('tanexpand'))
    {
      var fExpandMultiplier:Float = scale(selectTanType(tanExpandSeconds * 3 * (get('tanexpandperiod') + 1), get('cosecant')), -1, 1, 0.75, 1.75);
      fScrollSpeed *= scale(get('tanexpand'), 0, 1, 1, fExpandMultiplier);
    }
    if (mod('randomspeed'))
    {
      var seed:Int = (BeatToNoteRow(Conductor.instance.currentBeat) << 8) + (iCol * 100);

      for (i in 0...3)
        seed = ((seed * 1664525) + 1013904223) & 0xFFFFFFFF;

      var fRandom:Float = seed / 4294967296.0;

      /* Random speed always increases speed: a random speed of 10 indicates
       * [1,11]. This keeps it consistent with other mods: 0 means no effect. */

      fScrollSpeed *= scale(fRandom, 0.0, 1.0, 1.0, get('randomspeed') + 1.0);
    }
    var fYOffset:Float = CalculateNoteYPos(conductor, time, vwoosh, fScrollSpeed);

    var fYAdjust:Float = 0;

    if (mod('boost'))
    {
      var fEffectHeight:Float = 720;
      var fNewYOffset:Float = fYOffset * 1.5 / ((fYOffset + fEffectHeight / 1.2) / fEffectHeight);
      var fAccelYAdjust:Float = get('boost') * (fNewYOffset - fYOffset);
      // TRICKY: Clamp this value, or else BOOST+BOOMERANG will draw a ton of arrows on the screen.
      fAccelYAdjust = clamp(fAccelYAdjust, -400, 400);
      fYAdjust += fAccelYAdjust;
    }
    if (mod('brake'))
    {
      var fEffectHeight:Float = 720;
      var fScale:Float = scale(fYOffset, 0., fEffectHeight, 0, 1.);
      var fNewYOffset:Float = fYOffset * fScale;
      var fBrakeYAdjust:Float = get('brake') * (fNewYOffset - fYOffset);
      // TRICKY: Clamp this value the same way as BOOST so that in BOOST+BRAKE, BRAKE doesn't overpower BOOST
      fBrakeYAdjust = clamp(fBrakeYAdjust, -400, 400);
      fYAdjust += fBrakeYAdjust;
    }
    if (mod('wave'))
    {
      fYAdjust += get('wave') * 20 * FlxMath.fastSin(fYOffset / ((get('waveperiod') * 38) + 38));
    }
    if (mod('parabolay'))
    {
      fYAdjust += get('parabolay') * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE);
    }
    fYAdjust *= Preferences.downscroll ? -1 : 1;
    fYOffset += fYAdjust;

    if (mod('boomerang')) fYOffset = ((-1 * fYOffset * fYOffset / SCREEN_HEIGHT) + 1.5 * fYOffset) * get('boomerang');

    return fYOffset;
  }

  public function GetReversePercentForColumn(iCol:Int):Float
  {
    var f:Float = 0;
    var iNumCols:Int = 4;
    if (mod('reverse')) f += get('reverse');
    if (mod('reverse${iCol}')) f += get('reverse${iCol}');

    if (iCol >= iNumCols / 2) f += get('split');
    if ((iCol % 2) == 1) f += get('alternate');
    var iFirstCrossCol = iNumCols / 4;
    var iLastCrossCol = iNumCols - 1 - iFirstCrossCol;
    if (iCol >= iFirstCrossCol && iCol <= iLastCrossCol) f += get('cross');
    if (f > 2) f %= 2;
    if (f > 1) f = scale(f, 1., 2., 1., 0.);
    if (Preferences.downscroll) f = 1 - f;
    return f;
  }

  public function GetXPos(iCol:Int, fYOffset:Float, mn:Int, xOffset:Array<Float>):Float
  {
    var time:Float = (Conductor.instance.songPosition / 1000);
    var f:Float = xOffset[iCol] * 1; // 以后替换
    if (mod('movex$iCol')) f += ARROW_SIZE * get('movex${iCol}') + get('movexoffset$iCol');
    if (mod('movex')) f += ARROW_SIZE * get('movex') + get('movexoffset');
    if (mod('tornado')) f += CalculateTornadoOffsetFromMagnitude(dim_x, iCol, get('tornado'), get('tornadooffset'), get('tornadoperiod'), xOffset, 1,
      fYOffset); // 以后换field_zoom
    if (mod('tantornado')) f += CalculateTornadoOffsetFromMagnitude(dim_x, iCol, get('tantornado'), get('tantornadooffset'), get('tantornadoperiod'), xOffset,
      1, fYOffset, 1); // 以后换field_zoom
    if (mod('drunk')) f += get('drunk') * FlxMath.fastCos(CalculateDrunkAngle(time, get('drunkspeed'), iCol, get('drunkoffset'), 0.2, fYOffset,
      get('drunkperiod'), 10)) * ARROW_SIZE * 0.5;
    if (mod('tandrunk')) f += get('tandrunk') * selectTanType(CalculateDrunkAngle(time, get('tandrunkspeed'), iCol, get('tandrunkoffset'), 0.2, fYOffset,
      get('tandrunkperiod'), 10),
      get('cosecant')) * ARROW_SIZE * 0.5;
    if (mod('attenuatex')) f += get('attenuatex') * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE) * (xOffset[iCol] / ARROW_SIZE);
    if (mod('beat')) f += get('beat') * (beatFactor[dim_x] * FlxMath.fastSin(fYOffset / ((get('beatperiod') * 15) + 15) + Math.PI / 2));
    if (mod('bumpyx')) f += get('bumpyx') * 40 * FlxMath.fastSin(CalculateBumpyAngle(fYOffset, get('bumpyxoffset'), get('bumpyxperiod')));
    if (mod('tanbumpyx')) f += get('tanbumpyx') * 40 * selectTanType(CalculateBumpyAngle(fYOffset, get('tanbumpyxoffset'), get('tanbumpyxperiod')),
      get('cosecant'));
    if (mod('flip'))
    {
      var iFirstCol:Int = 0;
      var iLastCol:Int = 3;
      var iNewCol:Int = Std.int(scale(iCol, iFirstCol, iLastCol, iLastCol, iFirstCol));
      var zoom:Int = 1; // 以后替换
      var fOldPixelOffset:Float = xOffset[iCol] * zoom;
      var fNewPixelOffset:Float = xOffset[iNewCol] * zoom;
      var fDistance:Float = fNewPixelOffset - fOldPixelOffset;
      f += fDistance * get('flip');
    }
    if (mod('invert')) f += get('invert') * (ARROW_SIZE * ((iCol % 2 == 0) ? 1 : -1));
    if (mod('zigzag'))
    {
      var fResult:Float = triangle((Math.PI * (1 / (get('zigzagperiod') + 1)) * ((fYOffset + (100.0 * (get('zigzagoffset')))) / ARROW_SIZE)));

      f += (get('zigzag') * ARROW_SIZE / 2) * fResult;
    }
    if (mod('sawtooth')) f += (get('sawtooth') * ARROW_SIZE) * ((0.5 / (get('sawtoothperiod') + 1) * fYOffset) / ARROW_SIZE
      - Math.floor((0.5 / (get('sawtoothperiod') + 1) * fYOffset) / ARROW_SIZE));
    if (mod('parabolax')) f += get('parabolax') * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE);

    if (mod('digital')) f += (get('digital') * ARROW_SIZE * 0.5) * Math.round((get('digitalsteps') + 1) * FlxMath.fastSin(CalculateDigitalAngle(fYOffset,
      get('digitaloffset'), get('digitalperiod')))) / (get('digitalsteps') + 1);

    if (mod('tandigital')) f += (get('tandigital') * ARROW_SIZE * 0.5) * Math.round((get('tandigitalsteps') +
      1) * selectTanType(CalculateDigitalAngle(fYOffset, get('tandigitaloffset'), get('tandigitalperiod')), get('cosecant'))) / (get('tandigitalsteps')
      + 1);

    if (mod('square'))
    {
      var fResult:Float = square((Math.PI * (fYOffset + (1.0 * (get('squareoffset')))) / (ARROW_SIZE + (get('squareperiod') * ARROW_SIZE))));

      f += (get('square') * ARROW_SIZE * 0.5) * fResult;
    }
    if (mod('bounce'))
    {
      var fBounceAmt:Float = Math.abs(FlxMath.fastSin(((fYOffset + (1.0 * (get('bounceoffset')))) / (60 + (get('bounceperiod') * 60)))));

      f += get('bounce') * ARROW_SIZE * 0.5 * fBounceAmt;
    }
    if (mod('xmode')) f += get('xmode') * (mn == 1 ? fYOffset : -fYOffset);
    if (mod('tiny'))
    {
      // Allow Tiny to pull tracks together, but not to push them apart.
      var fTinyPercent:Float = get('tiny');
      fTinyPercent = Math.min(Math.pow(0.5, fTinyPercent), 1.);
      f *= fTinyPercent;
    }
    if (mod('tipsyx')) f += get('tipsyx') * UpdateTipsy(time, get('tipsyxoffset'), get('tipsyxspeed'), iCol); // 限时返场
    if (mod('tantipsyx')) f += get('tantipsyx') * UpdateTipsy(time, get('tantipsyxoffset'), get('tantipsyxspeed'), iCol, 1);
    if (mod('swap')) f += FlxG.width / 2 * get('swap') * (mn == 0 ? -1 : 1);
    if (mod('invertsine')) f += FlxMath.fastSin(0 +
      (fYOffset * 0.004)) * (ARROW_SIZE * (iCol % 2 == 0 ? 1 : -1) * get('invertsine') * 0.5); // from modcharting tools
    return f;
  }

  public var realScrollSpeed:Float;

  public function GetYPos(iCol:Int, fYOffset:Float, mn:Int, xOffset:Array<Float>):Float
  {
    var f:Float = fYOffset;
    var time:Float = (Conductor.instance.songPosition / 1000);
    if (mod('movey$iCol')) f += ARROW_SIZE * get('movey$iCol') + get('moveyoffset$iCol');
    if (mod('movey')) f += ARROW_SIZE * get('movey') + get('moveyoffset');
    if (mod('attenuatey')) f += get('attenuatey') * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE) * (xOffset[iCol] / ARROW_SIZE);
    if (mod('tipsy')) f += get('tipsy') * UpdateTipsy(time, get('tipsyoffset'), get('tipsyspeed'), iCol);
    if (mod('tantipsy')) f += get('tantipsy') * UpdateTipsy(time, get('tantipsyoffset'), get('tantipsyspeed'), iCol, 1);
    if (mod('beaty')) f += get('beaty') * (beatFactor[dim_y] * FlxMath.fastSin(fYOffset / ((get('beatyperiod') * 15) + 15) + Math.PI / 2));
    if (mod('drunky')) f += get('drunky') * FlxMath.fastCos(CalculateDrunkAngle(time, get('drunkyspeed'), iCol, get('drunkyoffset'), 0.2, fYOffset,
      get('drunkyperiod'), 10)) * ARROW_SIZE * 0.5;
    if (mod('tandrunk')) f += get('tandrunky') * selectTanType(CalculateDrunkAngle(time, get('tandrunkyspeed'), iCol, get('tandrunkyoffset'), 0.2, fYOffset,
      get('tandrunkyperiod'), 10),
      get('cosecant')) * ARROW_SIZE * 0.5;
    /*
      // XXX: Hack: we need to scale the reverse shift by the zoom.
      var fMiniPercent:Float = get('mini');
      var fZoom:Float = 1 - fMiniPercent * 0.5;

      // don't divide by 0
      if (Math.abs(fZoom) < 0.01) fZoom = 0.01;

      var fPercentReverse:Float = GetReversePercentForColumn(iCol);
      var fShift:Float = scale(fPercentReverse, 0., 1., Constants.STRUMLINE_Y_OFFSET, FlxG.height - curHeight - Constants.STRUMLINE_Y_OFFSET);
      var fPercentCentered = get('centered');
      fShift = scale(fPercentCentered, 0., 1., fShift, 0.0);
      var fScale = scale(GetReversePercentForColumn(iCol), 0., 1., 1., -1.);
      f += fShift;
      f *= fScale; */

    return f;
  }

  public function GetZPos(iCol:Int, fYOffset:Float, mn:Int, xOffset:Array<Float>):Float
  {
    var f:Float = 0;
    var time:Float = (Conductor.instance.songPosition / 1000);
    if (mod('movez$iCol')) f += ARROW_SIZE * get('movez$iCol') + get('movezoffset$iCol');
    if (mod('movez')) f += ARROW_SIZE * get('movez') + get('movezoffset');
    if (mod('tornadoz')) f += CalculateTornadoOffsetFromMagnitude(dim_x, iCol, get('tornadoz'), get('tornadozoffset'), get('tornadozperiod'), xOffset, 1,
      fYOffset); // 以后换field_zoom
    if (mod('tantornadoz')) f += CalculateTornadoOffsetFromMagnitude(dim_x, iCol, get('tantornadoz'), get('tantornadozoffset'), get('tantornadozperiod'),
      xOffset, 1, fYOffset, 1); // 以后换field_zoom
    if (mod('drunkz')) f += get('drunkz') * FlxMath.fastCos(CalculateDrunkAngle(time, get('drunkzspeed'), iCol, get('drunkzoffset'), 0.2, fYOffset,
      get('drunkzperiod'), 10)) * ARROW_SIZE * 0.5;
    if (mod('tandrunkz')) f += get('tandrunkz') * selectTanType(CalculateDrunkAngle(time, get('tandrunkzspeed'), iCol, get('tandrunkzoffset'), 0.2, fYOffset,
      get('tandrunkzperiod'), 10),
      get('cosecant')) * ARROW_SIZE * 0.5;
    if (mod('bouncez'))
    {
      var fBounceAmt:Float = Math.abs(FlxMath.fastSin(((fYOffset + (1.0 * (get('bouncezoffset')))) / (60 + (get('bouncezperiod') * 60)))));

      f += get('bouncez') * ARROW_SIZE * 0.5 * fBounceAmt;
    }
    if (mod('bumpy')) f += get('bumpy') * 40 * FlxMath.fastSin(CalculateBumpyAngle(fYOffset, get('bumpyoffset'), get('bumpyperiod')));
    if (mod('tanbumpy')) f += get('tanbumpy') * 40 * selectTanType(CalculateBumpyAngle(fYOffset, get('tanbumpyoffset'), get('tanbumpyperiod')),
      get('cosecant'));
    if (mod('bumpy$iCol')) f += get('bumpy$iCol') * 40 * FlxMath.fastSin(CalculateBumpyAngle(fYOffset, get('bumpyoffset'), get('bumpyperiod')));
    if (mod('beatz')) f += get('beatz') * (beatFactor[dim_x] * FlxMath.fastSin(fYOffset / ((get('beatzperiod') * 15) + 15) + Math.PI / 2));
    if (mod('digitalz')) f += (get('digitalz') * ARROW_SIZE * 0.5) * Math.round((get('digitalzsteps') + 1) * FlxMath.fastSin(CalculateDigitalAngle(fYOffset,
      get('digitalzoffset'), get('digitalzperiod')))) / (get('digitalzsteps') + 1);

    if (mod('tandigitalz')) f += (get('tandigitalz') * ARROW_SIZE * 0.5) * Math.round((get('tandigitalzsteps') +
      1) * selectTanType(CalculateDigitalAngle(fYOffset, get('tandigitalzoffset'), get('tandigitalzperiod')), get('cosecant'))) / (get('tandigitalzsteps')
      + 1);
    if (mod('zigzagz'))
    {
      var fResult:Float = triangle((Math.PI * (1 / (get('zigzagzperiod') + 1)) * ((fYOffset + (100.0 * (get('zigzagzoffset')))) / ARROW_SIZE)));

      f += (get('zigzagz') * ARROW_SIZE / 2) * fResult;
    }
    if (mod('sawtoothz')) f += (get('sawtoothz') * ARROW_SIZE) * ((0.5 / (get('sawtoothzperiod') + 1) * fYOffset) / ARROW_SIZE
      - Math.floor((0.5 / (get('sawtoothperiod') + 1) * fYOffset) / ARROW_SIZE));
    if (mod('squarez'))
    {
      var fResult:Float = square((Math.PI * (fYOffset + (1.0 * (get('squarezoffset')))) / (ARROW_SIZE + (get('squarezperiod') * ARROW_SIZE))));

      f += (get('squarez') * ARROW_SIZE * 0.5) * fResult;
    }
    if (mod('parabolaz')) f += get('parabolaz') * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE);
    if (mod('attenuatez')) f += get('attenuatez') * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE) * (xOffset[iCol] / ARROW_SIZE);
    if (mod('tipsyz')) f += get('tipsyz') * UpdateTipsy(time, get('tipsyzoffset'), get('tipsyzspeed'), iCol); // 限时返场
    if (mod('tantipsyz')) f += get('tantipsyz') * UpdateTipsy(time, get('tantipsyzoffset'), get('tantipsyzspeed'), iCol, 1);
    return f;
  }

  public function GetRotation(iCol:Int, fYOffset:Float, mn:Int, xOffset:Array<Float>):Array<Float>
  {
    return [];
  }

  public function ReceptorGetRotation(iCol:Int, fYOffset:Float, mn:Int, xOffset:Array<Float>):Array<Float>
  {
    return [];
  }

  public function new()
  {
    trace('You are opening the modchart tool');
  }
}

/*
  idk it should be working
  default vals:
  BlinkModFrequency=0.3333
  MiniPercentBase=0.5
  MiniPercentGate=1
 */
