package funkin.play;

import funkin.play.notes.Strumline;

class ModScripting
{
  var game = PlayState.instance;

  public function new()
  {
    trace('you can already use the mod scripting functions');
  }

  function ex(name:String)
    return game.playerStrumline.mods.exist(name) && game.opponentStrumline.mods.exist(name);

  public function defineMod(name:String, val:Float)
  {
    if (!ex(name))
    {
      game.playerStrumline.mods.modList.set(name, val);
      game.opponentStrumline.mods.modList.set(name, val);
    }
  }

  public function beatCallback(beat:Float, func) {}

  public function stepCallback(step:Float, func) {}

  public function modPerframe(beat:Float, endBeat:Float, func:(Float) -> Void) {}

  public function modEase() {}

  public function stepEase() {}

  public function beatSet() {}

  public function stepSet() {}

  public function set(name:String, val:Float, pn:Int = -1)
  {
    if (ex(name)) fromPN(pn, (a:Strumline) -> {
      a.mods.modList.set(a.mods.getRealName(name), val);
    });
  }

  function fromPN(pn:Int, command:(Strumline) -> Void)
  {
    switch (pn)
    {
      case 0:
        command(game.playerStrumline);
      case 1:
        command(game.opponentStrumline);
      case -1:
        command(game.playerStrumline);
        command(game.opponentStrumline);
    }
  }
}
