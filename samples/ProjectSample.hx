package ;

import tiled.project.TiledClass;
import tiled.types.TmxTileset.TmxTile;
import tiled.types.*;

// This is an example of both generating the project file and using `project` mode.

class ProjectSample {
  
  function load(map: TmxMap) {
    for (obj in map.objects) {
      // The `map.objects` index can contain null gaps
      if (obj == null) continue;
      // isA / as and to are just wrappers for `Std.isOfType`, `Std.downcast` and `cast`.
      if (obj.tclass.isA(MyTiledClass)) {
        var cl = obj.tclass.as(MyTiledClass);
        // If your class extends some in-game entity,
        // you can finalize the object initialization and add it to scene right away
        // or process the TmxObject however you ned.
        trace(cl.string);
      }
    }
  }
  
}
// Implementing it as a TiledClass will allow it to be exposed for Tiled.
// Make sure to do a macro call of
// --macro tiled.project.TiledProject.generateProject
// in order to update the project file.
// Additionally, this macro call will not update project file for `display`,
// meaning you have to actually compile with it.
class MyTiledClass implements TiledClass {
  
  // This will alow applying this class to objects and tiles
  // Because this class has `initX` methods, using `@:useAs` will take no effect.
  static function initObject(obj: TmxObject): MyTiledClass {
    return new MyTiledClass();
  }
  static function initTile(tile: TmxTile): MyTiledClass {
    return new MyTiledClass();
  }
  
  function new() {}
  
  // Things to keep in mind:
  // If you don't set default value in Haxe, then on loading it will _not_ set the default value,
  // meaning that for non-static languages you may end up with a `null` on primitive types.
  
  // Will have a string type in Tiled and default value of "hello"
  @:tvar public var string: String = "hello";
  // Will have a file type in Tiled and default value of "world.gif"
  @:tvar(file) public var file: String = "world.gif";
  // Will have a color type in Tiled and default value of red color.
  @:tvar(color) public var color: String = "#ff0000ff";
  // Alternatively color can be parsed as an integer.
  @:tvar(color) public var intColor: Int = 0xffff0000;
  // Will have a bool type and default value of false.
  @:tvar public var bool: Bool;
  // Will have a float type and default value of 0.0.
  @:tvar public var float: Float;
  // Will have an int type in Tiled, despite being parsed as a float.
  @:tvar public var intyFloat: Float = 10;
  // Will have an int type and default value of 0.
  @:tvar public var int: Int;
  // Will have an object reference type.
  @:tvar(object) public var object: Int;
  // Will have an object reference type and loaded as an actual object during map parsing.
  @:tvar public var objectRef: TmxObject;
  // var objectRefID: Int; // <- This variable will be created to store the object ID during loading for secondary pass.
  
  // This variable will NOT be exposed to Tiled!
  // However it WILL be loaded in project mode if it's being present.
  @:tvar(optional) public var optional: Int;
  
  // Will be exposed as an integer enum with a default value being B.
  @:tvar public var myIntEnum: MyEnum = EnumValueB;
  // Will be exposed as a string enum. In order to avoid name conflicts it will have the name postfix of `_s`.
  @:tvar(string) public var myStringEnum: MyEnum;
  // Will be exposed as an integer enum flags, letting you pick multiple values at once.
  // To avoid name conflicts it'll have name postfix of `_f`.
  @:tvar public var myIntFlags: haxe.EnumFlags<MyEnum>;
  // Will be exposed as a string enum flags. Will have postifx of `_fs`.
  @:tvar public var myStringFlags: Array<MyEnum>;
  
  // Will be exposed as a sub-class.
  // Make sure it does support property usage.
  @:tvar public var subClass: MySubClass = new MySubClass();
  // If you do not instantiate the TiledClass, it may be null if whatever using this class
  // does not alter any default values in this subclass.
  // Make sure to check for null in that case.
  @:tvar public var subClassNullable: MySubClass;
}

// You can't directly expose enums in current version, however they are automatically exposed if
// they are used for a TiledClass instances.
enum MyEnum {
  EnumValueA;
  EnumValueB;
  EnumValueC;
}

// 
@:useAs(property)
// Overrides the class name. In Tiled its name will be `xyPoint` instead of `MySubClass`.
@:tname("xyPoint")
class MySubClass implements TiledClass {
  
  // It's important that constructor either takes no arguments
  // or only ?optional arguments
  // Otherwise `@:useAs` meta will take no effect.
  public function new() {}
  
  // Both will be exposed as `offsetX` and `offsetY` properties for Tiled.
  // This can be useful when your TiledClass extends some other class and
  // properties you expose have conflicting names.
  // E.g. if you extend some visible object, it likely has a variable `x`,
  // and if you want to expose tiled variable `x`, you'd use the `@:tname` meta and a different field name in Haxe.
  @:tvar @:tname(offsetX) public var x: Int = 0;
  // You can use either ident or a string when declaring names
  // This also applies for `@:tvar` type hints and `@:useAs`.
  @:tvar @:tname("offsetY") public var y: Int = 0;
  
}

// This class will be applicable only to layers since constructor takes it and no `initX` is declared.
class LayerOnly implements TiledClass {
  public function new(layer: TmxLayer) {}
}

// This class will be applicable both for object and tile
// Use as is usable, because all constructor arguments are optional and auto-generated initTile passes none.
// While `initObject` will pass the underlying TmxObject to the constructor.
// This is useful when you want to use the tile as an intermediary before placing it as an object.
@:useAs(tile)
// Note that @:useAs below will produce a compiler warning, because `object` is already exposed by the constructor.
// @:useAs(tile, object)
class ObjectAndTileOnly implements TiledClass {
  public function new(?obj: TmxObject) {}
}

// TODO: Make it a more practical sample that includes TMX files and such.