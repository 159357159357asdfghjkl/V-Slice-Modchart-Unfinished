package funkin.play.modchart;

import flixel.FlxG;
import flixel.math.FlxMath;
import funkin.play.notes.Strumline;
import openfl.geom.Vector3D;

/**
 * Read Me:
 * I'm new to haxe so the code is weird,
 * it is in a mess,
 * don't expect it too much!
 * --but who can optimize it or rewrite this shit--
 * [Don't support many of NotITG mods unless it's open-source]
 */
class Modchart
{
  private var modList:Map<String, Float> = new Map<String, Float>();
  private var altname:Map<String, String> = new Map<String, String>();

  final ARROW_SIZE:Int = Strumline.NOTE_SPACING;
  final STEPMANIA_ARROW_SIZE:Int = 64;
  final SCREEN_HEIGHT = FlxG.height;

  function selectTanType(angle:Float, is_cosec:Float)
  {
    if (is_cosec != 0) return ModchartMath.fastCsc(angle);
    else
      return ModchartMath.fastTan(angle);
  }

  var dim_x:Int = 0;
  var dim_y:Int = 1;
  var dim_z:Int = 2;
  var expandSeconds:Float = 0;
  var tanExpandSeconds:Float = 0;
  var beatFactor:Array<Float> = [];

  function CalculateNoteYPos(conductor:Conductor, strumTime:Float, vwoosh:Bool = true, scrollSpeed:Float):Float
  {
    var vwoosh:Float = 1.0;
    return
      Constants.PIXELS_PER_MS * (conductor.songPosition - strumTime - Conductor.instance.inputOffset) * scrollSpeed * vwoosh * (Preferences.downscroll ? 1 : -1);
  }

  function GetCenterLine():Float
  {
    /* Another mini hack: if EFFECT_MINI is on, then our center line is at
     * eg. 320, not 160. */
    var fMiniPercent:Float = getValue('mini');
    var fZoom:Float = 1 - fMiniPercent * 0.5;
    return 160.0 / fZoom;
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

  public function initMods()
  {
    var ZERO:Array<String> = [
      'boost', 'brake', 'wave', 'waveoffset', 'waveperiod', 'parabolay', 'boomerang', 'expand', 'expandperiod', 'drunk', 'drunkspeed', 'drunkoffset',
      'drunkperiod', 'tandrunk', 'tandrunkspeed', 'tandrunkoffset', 'tandrunkperiod', 'drunkz', 'drunkzspeed', 'drunkzoffset', 'drunkzperiod', 'tandrunkz',
      'tandrunkzspeed', 'tandrunkzoffset', 'tandrunkzperiod', 'tanexpand', 'tanexpandperiod', 'tipsy', 'tipsyspeed', 'tipsyoffset', 'tantipsy',
      'tantipsyspeed', 'tantipsyoffset', 'tornado', 'tornadooffset', 'tornadoperiod', 'tantornado', 'tantornadooffset', 'tantornadoperiod', 'tornadoz',
      'tornadozoffset', 'tornadozperiod', 'tantornadoz', 'tantornadozoffset', 'tantornadozperiod', 'tornadoy', 'tornadoyoffset', 'tornadoyperiod',
      'tantornadoy', 'tantornadoyoffset', 'tantornadoyperiod', 'mini', 'movex', 'movey', 'movez', 'movexoffset', 'moveyoffset', 'movezoffset', 'movexoffset1',
      'moveyoffset1', 'movezoffset1', 'randomspeed', 'reverse', 'split', 'divide', 'alternate', 'cross', 'centered', 'swap', 'attenuatex', 'attenuatey',
      'attenuatez', 'beat', 'beatoffset', 'beatmult', 'beatperiod', 'beaty', 'beatyoffset', 'beatymult', 'beatyperiod', 'beatz', 'beatzoffset', 'beatzmult',
      'beatzperiod', 'bumpyx', 'bumpyxoffset', 'bumpyxperiod', 'tanbumpyx', 'tanbumpyxoffset', 'tanbumpyxperiod', 'bumpyy', 'bumpyyoffset', 'bumpyyperiod',
      'tanbumpyy', 'tanbumpyyoffset', 'tanbumpyyperiod', 'bumpy', 'bumpyoffset', 'bumpyperiod', 'tanbumpy', 'tanbumpyoffset', 'tanbumpyperiod', 'flip',
      'invert', 'zigzag', 'zigzagoffset', 'zigzagperiod', 'zigzagz', 'zigzagzoffset', 'zigzagzperiod', 'sawtooth', 'sawtoothperiod', 'sawtoothz',
      'sawtoothzperiod', 'parabolax', 'parabolaz', 'digital', 'digitalsteps', 'digitaloffset', 'digitalperiod', 'tandigital', 'tandigitalsteps',
      'tandigitaloffset', 'tandigitalperiod', 'digitalz', 'digitalzsteps', 'digitalzoffset', 'digitalzperiod', 'tandigitalz', 'tandigitalzsteps',
      'tandigitalzoffset', 'tandigitalzperiod', 'square', 'squareoffset', 'squareperiod', 'squarez', 'squarezoffset', 'squarezperiod', 'bounce',
      'bounceoffset', 'bounceperiod', 'bouncey', 'bounceyoffset', 'bounceyperiod', 'bouncez', 'bouncezoffset', 'bouncezperiod', 'xmode', 'tiny', 'tipsyx',
      'tipsyxspeed', 'tipsyxoffset', 'tantipsyx', 'tantipsyxspeed', 'tantipsyxoffset', 'tipsyz', 'tipsyzspeed', 'tipsyzoffset', 'tantipsyz', 'tantipsyzspeed',
      'tantipsyzoffset', 'drunky', 'drunkyspeed', 'drunkyoffset', 'drunkyperiod', 'tandrunky', 'tandrunkyspeed', 'tandrunkyoffset', 'tandrunkyperiod',
      'invertsine', 'vibrate', 'scale', 'scalex', 'scaley', 'squish', 'stretch', 'pulseinner', 'pulseouter', 'pulseoffset', 'pulseperiod', 'shrinkmult',
      'shrinklinear', 'noteskewx', 'noteskewy', 'zoomx', 'zoomy', 'tinyx', 'tinyy', 'confusionx', 'confusionxoffset', 'confusiony', 'confusionyoffset',
      'confusion', 'confusionoffset', 'dizzy', 'twirl', 'roll', 'orient', 'cosecant', 'camx', 'camy', 'camz', 'skewx', 'skewy'
    ];
    var ONE:Array<String> = ['xmod', 'zoom', 'movew'];
    for (i in 0...4)
    {
      ZERO.push('reverse$i');
      ZERO.push('movex$i');
      ZERO.push('movey$i');
      ZERO.push('movez$i');
      ZERO.push('movexoffset$i');
      ZERO.push('moveyoffset$i');
      ZERO.push('movezoffset$i');
      ZERO.push('movexoffset1$i');
      ZERO.push('moveyoffset1$i');
      ZERO.push('movezoffset1$i');
      ZERO.push('tiny$i');
      ZERO.push('bumpy$i');
      ZERO.push('scalex$i');
      ZERO.push('scaley$i');
      ZERO.push('scale$i');
      ZERO.push('squish$i');
      ZERO.push('stretch$i');
      ZERO.push('noteskewx$i');
      ZERO.push('noteskewy$i');
      ZERO.push('tinyx$i');
      ZERO.push('tinyy$i');
      ZERO.push('confusionx$i');
      ZERO.push('confusiony$i');
      ZERO.push('confusion$i');
      ZERO.push('confusionxoffset$i');
      ZERO.push('confusionyoffset$i');
      ZERO.push('confusionoffset$i');
      ONE.push('movew$i');
      ONE.push('zoom$i');
    }
    for (mod in ZERO)
      modList.set(mod, 0);

    for (mod in ONE)
      modList.set(mod, 1);

    modList.set('cmod', -1);
    modList.set('mmod', 45);
    altname.set('land', 'brake');
    altname.set('dwiwave', 'expand');
    altname.set('converge', 'centered');

    // in the groove 2 mod name
    altname.set('accel', 'boost');
    altname.set('decel', 'brake');
    altname.set('drift', 'drunk');
    altname.set('float', 'tipsy');

    altname.set('tipz', 'tipsyz');
    altname.set('tipzspeed', 'tipsyzspeed');
    altname.set('tipzoffset', 'tipsyzoffset');
  }

  public function setValue(s:String, val:Float)
  {
    if (modList.exists(s) || altname.exists(s)) modList.set(getName(s), val);
  }

  public function getValue(s:String):Float
    return modList.exists(s) ? modList.get(s) : 0;

  public function getName(s:String):String
    return altname.exists(s) ? altname.get(s) : s;

  function UpdateTipsy(time:Float, offset:Float, speed:Float, col:Int, ?tan:Float = 0)
  {
    var time_times_timer:Float = time * ((speed * 1.2) + 1.2);
    var arrow_times_mag:Float = ARROW_SIZE * 0.4;
    return (tan == 0 ? FlxMath.fastCos(time_times_timer + (col * ((offset * 1.8) + 1.8))) * arrow_times_mag : selectTanType(time_times_timer
      + (col * ((offset * 1.8) + 1.8)), getValue('cosecant')) * arrow_times_mag);
  }

  function UpdateBeat(d:Int, beat_offset:Float, beat_mult:Float)
  {
    var fAccelTime:Float = 0.2;
    var fTotalTime:Float = 0.5;
    var fBeat:Float = ((Conductor.instance.currentBeatTime + fAccelTime + beat_offset) * (beat_mult + 1));
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
      beatFactor[d] = ModchartMath.scale(fBeat, 0.0, fAccelTime, 0.0, 1.0);
      beatFactor[d] *= beatFactor[d];
    }
    else
      /* fBeat < fTotalTime */ {
      beatFactor[d] = ModchartMath.scale(fBeat, fAccelTime, fTotalTime, 1.0, 0.0);
      beatFactor[d] = 1 - (1 - beatFactor[d]) * (1 - beatFactor[d]);
    }
    if (bEvenBeat) beatFactor[d] *= -1;
    beatFactor[d] *= 20.0;
  }

  public function update(elapsed:Float):Void
  {
    var lastTime:Float = 0;
    var time:Float = Conductor.instance.songPosition / 1000 * 4294.967296 / 1000000; // fast time math
    expandSeconds += time - lastTime;
    expandSeconds = ModchartMath.mod(expandSeconds, ((Math.PI * 2) / (getValue('expandperiod') + 1)));
    tanExpandSeconds += time - lastTime;
    tanExpandSeconds = ModchartMath.mod(tanExpandSeconds, ((Math.PI * 2) / (getValue('tanexpandperiod') + 1)));
    UpdateBeat(dim_x, getValue('beatoffset'), getValue('beatmult'));
    UpdateBeat(dim_y, getValue('beatyoffset'), getValue('beatymult'));
    UpdateBeat(dim_z, getValue('beatzoffset'), getValue('beatzmult'));
    lastTime = time;
  }

  public function GetYOffset(conductor:Conductor, time:Float, speed:Float, vwoosh:Bool, iCol:Int, note:flixel.FlxSprite):Float
  {
    var fScrollSpeed:Float = speed;

    if (getValue('expand') != 0)
    {
      var fExpandMultiplier:Float = ModchartMath.scale(FlxMath.fastCos(expandSeconds * 3 * (getValue('expandperiod') + 1)), -1, 1, 0.75, 1.75);
      fScrollSpeed *= ModchartMath.scale(getValue('expand'), 0, 1, 1, fExpandMultiplier);
    }

    if (getValue('tanexpand') != 0)
    {
      var fExpandMultiplier:Float = ModchartMath.scale(selectTanType(tanExpandSeconds * 3 * (getValue('tanexpandperiod') + 1), getValue('cosecant')), -1, 1,
        0.75, 1.75);
      fScrollSpeed *= ModchartMath.scale(getValue('tanexpand'), 0, 1, 1, fExpandMultiplier);
    }

    if (getValue('randomspeed') != 0)
    {
      var seed:Int = (ModchartMath.BeatToNoteRow(Conductor.instance.currentBeatTime) << 8) + (iCol * 100);

      for (i in 0...3)
        seed = ((seed * 1664525) + 1013904223) & 0xFFFFFFFF;

      var fRandom:Float = seed / 4294967296.0;

      /* Random speed always increases speed: a random speed of 10 indicates
       * [1,11]. This keeps it consistent with other mods: 0 means no effect. */

      fScrollSpeed *= ModchartMath.scale(fRandom, 0.0, 1.0, 1.0, getValue('randomspeed') + 1.0);
    }

    var fYOffset:Float = CalculateNoteYPos(conductor, time, vwoosh, fScrollSpeed);
    var fYAdjust:Float = 0;

    if (getValue('boost') != 0)
    {
      var fEffectHeight:Float = 720;
      var fNewYOffset:Float = fYOffset * 1.5 / ((fYOffset + fEffectHeight / 1.2) / fEffectHeight);
      var fAccelYAdjust:Float = getValue('boost') * (fNewYOffset - fYOffset);
      // TRICKY: Clamp this value, or else BOOST+BOOMERANG will draw a ton of arrows on the screen.
      fAccelYAdjust = ModchartMath.clamp(fAccelYAdjust, -400, 400);
      fYAdjust += fAccelYAdjust;
    }

    if (getValue('brake') != 0)
    {
      var fEffectHeight:Float = 720;
      var fScale:Float = ModchartMath.scale(fYOffset, 0., fEffectHeight, 0, 1.);
      var fNewYOffset:Float = fYOffset * fScale;
      var fBrakeYAdjust:Float = getValue('brake') * (fNewYOffset - fYOffset);
      // TRICKY: Clamp this value the same way as BOOST so that in BOOST+BRAKE, BRAKE doesn't overpower BOOST
      fBrakeYAdjust = ModchartMath.clamp(fBrakeYAdjust, -400, 400);
      fYAdjust += fBrakeYAdjust;
    }

    if (getValue('wave') != 0)
    {
      fYAdjust += getValue('wave') * 20 * FlxMath.fastSin((fYOffset + getValue('waveoffset')) / ((getValue('waveperiod') * 38) + 38));
    }

    if (getValue('parabolay') != 0)
    {
      fYAdjust += getValue('parabolay') * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE);
    }

    fYAdjust *= Preferences.downscroll ? -1 : 1;
    fYOffset += fYAdjust;

    if (getValue('boomerang') != 0) fYOffset = ((-1 * fYOffset * fYOffset / SCREEN_HEIGHT) + 1.5 * fYOffset) * getValue('boomerang');

    var reverseStuff:Float = (1 - 2 * GetReversePercentForColumn(iCol));
    fYOffset *= reverseStuff;
    fYOffset *= GetMultScrollSpeed();
    return fYOffset;
  }

  public function GetReversePercentForColumn(iCol:Int):Float
  {
    var f:Float = 0;
    var iNumCols:Int = 4;
    f += getValue('reverse');
    f += getValue('reverse${iCol}');

    if (iCol >= iNumCols / 2) f += getValue('split');
    if ((iCol % 2) == 1) f += getValue('alternate');
    var iFirstCrossCol = iNumCols / 4;
    var iLastCrossCol = iNumCols - 1 - iFirstCrossCol;
    if (iCol >= iFirstCrossCol && iCol <= iLastCrossCol) f += getValue('cross');
    if (f > 2) f = ModchartMath.mod(f, 2);
    if (f > 1) f = ModchartMath.scale(f, 1., 2., 1., 0.);
    if (Preferences.downscroll) f = 1 - f;
    return f;
  }

  public function GetXPos(iCol:Int, fYOffset:Float, pn:Int, xOffset:Array<Float>):Float
  {
    var time:Float = (Conductor.instance.songPosition / 1000);
    var f:Float = 0;
    f += ARROW_SIZE * getValue('movex${iCol}') + getValue('movexoffset$iCol') + getValue('movexoffset1$iCol');

    f += ARROW_SIZE * getValue('movex') + getValue('movexoffset') + getValue('movexoffset1');

    if (getValue('vibrate') != 0) f += (Math.random() - 0.5) * getValue('vibrate') * 20;

    if (getValue('drunk') != 0) f += getValue('drunk') * FlxMath.fastCos(CalculateDrunkAngle(time, getValue('drunkspeed'), iCol, getValue('drunkoffset'), 0.2,
      fYOffset, getValue('drunkperiod'), 10)) * ARROW_SIZE * 0.5;

    if (getValue('tandrunk') != 0) f += getValue('tandrunk') * selectTanType(CalculateDrunkAngle(time, getValue('tandrunkspeed'), iCol,
      getValue('tandrunkoffset'), 0.2, fYOffset, getValue('tandrunkperiod'), 10),
      getValue('cosecant')) * ARROW_SIZE * 0.5;

    if (getValue('attenuatex') != 0) f += getValue('attenuatex') * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE) * (xOffset[iCol] / ARROW_SIZE);

    if (getValue('beat') != 0)
    {
      var fShift:Float = beatFactor[dim_x] * Math.sin(((fYOffset / (getValue('beatperiod') * 30.0 + 30.0))) + (Math.PI / 2));
      f += getValue('beat') * fShift;
    }

    if (getValue('bumpyx') != 0) f += getValue('bumpyx') * 40 * FlxMath.fastSin(CalculateBumpyAngle(fYOffset, getValue('bumpyxoffset'),
      getValue('bumpyxperiod')));

    if (getValue('tanbumpyx') != 0) f += getValue('tanbumpyx') * 40 * selectTanType(CalculateBumpyAngle(fYOffset, getValue('tanbumpyxoffset'),
      getValue('tanbumpyxperiod')), getValue('cosecant'));

    if (getValue('flip') != 0)
    {
      var iFirstCol:Int = 0;
      var iLastCol:Int = 3;
      var iNewCol:Int = Std.int(ModchartMath.scale(iCol, iFirstCol, iLastCol, iLastCol, iFirstCol));
      var zoom:Int = 1;
      var fOldPixelOffset:Float = xOffset[iCol] * zoom;
      var fNewPixelOffset:Float = xOffset[iNewCol] * zoom;
      var fDistance:Float = fNewPixelOffset - fOldPixelOffset;
      f += fDistance * getValue('flip');
    }

    if (getValue('divide') != 0) f += getValue('divide') * (ARROW_SIZE * (iCol >= 2 ? 1 : -1));

    if (getValue('invert') != 0) f += getValue('invert') * (ARROW_SIZE * ((iCol % 2 == 0) ? 1 : -1));

    if (getValue('zigzag') != 0)
    {
      var fResult:Float = ModchartMath.triangle((Math.PI * (1 / (getValue('zigzagperiod') + 1)) * ((fYOffset +
        (100.0 * (getValue('zigzagoffset')))) / ARROW_SIZE)));

      f += (getValue('zigzag') * ARROW_SIZE / 2) * fResult;
    }

    if (getValue('sawtooth') != 0) f += (getValue('sawtooth') * ARROW_SIZE) * ((0.5 / (getValue('sawtoothperiod') + 1) * fYOffset) / ARROW_SIZE
      - Math.floor((0.5 / (getValue('sawtoothperiod') + 1) * fYOffset) / ARROW_SIZE));

    if (getValue('parabolax') != 0) f += getValue('parabolax') * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE);

    if (getValue('digital') != 0) f += (getValue('digital') * ARROW_SIZE * 0.5) * Math.round((getValue('digitalsteps') +
      1) * FlxMath.fastSin(CalculateDigitalAngle(fYOffset, getValue('digitaloffset'), getValue('digitalperiod')))) / (getValue('digitalsteps')
      + 1);

    if (getValue('tandigital') != 0) f += (getValue('tandigital') * ARROW_SIZE * 0.5) * Math.round((getValue('tandigitalsteps') +
      1) * selectTanType(CalculateDigitalAngle(fYOffset, getValue('tandigitaloffset'), getValue('tandigitalperiod')),
        getValue('cosecant'))) / (getValue('tandigitalsteps')
      + 1);

    if (getValue('square') != 0)
    {
      var fResult:Float = ModchartMath.square((Math.PI * (fYOffset + (1.0 * (getValue('squareoffset')))) / (ARROW_SIZE
        + (getValue('squareperiod') * ARROW_SIZE))));

      f += (getValue('square') * ARROW_SIZE * 0.5) * fResult;
    }

    if (getValue('bounce') != 0)
    {
      var fBounceAmt:Float = Math.abs(FlxMath.fastSin(((fYOffset + (1.0 * (getValue('bounceoffset')))) / (60 + (getValue('bounceperiod') * 60)))));

      f += getValue('bounce') * ARROW_SIZE * 0.5 * fBounceAmt;
    }

    if (getValue('xmode') != 0) f += getValue('xmode') * (pn == 1 ? fYOffset : -fYOffset);

    if (getValue('tiny') != 0)
    {
      // Allow Tiny to pull tracks together, but not to push them apart.
      var fTinyPercent:Float = getValue('tiny');
      fTinyPercent = Math.min(Math.pow(0.5, fTinyPercent), 1.);
      f *= fTinyPercent;
    }

    if (getValue('tipsyx') != 0) f += getValue('tipsyx') * UpdateTipsy(time, getValue('tipsyxoffset'), getValue('tipsyxspeed'), iCol);

    if (getValue('tantipsyx') != 0) f += getValue('tantipsyx') * UpdateTipsy(time, getValue('tantipsyxoffset'), getValue('tantipsyxspeed'), iCol, 1);

    if (getValue('swap') != 0) f += FlxG.width / 2 * getValue('swap') * (pn == 0 ? -1 : 1);

    if (getValue('tornado') != 0)
    {
      var iTornadoWidth:Int = 2;
      var iStartCol:Int = iCol - iTornadoWidth;
      var iEndCol:Int = iCol + iTornadoWidth;
      iStartCol = ModchartMath.iClamp(iStartCol, 0, 3);
      iEndCol = ModchartMath.iClamp(iEndCol, 0, 3);
      var fMinX:Float = 3.402823466e+38;
      var fMaxX:Float = 1.175494351e-38;

      // TODO: Don't index by PlayerNumber.
      for (i in iStartCol...iEndCol + 1)
      {
        fMinX = Math.min(fMinX, xOffset[i]);
        fMaxX = Math.max(fMaxX, xOffset[i]);
      }
      var fRealPixelOffset:Float = xOffset[iCol];
      var fPositionBetween:Float = ModchartMath.scale(fRealPixelOffset, fMinX, fMaxX, -1, 1);
      var fRads:Float = Math.acos(fPositionBetween);
      fRads += (fYOffset + getValue('tornadooffset')) * ((6 * getValue('tornadoperiod')) + 6) / SCREEN_HEIGHT;
      var fAdjustedPixelOffset:Float = ModchartMath.scale(FlxMath.fastCos(fRads), -1, 1, fMinX, fMaxX);

      f += (fAdjustedPixelOffset - fRealPixelOffset) * getValue('tornado');
    }

    if (getValue('tantornado') != 0)
    {
      var iTornadoWidth:Int = 2;
      var iStartCol:Int = iCol - iTornadoWidth;
      var iEndCol:Int = iCol + iTornadoWidth;

      iStartCol = ModchartMath.iClamp(iStartCol, 0, 3);
      iEndCol = ModchartMath.iClamp(iEndCol, 0, 3);
      var fMinX:Float = 3.402823466e+38;
      var fMaxX:Float = 1.175494351e-38;

      // TODO: Don't index by PlayerNumber.
      for (i in iStartCol...iEndCol + 1)
      {
        fMinX = Math.min(fMinX, xOffset[i]);
        fMaxX = Math.max(fMaxX, xOffset[i]);
      }
      var fRealPixelOffset:Float = xOffset[iCol];
      var fPositionBetween:Float = ModchartMath.scale(fRealPixelOffset, fMinX, fMaxX, -1, 1);
      var fRads:Float = Math.acos(fPositionBetween);

      fRads += (fYOffset + getValue('tantornadooffset')) * ((6 * getValue('tantornadoperiod')) + 6) / SCREEN_HEIGHT;
      var fAdjustedPixelOffset:Float = ModchartMath.scale(selectTanType(fRads, getValue('cosecant')), -1, 1, fMinX, fMaxX);
      f += (fAdjustedPixelOffset - fRealPixelOffset) * getValue('tantornado');
    }
    return f;
  }

  public function GetYPos(iCol:Int, fYOffset:Float, pn:Int, xOffset:Array<Float>):Float
  {
    var f:Float = fYOffset;
    var time:Float = (Conductor.instance.songPosition / 1000);

    // XXX: Hack: we need to scale the reverse shift by the zoom.
    var fMiniPercent:Float = getValue('mini');
    var fZoom:Float = 1 - fMiniPercent * 0.5;

    // don't divide by 0
    if (Math.abs(fZoom) < 0.01) fZoom = 0.01;

    var fPercentReverse:Float = GetReversePercentForColumn(iCol);
    var fShift:Float = 514 * fPercentReverse;
    var fPercentCentered:Float = getValue('centered');
    fShift = ModchartMath.scale(fPercentCentered, 0., 1., fShift, 0.0);
    f += fShift;

    f += ARROW_SIZE * getValue('movey$iCol') + getValue('moveyoffset$iCol') + getValue('moveyoffset1$iCol');

    f += ARROW_SIZE * getValue('movey') + getValue('moveyoffset') + getValue('moveyoffset1');

    if (getValue('vibrate') != 0) f += (Math.random() - 0.5) * getValue('vibrate') * 20;

    if (getValue('attenuatey') != 0) f += getValue('attenuatey') * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE) * (xOffset[iCol] / ARROW_SIZE);

    if (getValue('tipsy') != 0) f += getValue('tipsy') * UpdateTipsy(time, getValue('tipsyoffset'), getValue('tipsyspeed'), iCol);

    if (getValue('tantipsy') != 0) f += getValue('tantipsy') * UpdateTipsy(time, getValue('tantipsyoffset'), getValue('tantipsyspeed'), iCol, 1);

    if (getValue('beaty') != 0) f += getValue('beaty') * (beatFactor[dim_y] * FlxMath.fastSin(fYOffset / ((getValue('beatyperiod') * 15) + 15) + Math.PI / 2));

    if (getValue('drunky') != 0) f += getValue('drunky') * FlxMath.fastCos(CalculateDrunkAngle(time, getValue('drunkyspeed'), iCol, getValue('drunkyoffset'),
      0.2, fYOffset, getValue('drunkyperiod'), 10)) * ARROW_SIZE * 0.5;

    if (getValue('tandrunk') != 0) f += getValue('tandrunky') * selectTanType(CalculateDrunkAngle(time, getValue('tandrunkyspeed'), iCol,
      getValue('tandrunkyoffset'), 0.2, fYOffset, getValue('tandrunkyperiod'), 10),
      getValue('cosecant')) * ARROW_SIZE * 0.5;

    if (getValue('bouncey') != 0)
    {
      var fBounceAmt:Float = Math.abs(FlxMath.fastSin(((fYOffset + (1.0 * (getValue('bounceyoffset')))) / (60 + (getValue('bounceyperiod') * 60)))));

      f += getValue('bouncey') * ARROW_SIZE * 0.5 * fBounceAmt;
    }

    if (getValue('bumpyy') != 0) f += getValue('bumpyy') * 40 * FlxMath.fastSin(CalculateBumpyAngle(fYOffset, getValue('bumpyyoffset'),
      getValue('bumpyyperiod')));

    if (getValue('tanbumpyy') != 0) f += getValue('tanbumpyy') * 40 * selectTanType(CalculateBumpyAngle(fYOffset, getValue('tanbumpyyoffset'),
      getValue('tanbumpyyperiod')), getValue('cosecant'));

    if (getValue('tornadoy') != 0)
    {
      var iTornadoWidth:Int = 2;
      var iStartCol:Int = iCol - iTornadoWidth;
      var iEndCol:Int = iCol + iTornadoWidth;
      iStartCol = ModchartMath.iClamp(iStartCol, 0, 3);
      iEndCol = ModchartMath.iClamp(iEndCol, 0, 3);

      var fMinX:Float = 3.402823466e+38;
      var fMaxX:Float = 1.175494351e-38;
      // TODO: Don't index by PlayerNumber.

      for (i in iStartCol...iEndCol + 1)
      {
        fMinX = Math.min(fMinX, xOffset[i]);
        fMaxX = Math.max(fMaxX, xOffset[i]);
      }

      var fRealPixelOffset:Float = xOffset[iCol];
      var fPositionBetween:Float = ModchartMath.scale(fRealPixelOffset, fMinX, fMaxX, -1, 1);
      var fRads:Float = Math.acos(fPositionBetween);
      fRads += (fYOffset + getValue('tornadoyoffset')) * ((6 * getValue('tornadoyperiod')) + 6) / SCREEN_HEIGHT;

      var fAdjustedPixelOffset:Float = ModchartMath.scale(FlxMath.fastCos(fRads), -1, 1, fMinX, fMaxX);

      f += (fAdjustedPixelOffset - fRealPixelOffset) * getValue('tornadoy');
    }

    if (getValue('tantornadoy') != 0)
    {
      var iTornadoWidth:Int = 2;
      var iStartCol:Int = iCol - iTornadoWidth;
      var iEndCol:Int = iCol + iTornadoWidth;
      iStartCol = ModchartMath.iClamp(iStartCol, 0, 3);
      iEndCol = ModchartMath.iClamp(iEndCol, 0, 3);

      var fMinX:Float = 3.402823466e+38;
      var fMaxX:Float = 1.175494351e-38;

      // TODO: Don't index by PlayerNumber.

      for (i in iStartCol...iEndCol + 1)
      {
        fMinX = Math.min(fMinX, xOffset[i]);
        fMaxX = Math.max(fMaxX, xOffset[i]);
      }

      var fRealPixelOffset:Float = xOffset[iCol];
      var fPositionBetween:Float = ModchartMath.scale(fRealPixelOffset, fMinX, fMaxX, -1, 1);
      var fRads:Float = Math.acos(fPositionBetween);
      fRads += (fYOffset + getValue('tantornadoyoffset')) * ((6 * getValue('tantornadoyperiod')) + 6) / SCREEN_HEIGHT;

      var fAdjustedPixelOffset:Float = ModchartMath.scale(selectTanType(fRads, getValue('cosecant')), -1, 1, fMinX, fMaxX);

      f += (fAdjustedPixelOffset - fRealPixelOffset) * getValue('tantornadoy');
    }
    return f;
  }

  public function GetZPos(iCol:Int, fYOffset:Float, pn:Int, xOffset:Array<Float>):Float
  {
    var f:Float = 0;
    var time:Float = (Conductor.instance.songPosition / 1000);
    f += ARROW_SIZE * getValue('movez$iCol') + getValue('movezoffset$iCol') + getValue('movezoffset1$iCol');

    f += ARROW_SIZE * getValue('movez') + getValue('movezoffset') + getValue('movezoffset1');

    if (getValue('tornadoz') != 0)
    {
      var iTornadoWidth:Int = 2;
      var iStartCol:Int = iCol - iTornadoWidth;
      var iEndCol:Int = iCol + iTornadoWidth;
      iStartCol = ModchartMath.iClamp(iStartCol, 0, 3);
      iEndCol = ModchartMath.iClamp(iEndCol, 0, 3);

      var fMinX:Float = 3.402823466e+38;
      var fMaxX:Float = 1.175494351e-38;
      // TODO: Don't index by PlayerNumber.

      for (i in iStartCol...iEndCol + 1)
      {
        fMinX = Math.min(fMinX, xOffset[i]);
        fMaxX = Math.max(fMaxX, xOffset[i]);
      }

      var fRealPixelOffset:Float = xOffset[iCol];
      var fPositionBetween:Float = ModchartMath.scale(fRealPixelOffset, fMinX, fMaxX, -1, 1);
      var fRads:Float = Math.acos(fPositionBetween);
      fRads += (fYOffset + getValue('tornadozoffset')) * ((6 * getValue('tornadozperiod')) + 6) / SCREEN_HEIGHT;

      var fAdjustedPixelOffset:Float = ModchartMath.scale(FlxMath.fastCos(fRads), -1, 1, fMinX, fMaxX);

      f += (fAdjustedPixelOffset - fRealPixelOffset) * getValue('tornadoz');
    }

    if (getValue('tantornadoz') != 0)
    {
      var iTornadoWidth:Int = 2;
      var iStartCol:Int = iCol - iTornadoWidth;
      var iEndCol:Int = iCol + iTornadoWidth;
      iStartCol = ModchartMath.iClamp(iStartCol, 0, 3);
      iEndCol = ModchartMath.iClamp(iEndCol, 0, 3);

      var fMinX:Float = 3.402823466e+38;
      var fMaxX:Float = 1.175494351e-38;

      // TODO: Don't index by PlayerNumber.

      for (i in iStartCol...iEndCol + 1)
      {
        fMinX = Math.min(fMinX, xOffset[i]);
        fMaxX = Math.max(fMaxX, xOffset[i]);
      }

      var fRealPixelOffset:Float = xOffset[iCol];
      var fPositionBetween:Float = ModchartMath.scale(fRealPixelOffset, fMinX, fMaxX, -1, 1);
      var fRads:Float = Math.acos(fPositionBetween);
      fRads += (fYOffset + getValue('tantornadozoffset')) * ((6 * getValue('tantornadozperiod')) + 6) / SCREEN_HEIGHT;

      var fAdjustedPixelOffset:Float = ModchartMath.scale(selectTanType(fRads, getValue('cosecant')), -1, 1, fMinX, fMaxX);

      f += (fAdjustedPixelOffset - fRealPixelOffset) * getValue('tantornadoz');
    }

    if (getValue('drunkz') != 0) f += getValue('drunkz') * FlxMath.fastCos(CalculateDrunkAngle(time, getValue('drunkzspeed'), iCol, getValue('drunkzoffset'),
      0.2, fYOffset, getValue('drunkzperiod'), 10)) * ARROW_SIZE * 0.5;

    if (getValue('tandrunkz') != 0) f += getValue('tandrunkz') * selectTanType(CalculateDrunkAngle(time, getValue('tandrunkzspeed'), iCol,
      getValue('tandrunkzoffset'), 0.2, fYOffset, getValue('tandrunkzperiod'), 10),
      getValue('cosecant')) * ARROW_SIZE * 0.5;

    if (getValue('bouncez') != 0)
    {
      var fBounceAmt:Float = Math.abs(FlxMath.fastSin(((fYOffset + (1.0 * (getValue('bouncezoffset')))) / (60 + (getValue('bouncezperiod') * 60)))));

      f += getValue('bouncez') * ARROW_SIZE * 0.5 * fBounceAmt;
    }

    if (getValue('bumpy') != 0) f += getValue('bumpy') * 40 * FlxMath.fastSin(CalculateBumpyAngle(fYOffset, getValue('bumpyoffset'), getValue('bumpyperiod')));

    if (getValue('tanbumpy') != 0) f += getValue('tanbumpy') * 40 * selectTanType(CalculateBumpyAngle(fYOffset, getValue('tanbumpyoffset'),
      getValue('tanbumpyperiod')), getValue('cosecant'));

    if (getValue('bumpy$iCol') != 0) f += getValue('bumpy$iCol') * 40 * FlxMath.fastSin(CalculateBumpyAngle(fYOffset, getValue('bumpyoffset'),
      getValue('bumpyperiod')));

    if (getValue('beatz') != 0) f += getValue('beatz') * (beatFactor[dim_x] * FlxMath.fastSin(fYOffset / ((getValue('beatzperiod') * 15) + 15) + Math.PI / 2));

    if (getValue('digitalz') != 0) f += (getValue('digitalz') * ARROW_SIZE * 0.5) * Math.round((getValue('digitalzsteps') +
      1) * FlxMath.fastSin(CalculateDigitalAngle(fYOffset, getValue('digitalzoffset'), getValue('digitalzperiod')))) / (getValue('digitalzsteps')
      + 1);

    if (getValue('tandigitalz') != 0) f += (getValue('tandigitalz') * ARROW_SIZE * 0.5) * Math.round((getValue('tandigitalzsteps') +
      1) * selectTanType(CalculateDigitalAngle(fYOffset, getValue('tandigitalzoffset'), getValue('tandigitalzperiod')),
      getValue('cosecant'))) / (getValue('tandigitalzsteps') + 1);

    if (getValue('zigzagz') != 0)
    {
      var fResult:Float = ModchartMath.triangle((Math.PI * (1 / (getValue('zigzagzperiod') + 1)) * ((fYOffset +
        (100.0 * (getValue('zigzagzoffset')))) / ARROW_SIZE)));

      f += (getValue('zigzagz') * ARROW_SIZE / 2) * fResult;
    }

    if (getValue('sawtoothz') != 0) f += (getValue('sawtoothz') * ARROW_SIZE) * ((0.5 / (getValue('sawtoothzperiod') + 1) * fYOffset) / ARROW_SIZE
      - Math.floor((0.5 / (getValue('sawtoothperiod') + 1) * fYOffset) / ARROW_SIZE));

    if (getValue('squarez') != 0)
    {
      var fResult:Float = ModchartMath.square((Math.PI * (fYOffset + (1.0 * (getValue('squarezoffset')))) / (ARROW_SIZE
        + (getValue('squarezperiod') * ARROW_SIZE))));

      f += (getValue('squarez') * ARROW_SIZE * 0.5) * fResult;
    }

    if (getValue('parabolaz') != 0) f += getValue('parabolaz') * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE);

    if (getValue('attenuatez') != 0) f += getValue('attenuatez') * (fYOffset / ARROW_SIZE) * (fYOffset / ARROW_SIZE) * (xOffset[iCol] / ARROW_SIZE);

    if (getValue('tipsyz') != 0) f += getValue('tipsyz') * UpdateTipsy(time, getValue('tipsyzoffset'), getValue('tipsyzspeed'), iCol);

    if (getValue('tantipsyz') != 0) f += getValue('tantipsyz') * UpdateTipsy(time, getValue('tantipsyzoffset'), getValue('tantipsyzspeed'), iCol, 1);

    return f;
  }

  public function GetRotationZ(iCol:Int, fYOffset:Float, noteBeat:Float, xPos:Float):Float
  {
    var fRotation:Float = 0;
    if (getValue('confusion') != 0 || getValue('confusionoffset') != 0 || getValue('confusion$iCol') != 0 || getValue('confusionoffset$iCol') != 0)
      fRotation += ReceptorGetRotationZ(iCol, xPos);

    // As usual, enable dizzy hold heads at your own risk. -Wolfman2000
    if (getValue('dizzy') != 0)
    {
      var fSongBeat:Float = Conductor.instance.currentBeatTime;
      var fDizzyRotation = noteBeat - fSongBeat;
      fDizzyRotation *= getValue('dizzy');
      fDizzyRotation = ModchartMath.mod(fDizzyRotation, 2 * Math.PI);
      fDizzyRotation *= 180 / Math.PI;
      fRotation += fDizzyRotation;
    }
    return fRotation;
  }

  public function GetRotationX(iCol:Int, fYOffset:Float):Float
  {
    var fRotation:Float = 0;
    if (getValue('confusionx') != 0 || getValue('confusionxoffset') != 0 || getValue('confusionx$iCol') != 0 || getValue('confusionxoffset$iCol') != 0)
      fRotation += ReceptorGetRotationX(iCol);

    if (getValue('roll') != 0)
    {
      fRotation += getValue('roll') * fYOffset / 2;
    }
    return fRotation;
  }

  public function GetRotationY(iCol:Int, fYOffset:Float):Float
  {
    var fRotation:Float = 0;
    if (getValue('confusiony') != 0 || getValue('confusionyoffset') != 0 || getValue('confusiony$iCol') != 0 || getValue('confusionyoffset$iCol') != 0)
      fRotation += ReceptorGetRotationY(iCol);
    if (getValue('twirl') != 0)
    {
      fRotation += getValue('twirl') * fYOffset / 2;
    }
    return fRotation;
  }

  public function ReceptorGetRotationZ(iCol:Int, xPos:Float):Float
  {
    var fRotation:Float = 0;
    var beat:Float = Conductor.instance.currentBeatTime;
    if (getValue('confusion$iCol') != 0) fRotation += getValue('confusion$iCol') * 180.0 / Math.PI;

    if (getValue('confusionoffset') != 0) fRotation += getValue('confusionoffset') * 180.0 / Math.PI;

    if (getValue('confusionoffset$iCol') != 0) fRotation += getValue('confusionoffset$iCol') * 180.0 / Math.PI;

    if (getValue('confusion') != 0)
    {
      var fConfRotation:Float = beat;
      fConfRotation *= getValue('confusion');
      fConfRotation %= 2 * Math.PI;
      fConfRotation *= -180 / Math.PI;
      fRotation += fConfRotation;
    }

    if (getValue('orient') != 0) fRotation += xPos;
    return fRotation;
  }

  public function ReceptorGetRotationX(iCol:Int):Float
  {
    var fRotation:Float = 0;
    var beat:Float = Conductor.instance.currentBeatTime;
    if (getValue('confusionx$iCol') != 0) fRotation += getValue('confusionx$iCol') * 180.0 / Math.PI;

    if (getValue('confusionxoffset') != 0) fRotation += getValue('confusionxoffset') * 180.0 / Math.PI;

    if (getValue('confusionxoffset$iCol') != 0) fRotation += getValue('confusionxoffset$iCol') * 180.0 / Math.PI;

    if (getValue('confusionx') != 0)
    {
      var fConfRotation:Float = beat;
      fConfRotation *= getValue('confusionx');
      fConfRotation = ModchartMath.mod(fConfRotation, 2 * Math.PI);
      fConfRotation *= -180 / Math.PI;
      fRotation += fConfRotation;
    }
    return fRotation;
  }

  public function GetCameraEffects()
  {
    var x:Float = getValue('camx');
    var y:Float = getValue('camy');
    var z:Float = getValue('camz');
    var skewx:Float = getValue('skewx');
    var skewy:Float = getValue('skewy');
    return [x, y, z, skewx, skewy];
  }

  public function ReceptorGetRotationY(iCol:Int):Float
  {
    var fRotation:Float = 0;
    var beat:Float = Conductor.instance.currentBeatTime;
    if (getValue('confusiony$iCol') != 0) fRotation += getValue('confusiony$iCol') * 180.0 / Math.PI;

    if (getValue('confusionyoffset') != 0) fRotation += getValue('confusionyoffset') * 180.0 / Math.PI;

    if (getValue('confusionyoffset$iCol') != 0) fRotation += getValue('confusionyoffset$iCol') * 180.0 / Math.PI;

    if (getValue('confusiony') != 0)
    {
      var fConfRotation:Float = beat;
      fConfRotation *= getValue('confusiony');
      fConfRotation = ModchartMath.mod(fConfRotation, 2 * Math.PI);
      fConfRotation *= -180 / Math.PI;
      fRotation += fConfRotation;
    }

    return fRotation;
  }

  public function GetScale(iCol:Int, fYOffset:Float, pn:Int, defaultScale:Array<Float>):Array<Float>
  {
    var x:Float = defaultScale[0];
    var y:Float = defaultScale[1];

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
    x *= Math.pow(0.5, getValue('tinyx'));
    x *= Math.pow(0.5, getValue('tinyx$iCol'));
    y *= Math.pow(0.5, getValue('tinyy'));
    y *= Math.pow(0.5, getValue('tinyy$iCol'));
    var skewx:Float = getValue('noteskewx') + getValue('noteskewx$iCol');
    var skewy:Float = getValue('noteskewy') + getValue('noteskewy$iCol');
    skewx *= 50;
    skewy *= 50;
    return [x, y, skewx, skewy];
  }

  public function GetZoom(iCol:Int, fYOffset:Float, pn:Int):Float
  {
    var fZoom:Float = 1.0;
    // Design change:  Instead of having a flag in the style that toggles a
    // fixed zoom (0.6) that is only applied to the columns, ScreenGameplay now
    // calculates a zoom factor to apply to the notefield and puts it in the
    // PlayerState. -Kyz
    var fPulseInner:Float = 1.0;

    if (getValue('pulseinner') != 0 || getValue('pulseouter') != 0)
    {
      fPulseInner = ((getValue('pulseinner') * 0.5) + 1);
      if (fPulseInner == 0) fPulseInner = 0.01;
    }

    if (getValue('pulseinner') != 0 || getValue('pulseouter') != 0)
    {
      var sine:Float = FlxMath.fastSin(((fYOffset + (100.0 * (getValue('pulseoffset')))) / (0.4 * (ARROW_SIZE + (getValue('pulseperiod') * ARROW_SIZE)))));

      fZoom *= (sine * (getValue('pulseouter') * 0.5)) + fPulseInner;
    }

    if (getValue('shrinkmult') != 0 && fYOffset >= 0) fZoom *= 1 / (1 + (fYOffset * (getValue('shrinkmult') / 100.0)));

    if (getValue('shrinklinear') != 0 && fYOffset >= 0) fZoom += fYOffset * (0.5 * getValue('shrinklinear') / ARROW_SIZE);

    if (getValue('tiny') != 0)
    {
      var fTinyPercent = getValue('tiny');
      fTinyPercent = Math.pow(0.5, fTinyPercent);
      fZoom *= fTinyPercent;
    }
    if (getValue('tiny$iCol') != 0)
    {
      var fTinyPercent = Math.pow(0.5, getValue('tiny$iCol'));
      fZoom *= fTinyPercent;
    }
    fZoom *= getValue('zoom');
    fZoom *= getValue('zoom$iCol');
    return fZoom;
  }

  function GetMultScrollSpeed()
  {
    // it's fake, i can't do scroll bpm
    var speed:Float = 1;
    var xmod:Float = getValue('xmod');
    var cmod:Float = getValue('cmod');
    var mmod:Float = getValue('mmod');
    speed *= xmod;
    if (cmod >= 0) speed = cmod;
    if (speed > mmod) speed = mmod;
    return speed;
  }

  public function new():Void {}
}

/*
  idk it should be working
  default vals:
  BlinkModFrequency=0.3333
 */
