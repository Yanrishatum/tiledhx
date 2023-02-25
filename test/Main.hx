package ;

import hxd.Key;
import hxd.res.Resource;
import h2d.Text;
import h2d.Graphics;
import h2d.Object;
import tiled.types.TmxMap;
import tiled.Tiled;
import h2d.Bitmap;
import h2d.TileGroup;
import hxd.Res;
import tiled.types.Properties;
import tiled.types.TmxObject;
import hxd.App;
import haxe.EnumFlags;

using tiled.TiledTools;

class Main extends App {
  
  var loader: Tiled = new Tiled();
  
  var maps: Array<Resource>;
  var current: Resource;
  
  static function main() {
    Res.initLocal();
    new Main();
  }
  
  override function init()
  {
    super.init();
    maps = [
      Res.tiled.desert_tmx,
      Res.tiled.hexagonal_mini,
      Res.tiled.isometric_grass_and_water_tmx,
      Res.tiled.orthogonal_outside,
      Res.tiled.perspective_walls_tmx,
      Res.tiled.sewers,
      // Res.tiled.sewer_automap.sewers,
      Res.tiled.sticker_knight.map.sandbox,
      Res.tiled.sticker_knight.map.sandbox2,
    ];
    disp(maps[0]);
  }
  
  override function update(dt:Float) {
    super.update(dt);
    if (Key.isReleased(Key.SPACE)) {
      var idx = maps.indexOf(current)+1;
      disp(maps[idx%maps.length]);
    }
  }
  
  function disp(res: Resource) {
    s2d.removeChildren();
    current = res;
    var m = loader.loadTMXResource(res);
    m.realignObjects(TopLeft); // By default Tiled aligns by bottom-left/bottom-center.
    for (l in m.flatIterator()) {
      switch (l.kind) {
        case TTileLayer:
          var layer = new TilemapLayer(m, l, s2d);
        case TObjectGroup:
          for (o in l.objects) {
            var obj: Object;
            switch (o.kind) {
              case TTile:
                var t = m.tilesets.getImage(o.gid);
                var b = new Bitmap(t, s2d);
                b.width = o.width;
                b.height = o.height;
                obj = b;
              case TPolygon:
                var g = new Graphics(s2d);
                g.beginFill(0xff0000);
                for (pt in o.vertices) g.lineTo(pt.x, pt.y);
                g.endFill();
                obj = g;
              case TPolyline:
                var g = new Graphics(s2d);
                g.lineStyle(1, 0x0000ff);
                for (pt in o.vertices) g.lineTo(pt.x, pt.y);
                // @:privateAccess g.flush();
                obj = g;
              case TPoint:
                var g = new Graphics(s2d);
                g.beginFill(0xff00ff);
                g.drawCircle(0, 0, 5);
                g.endFill();
                obj = g;
              case TEllipse:
                var g = new Graphics(s2d);
                g.beginFill(0xff00ff);
                g.drawEllipse(0, 0, o.width/2, o.height/2);
                g.endFill();
                obj = g;
              case TRectangle:
                var g = new Graphics(s2d);
                g.beginFill(0x00ff00);
                g.drawRect(0, 0, o.width, o.height);
                g.endFill();
                obj = g;
              case TText:
                var txt = new Text(hxd.res.DefaultFont.get(), s2d);
                txt.textAlign = switch (o.text.halign) {
                  case ALeft: Left;
                  case ARight: Right;
                  case ACenter: Center;
                  default: Left;
                }
                txt.textColor = o.text.color;
                txt.text = o.text.text;
                if (o.text.wrap) txt.maxWidth = o.width;
                obj = txt;
            }
            obj.rotation = o.rotation;
            obj.setPosition(o.x, o.y);
          }
        case TImageLayer:
        case TGroup:
      }
    }
    var b = s2d.getBounds();
    var scale = Math.min(s2d.width / b.width, s2d.height / b.height);
    s2d.camera.setAnchor(0.5, 0.5);
    var center = b.getCenter();
    s2d.camera.setPosition(center.x, center.y);
    s2d.camera.setScale(scale, scale);
  }
  
}

class InstProps implements tiled.project.TiledClass {
  public inline function new(obj: tiled.types.TmxObject) {
    
  }
  
  // static function initObject(obj: tiled.types.TmxObject) {
  //   return new InstProps(obj);
  // }
  @:tvar var str: String;
  @:tvar(file) var file: String;
  @:tvar(color) var color: String;
  @:tvar var ival: Int;
  @:tvar(color) var icolor: Int;
  @:tvar(object) var iobj: Int;
  @:tvar var float: Float;
  @:tvar(int) var ifloat: Float;
  @:tvar var ref:tiled.types.TmxObject;
  @:tvar var arr: Array<tiled.types.TmxObject>;
  @:tvar var bool: Bool;
  @:tvar var subClass: SubInst;
  @:tvar var ienum: TestEnum;
  @:tvar(string) var senum: TestEnum;
  @:tvar var ienumFlags: EnumFlags<TestEnum>;
  @:tvar(string) var senumFlags: EnumFlags<TestEnum>;
  @:tvar var senumArray: Array<TestEnum>;
  @:tvar(int) var ienumArray: Array<TestEnum>;
}

class SubInst implements tiled.project.TiledClass {
  @:tvar var x: Float;
  @:tvar var y: Float;
  
  public function new(other: tiled.project.TiledClass) {
    
  }
}

enum TestEnum {
  ValueA;
  ValueB;
  ValueC;
}

typedef TestProps = {
  var ref:TmxObject;
  @:tcolor var col:Int;
  @:tfile var file:String;
  var str:String;
  var intval:Int;
  var floatval:Float;
  var bool:Bool;
}