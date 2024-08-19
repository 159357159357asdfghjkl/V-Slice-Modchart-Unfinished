package funkin.play.modchart;

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.math.FlxAngle;
import openfl.geom.Vector3D;
import funkin.play.notes.Strumline;

/**
 * Read Me:
 * I'm new to haxe so the code is weird,
 * it is in a mess,
 * don't expect it too much!
 * --but who can optimize it or rewrite this shit--
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

  final ARROW_SIZE = Strumline.NOTE_SPACING;
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
    var xPerspective:Float = (x - (FlxG.width / 2)) * (1 / tanHalfFOV);
    var yPerspective:Float = (y - FlxG.height / 2) * (1 / tanHalfFOV);
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
      'drunkyspeed', 'drunkyoffset', 'drunkyperiod', 'tandrunky', 'tandrunkyspeed', 'tandrunkyoffset', 'tandrunkyperiod', 'invertsine', 'scale', 'scalex',
      'scaley', 'squish', 'stretch', 'zoom', 'pulseinner', 'pulseouter', 'pulseoffset', 'pulseperiod', 'shrinkmult', 'shrinklinear', 'cosecant',
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
      mods.push('scalex$i');
      mods.push('scaley$i');
      mods.push('scale$i');
      mods.push('squish$i');
      mods.push('stretch$i');
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

    // troll engine modname
    altname.set('tipz', 'tipsyz');
    altname.set('tipzspeed', 'tipsyzspeed');
    altname.set('tipzoffset', 'tipsyzoffset');
    altname.set('transformx', 'movex'); // but different
    altname.set('transformy', 'movey');
    altname.set('transformz', 'movez');
    altname.set('transformx-a', 'movexoffset');
    altname.set('transformy-a', 'moveyoffset');
    altname.set('transformz-a', 'movezoffset');
    altname.set('opponentswap', 'swap');
  }

  function getModCondition(s:String):Bool
    return modList.exists(s) && getValue(s) != 0;

  function getValue(s:String)
    return modList.get(s);

  public function modNameExists(s:String):Bool
    return modList.exists(s) || altname.exists(s);

  public function getName(s:String)
    return altname.exists(s) ? altname.get(s) : s;

  var beatFactor:Array<Float> = [];

  function UpdateTipsy(time:Float, offset:Float, speed:Float, col:Int, ?tan:Float = 0)
  {
    var time_times_timer:Float = time * ((speed * 1.2) + 1.2);
    var arrow_times_mag:Float = ARROW_SIZE * 0.4;
    return (tan == 0 ? FlxMath.fastCos(time_times_timer + (col * ((offset * 1.8) + 1.8))) * arrow_times_mag : selectTanType(time_times_timer
      + (col * ((offset * 1.8) + 1.8)), getValue('cosecant')) * arrow_times_mag);
  }

  public function update(elapsed:Float):Void
  {
    var lastTime:Float = 0;
    var time:Float = Conductor.instance.songPosition / 1000 * 4294.967296 / 1000000; // fast time math
    expandSeconds += time - lastTime;
    expandSeconds %= ((Math.PI * 2) / (getValue('expandperiod') + 1));
    tanExpandSeconds += time - lastTime;
    tanExpandSeconds %= ((Math.PI * 2) / (getValue('tanexpandperiod') + 1));

    UpdateBeat(dim_x, Conductor.instance.currentBeat, getValue('beatoffset'), getValue('beatmult'));

    // Update BeatY
    UpdateBeat(dim_y, Conductor.instance.currentBeat, getValue('beatyoffset'), getValue('beatymult'));

    // Update BeatZ
    UpdateBeat(dim_z, Conductor.instance.currentBeat, getValue('beatzoffset'), getValue('beatzmult'));
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
    var processed_rads:Float = (tan == 0 ? FlxMath.fastCos(rads) : selectTanType(rads, getValue('cosecant')));
    var adjusted_pixel_offset:Float = scale(processed_rads, tornado_offset_scale_from_low, tornado_offset_scale_from_high, minTornado * field_zoom,
      maxTornado * field_zoom);
    return (adjusted_pixel_offset - real_pixel_offset) * magnitude;
  }

  public function GetYOffset(conductor:Conductor, time:Float, speed:Float, vwoosh:Bool, iCol:Int):Float
  {
    var fScrollSpeed:Float = speed;
    if (getModCondition('expand'))
    {
      var fExpandMultiplier:Float = scale(FlxMath.fastCos(expandSeconds * 3 * (getValue('expandperiod') + 1)), -1, 1, 0.75, 1.75);
      fScrollSpeed *= scale(getValue('expand'), 0, 1, 1, fExpandMultiplier);
    }
    if (getModCondition('tanexpand'))
    {
      var fExpandMultiplier:Float = scale(selectTanType(tanExpandSeconds * 3 * (getValue('tanexpandperiod') + 1), getValue('cosecant')), -1, 1, 0.75, 1.75);
      fScrollSpeed *= scale(getValue('tanexpand'), 0, 1, 1, fExpandMultiplier);
    }
    if (getModCondition('randomspeed'))
    {
      var seed:Int = (BeatToNoteRow(Conductor.instance.currentBeat) << 8) + (iCol * 100);

      for (i in 0...3)
        seed = ((seed * 1664525) + 1013904223) & 0xFFFFFFFF;

      var fRandom:Float = seed / 4294967296.0;

      /* Random speed always increases speed: a random speed of 10 indicates
       * [1,11]. This keeps it consistent with other mods: 0 means no effect. */

      fScrollSpeed *= scale(fRandom, 0.0, 1.0, 1.0, getValue('randomspeed') + 1.0);
    }
    var fYOffset:Float = CalculateNoteYPos(conductor, time, vwoosh, fScrollSpeed);

    var fYAdjust:Float = 0;

    if (getModCondition('boost'))
    {
      var fEffectHeight:Float = 720;
      var fNewYOffset:Float = fYOffset * 1.5 / ((fYOffset + fEffectHeight / 1.2) / fEffectHeight);
      var fAccelYAdjust:Float = getValue('boost') * (fNewYOffset - fYOffset);
      // TRICKY: Clamp this value, or else BOOST+BOOMERANG will draw a ton of arrows on the screen.
      fAccelYAdjust = clamp(fAccelYAdjust, -400, 400);
      fYAdjust += fAccelYAdjust;
    }
    if (getModCondition('brake'))
    {
      var fEffectHeight:Float = 720;
      var fScale:Float = scale(fYOffset, 0., fEffectHeight, 0, 1.);
      var fNewYOffset:Float = fYOffset * fScale;
      var fBrakeYAdjust:Float = getValue('brake') * (fNewYOffset - fYOffset);
      // TRICKY: Clamp this value the same way as BOOST so that in BOOST+BRAKE, BRAKE doesn't overpower BOOST
      fBrakeYAdjust = clamp(fBrakeYAdjust, -400, 400);
      fYAdjust += fBrakeYAdjust;
    }
    if (getModCondition('wave'))
    {
      fYAdjust += getValue('wave') * 20 * FlxMath.fastSin(fYOffset / ((getValue('waveperiod') * 38) + 38));
    }
    if (getModCondition('parabolay'))
    {
      fYAdjust += getValue('parabolay') * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE);
    }
    fYAdjust *= Preferences.downscroll ? -1 : 1;
    fYOffset += fYAdjust;

    if (getModCondition('boomerang')) fYOffset = ((-1 * fYOffset * fYOffset / SCREEN_HEIGHT) + 1.5 * fYOffset) * getValue('boomerang');

    return fYOffset;
  }

  public function GetReversePercentForColumn(iCol:Int):Float
  {
    var f:Float = 0;
    var iNumCols:Int = 4;
    if (getModCondition('reverse')) f += getValue('reverse');
    if (getModCondition('reverse${iCol}')) f += getValue('reverse${iCol}');

    if (iCol >= iNumCols / 2) f += getValue('split');
    if ((iCol % 2) == 1) f += getValue('alternate');
    var iFirstCrossCol = iNumCols / 4;
    var iLastCrossCol = iNumCols - 1 - iFirstCrossCol;
    if (iCol >= iFirstCrossCol && iCol <= iLastCrossCol) f += getValue('cross');
    if (f > 2) f %= 2;
    if (f > 1) f = scale(f, 1., 2., 1., 0.);
    if (Preferences.downscroll) f = 1 - f;
    return f;
  }

  public function GetXPos(iCol:Int, fYOffset:Float, pn:Int, xOffset:Array<Float>):Float
  {
    var time:Float = (Conductor.instance.songPosition / 1000);
    var f:Float = xOffset[iCol] * 1;
    if (getModCondition('movex$iCol')) f += ARROW_SIZE * getValue('movex${iCol}') + getValue('movexoffset$iCol');
    if (getModCondition('movex')) f += ARROW_SIZE * getValue('movex') + getValue('movexoffset');
    if (getModCondition('tornado')) f += CalculateTornadoOffsetFromMagnitude(dim_x, iCol, getValue('tornado'), getValue('tornadooffset'),
      getValue('tornadoperiod'), xOffset, 1, fYOffset);
    if (getModCondition('tantornado')) f += CalculateTornadoOffsetFromMagnitude(dim_x, iCol, getValue('tantornado'), getValue('tantornadooffset'),
      getValue('tantornadoperiod'), xOffset, 1, fYOffset, 1);
    if (getModCondition('drunk')) f += getValue('drunk') * FlxMath.fastCos(CalculateDrunkAngle(time, getValue('drunkspeed'), iCol, getValue('drunkoffset'),
      0.2, fYOffset, getValue('drunkperiod'), 10)) * ARROW_SIZE * 0.5;
    if (getModCondition('tandrunk')) f += getValue('tandrunk') * selectTanType(CalculateDrunkAngle(time, getValue('tandrunkspeed'), iCol,
      getValue('tandrunkoffset'), 0.2, fYOffset, getValue('tandrunkperiod'), 10),
      getValue('cosecant')) * ARROW_SIZE * 0.5;
    if (getModCondition('attenuatex')) f += getValue('attenuatex') * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE) * (xOffset[iCol] / ARROW_SIZE);
    if (getModCondition('beat')) f += getValue('beat') * (beatFactor[dim_x] * FlxMath.fastSin(fYOffset / ((getValue('beatperiod') * 15) + 15) + Math.PI / 2));
    if (getModCondition('bumpyx')) f += getValue('bumpyx') * 40 * FlxMath.fastSin(CalculateBumpyAngle(fYOffset, getValue('bumpyxoffset'),
      getValue('bumpyxperiod')));
    if (getModCondition('tanbumpyx')) f += getValue('tanbumpyx') * 40 * selectTanType(CalculateBumpyAngle(fYOffset, getValue('tanbumpyxoffset'),
      getValue('tanbumpyxperiod')), getValue('cosecant'));
    if (getModCondition('flip'))
    {
      var iFirstCol:Int = 0;
      var iLastCol:Int = 3;
      var iNewCol:Int = Std.int(scale(iCol, iFirstCol, iLastCol, iLastCol, iFirstCol));
      var zoom:Int = 1;
      var fOldPixelOffset:Float = xOffset[iCol] * zoom;
      var fNewPixelOffset:Float = xOffset[iNewCol] * zoom;
      var fDistance:Float = fNewPixelOffset - fOldPixelOffset;
      f += fDistance * getValue('flip');
    }
    if (getModCondition('invert')) f += getValue('invert') * (ARROW_SIZE * ((iCol % 2 == 0) ? 1 : -1));
    if (getModCondition('zigzag'))
    {
      var fResult:Float = triangle((Math.PI * (1 / (getValue('zigzagperiod') + 1)) * ((fYOffset + (100.0 * (getValue('zigzagoffset')))) / ARROW_SIZE)));

      f += (getValue('zigzag') * ARROW_SIZE / 2) * fResult;
    }
    if (getModCondition('sawtooth')) f += (getValue('sawtooth') * ARROW_SIZE) * ((0.5 / (getValue('sawtoothperiod') + 1) * fYOffset) / ARROW_SIZE
      - Math.floor((0.5 / (getValue('sawtoothperiod') + 1) * fYOffset) / ARROW_SIZE));
    if (getModCondition('parabolax')) f += getValue('parabolax') * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE);

    if (getModCondition('digital')) f += (getValue('digital') * ARROW_SIZE * 0.5) * Math.round((getValue('digitalsteps') +
      1) * FlxMath.fastSin(CalculateDigitalAngle(fYOffset, getValue('digitaloffset'), getValue('digitalperiod')))) / (getValue('digitalsteps')
      + 1);

    if (getModCondition('tandigital')) f += (getValue('tandigital') * ARROW_SIZE * 0.5) * Math.round((getValue('tandigitalsteps') +
      1) * selectTanType(CalculateDigitalAngle(fYOffset, getValue('tandigitaloffset'), getValue('tandigitalperiod')),
        getValue('cosecant'))) / (getValue('tandigitalsteps')
      + 1);

    if (getModCondition('square'))
    {
      var fResult:Float = square((Math.PI * (fYOffset + (1.0 * (getValue('squareoffset')))) / (ARROW_SIZE + (getValue('squareperiod') * ARROW_SIZE))));

      f += (getValue('square') * ARROW_SIZE * 0.5) * fResult;
    }
    if (getModCondition('bounce'))
    {
      var fBounceAmt:Float = Math.abs(FlxMath.fastSin(((fYOffset + (1.0 * (getValue('bounceoffset')))) / (60 + (getValue('bounceperiod') * 60)))));

      f += getValue('bounce') * ARROW_SIZE * 0.5 * fBounceAmt;
    }
    if (getModCondition('xmode')) f += getValue('xmode') * (pn == 1 ? fYOffset : -fYOffset);
    if (getModCondition('tiny'))
    {
      // Allow Tiny to pull tracks together, but not to push them apart.
      var fTinyPercent:Float = getValue('tiny');
      fTinyPercent = Math.min(Math.pow(0.5, fTinyPercent), 1.);
      f *= fTinyPercent;
    }
    if (getModCondition('tipsyx')) f += getValue('tipsyx') * UpdateTipsy(time, getValue('tipsyxoffset'), getValue('tipsyxspeed'), iCol);
    if (getModCondition('tantipsyx')) f += getValue('tantipsyx') * UpdateTipsy(time, getValue('tantipsyxoffset'), getValue('tantipsyxspeed'), iCol, 1);
    if (getModCondition('swap')) f += FlxG.width / 2 * getValue('swap') * (pn == 0 ? -1 : 1);
    if (getModCondition('invertsine')) f += FlxMath.fastSin(0 +
      (fYOffset * 0.004)) * (ARROW_SIZE * (iCol % 2 == 0 ? 1 : -1) * getValue('invertsine') * 0.5); // from modcharting tools
    return f;
  }

  public function GetYPos(iCol:Int, fYOffset:Float, pn:Int, xOffset:Array<Float>):Float
  {
    var f:Float = fYOffset;
    var time:Float = (Conductor.instance.songPosition / 1000);
    if (getModCondition('movey$iCol')) f += ARROW_SIZE * getValue('movey$iCol') + getValue('moveyoffset$iCol');
    if (getModCondition('movey')) f += ARROW_SIZE * getValue('movey') + getValue('moveyoffset');
    if (getModCondition('attenuatey')) f += getValue('attenuatey') * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE) * (xOffset[iCol] / ARROW_SIZE);
    if (getModCondition('tipsy')) f += getValue('tipsy') * UpdateTipsy(time, getValue('tipsyoffset'), getValue('tipsyspeed'), iCol);
    if (getModCondition('tantipsy')) f += getValue('tantipsy') * UpdateTipsy(time, getValue('tantipsyoffset'), getValue('tantipsyspeed'), iCol, 1);
    if (getModCondition('beaty')) f += getValue('beaty') * (beatFactor[dim_y] * FlxMath.fastSin(fYOffset / ((getValue('beatyperiod') * 15) + 15) +
      Math.PI / 2));
    if (getModCondition('drunky')) f += getValue('drunky') * FlxMath.fastCos(CalculateDrunkAngle(time, getValue('drunkyspeed'), iCol,
      getValue('drunkyoffset'), 0.2, fYOffset, getValue('drunkyperiod'), 10)) * ARROW_SIZE * 0.5;
    if (getModCondition('tandrunk')) f += getValue('tandrunky') * selectTanType(CalculateDrunkAngle(time, getValue('tandrunkyspeed'), iCol,
      getValue('tandrunkyoffset'), 0.2, fYOffset, getValue('tandrunkyperiod'), 10),
      getValue('cosecant')) * ARROW_SIZE * 0.5;
    /*
      // XXX: Hack: we need to scale the reverse shift by the zoom.
      var fMiniPercent:Float = getValue('mini');
      var fZoom:Float = 1 - fMiniPercent * 0.5;

      // don't divide by 0
      if (Math.abs(fZoom) < 0.01) fZoom = 0.01;

      var fPercentReverse:Float = GetReversePercentForColumn(iCol);
      var fShift:Float = scale(fPercentReverse, 0., 1., Constants.STRUMLINE_Y_OFFSET, FlxG.height - curHeight - Constants.STRUMLINE_Y_OFFSET);
      var fPercentCentered = getValue('centered');
      fShift = scale(fPercentCentered, 0., 1., fShift, 0.0);
      var fScale = scale(GetReversePercentForColumn(iCol), 0., 1., 1., -1.);
      f += fShift;
      f *= fScale; */

    return f;
  }

  public function GetZPos(iCol:Int, fYOffset:Float, pn:Int, xOffset:Array<Float>):Float
  {
    var f:Float = 0;
    var time:Float = (Conductor.instance.songPosition / 1000);
    if (getModCondition('movez$iCol')) f += ARROW_SIZE * getValue('movez$iCol') + getValue('movezoffset$iCol');
    if (getModCondition('movez')) f += ARROW_SIZE * getValue('movez') + getValue('movezoffset');
    if (getModCondition('tornadoz')) f += CalculateTornadoOffsetFromMagnitude(dim_x, iCol, getValue('tornadoz'), getValue('tornadozoffset'),
      getValue('tornadozperiod'), xOffset, 1, fYOffset);
    if (getModCondition('tantornadoz')) f += CalculateTornadoOffsetFromMagnitude(dim_x, iCol, getValue('tantornadoz'), getValue('tantornadozoffset'),
      getValue('tantornadozperiod'), xOffset, 1, fYOffset, 1);
    if (getModCondition('drunkz')) f += getValue('drunkz') * FlxMath.fastCos(CalculateDrunkAngle(time, getValue('drunkzspeed'), iCol,
      getValue('drunkzoffset'), 0.2, fYOffset, getValue('drunkzperiod'), 10)) * ARROW_SIZE * 0.5;
    if (getModCondition('tandrunkz')) f += getValue('tandrunkz') * selectTanType(CalculateDrunkAngle(time, getValue('tandrunkzspeed'), iCol,
      getValue('tandrunkzoffset'), 0.2, fYOffset, getValue('tandrunkzperiod'), 10),
      getValue('cosecant')) * ARROW_SIZE * 0.5;
    if (getModCondition('bouncez'))
    {
      var fBounceAmt:Float = Math.abs(FlxMath.fastSin(((fYOffset + (1.0 * (getValue('bouncezoffset')))) / (60 + (getValue('bouncezperiod') * 60)))));

      f += getValue('bouncez') * ARROW_SIZE * 0.5 * fBounceAmt;
    }
    if (getModCondition('bumpy')) f += getValue('bumpy') * 40 * FlxMath.fastSin(CalculateBumpyAngle(fYOffset, getValue('bumpyoffset'),
      getValue('bumpyperiod')));
    if (getModCondition('tanbumpy')) f += getValue('tanbumpy') * 40 * selectTanType(CalculateBumpyAngle(fYOffset, getValue('tanbumpyoffset'),
      getValue('tanbumpyperiod')), getValue('cosecant'));
    if (getModCondition('bumpy$iCol')) f += getValue('bumpy$iCol') * 40 * FlxMath.fastSin(CalculateBumpyAngle(fYOffset, getValue('bumpyoffset'),
      getValue('bumpyperiod')));
    if (getModCondition('beatz')) f += getValue('beatz') * (beatFactor[dim_x] * FlxMath.fastSin(fYOffset / ((getValue('beatzperiod') * 15) + 15) +
      Math.PI / 2));
    if (getModCondition('digitalz')) f += (getValue('digitalz') * ARROW_SIZE * 0.5) * Math.round((getValue('digitalzsteps') +
      1) * FlxMath.fastSin(CalculateDigitalAngle(fYOffset, getValue('digitalzoffset'), getValue('digitalzperiod')))) / (getValue('digitalzsteps')
      + 1);

    if (getModCondition('tandigitalz')) f += (getValue('tandigitalz') * ARROW_SIZE * 0.5) * Math.round((getValue('tandigitalzsteps') +
      1) * selectTanType(CalculateDigitalAngle(fYOffset, getValue('tandigitalzoffset'), getValue('tandigitalzperiod')),
      getValue('cosecant'))) / (getValue('tandigitalzsteps') + 1);
    if (getModCondition('zigzagz'))
    {
      var fResult:Float = triangle((Math.PI * (1 / (getValue('zigzagzperiod') + 1)) * ((fYOffset + (100.0 * (getValue('zigzagzoffset')))) / ARROW_SIZE)));

      f += (getValue('zigzagz') * ARROW_SIZE / 2) * fResult;
    }
    if (getModCondition('sawtoothz')) f += (getValue('sawtoothz') * ARROW_SIZE) * ((0.5 / (getValue('sawtoothzperiod') + 1) * fYOffset) / ARROW_SIZE
      - Math.floor((0.5 / (getValue('sawtoothperiod') + 1) * fYOffset) / ARROW_SIZE));
    if (getModCondition('squarez'))
    {
      var fResult:Float = square((Math.PI * (fYOffset + (1.0 * (getValue('squarezoffset')))) / (ARROW_SIZE + (getValue('squarezperiod') * ARROW_SIZE))));

      f += (getValue('squarez') * ARROW_SIZE * 0.5) * fResult;
    }
    if (getModCondition('parabolaz')) f += getValue('parabolaz') * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE);
    if (getModCondition('attenuatez')) f += getValue('attenuatez') * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE) * (xOffset[iCol] / ARROW_SIZE);
    if (getModCondition('tipsyz')) f += getValue('tipsyz') * UpdateTipsy(time, getValue('tipsyzoffset'), getValue('tipsyzspeed'), iCol);
    if (getModCondition('tantipsyz')) f += getValue('tantipsyz') * UpdateTipsy(time, getValue('tantipsyzoffset'), getValue('tantipsyzspeed'), iCol, 1);
    return f;
  }

  public function GetRotation(iCol:Int, fYOffset:Float, pn:Int, xOffset:Array<Float>):Array<Float>
  {
    return [];
  }

  public function ReceptorGetRotation(iCol:Int, fYOffset:Float, pn:Int, xOffset:Array<Float>):Array<Float>
  {
    return [];
  }

  public function GetScale(iCol:Int, fYOffset:Float, pn:Int, defaultscale:Float, isSus:Bool):Array<Float>
  {
    var x:Float = defaultscale;
    var y:Float = defaultscale;

    x += getValue('scale') + getValue('scale$iCol') + getValue('scalex$iCol') + getValue('scalex');
    y += getValue('scale') + getValue('scale$iCol') + getValue('scaley$iCol') + getValue('scaley');
    var angle = 0;

    var stretch = getValue("stretch") + getValue('stretch$iCol');
    var squish = getValue("squish") + getValue('squish$iCol');
    var stretchX = FlxMath.lerp(1, 0.5, stretch);
    var stretchY = FlxMath.lerp(1, 2, stretch);
    var squishX = FlxMath.lerp(1, 2, squish);
    var squishY = FlxMath.lerp(1, 0.5, squish);
    x *= (FlxMath.fastSin(angle * Math.PI / 180) * squishY) + (FlxMath.fastCos(angle * Math.PI / 180) * squishX);
    x *= (FlxMath.fastSin(angle * Math.PI / 180) * stretchY) + (FlxMath.fastCos(angle * Math.PI / 180) * stretchX);
    y *= (FlxMath.fastCos(angle * Math.PI / 180) * stretchY) + (FlxMath.fastSin(angle * Math.PI / 180) * stretchX);
    y *= (FlxMath.fastCos(angle * Math.PI / 180) * squishY) + (FlxMath.fastSin(angle * Math.PI / 180) * squishX);

    if (isSus) y = 1;
    return [x, y];
  }

  public function GetZoom(iCol:Int, fYOffset:Float, pn:Int):Float
  {
    var fZoom:Float = 1.0;
    // Design change:  Instead of having a flag in the style that toggles a
    // fixed zoom (0.6) that is only applied to the columns, ScreenGameplay now
    // calculates a zoom factor to apply to the notefield and puts it in the
    // PlayerState. -Kyz
    var fPulseInner:Float = 1.0;
    if (getModCondition('pulseinner') || getModCondition('pulseouter'))
    {
      fPulseInner = ((getValue('pulseinner') * 0.5) + 1);
      if (fPulseInner == 0) fPulseInner = 0.01;
    }
    if (getModCondition('pulseinner') || getModCondition('pulseouter'))
    {
      var sine:Float = FlxMath.fastSin(((fYOffset + (100.0 * (getValue('pulseoffset')))) / (0.4 * (ARROW_SIZE + (getValue('pulseperiod') * ARROW_SIZE)))));

      fZoom *= (sine * (getValue('pulseouter') * 0.5)) + fPulseInner;
    }
    if (getModCondition('shrinkmult') && fYOffset >= 0) fZoom *= 1 / (1 + (fYOffset * (getValue('shrinkmult') / 100.0)));

    if (getModCondition('shrinklinear') && fYOffset >= 0) fZoom += fYOffset * (0.5 * getValue('shrinklinear') / ARROW_SIZE);

    if (getModCondition('tiny'))
    {
      var fTinyPercent = getValue('tiny');
      fTinyPercent = Math.pow(0.5, fTinyPercent);
      fZoom *= fTinyPercent;
    }
    if (getModCondition('tiny$iCol'))
    {
      var fTinyPercent = Math.pow(0.5, getValue('tiny$iCol'));
      fZoom *= fTinyPercent;
    }
    return fZoom;
  }

  public function new():Void {}
}

/*
  idk it should be working
  default vals:
  BlinkModFrequency=0.3333
 */
