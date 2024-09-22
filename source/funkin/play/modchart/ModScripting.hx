package funkin.play.modchart;

import funkin.play.notes.Strumline;
import openfl.geom.Vector3D;

// a scrapped stuff, will be removed in the further update
class ModScripting
{
  var game = PlayState.instance;
  var util:ModTools = new ModTools();

  public function new():Void {}

  public function setValue(name:String, val:Float, ?pn:Int)
  {
    util.fromPN(pn, (a:Strumline) -> {
      a.mods.setValue(name, val);
    });
  }
}

class ModTools
{
  var game = PlayState.instance;

  public function new() {};

  public function fromPN(pn:Int, command:(Strumline) -> Void)
  {
    if (pn == 2) command(game.playerStrumline);
    else if (pn == 1) command(game.opponentStrumline);
    else
    {
      command(game.playerStrumline);
      command(game.opponentStrumline);
    }
  }
}
