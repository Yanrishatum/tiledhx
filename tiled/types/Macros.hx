package tiled.types;

  
#if macro
import haxe.macro.Compiler;
import haxe.macro.Type;
import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.Tools;

class Macros {
  
  static var dataFields:Map<String, Map<String, String>> = [];

  static function buildExtraFields() {
    var id = Context.getLocalClass().get().name;
    var df = dataFields.get(id);
    if (df == null || Lambda.count(df) == 0) return null;
    
    var fields = Context.getBuildFields();
    for (k => v in df) {
      fields.push({
        name: k,
        access: [Access.APublic],
        kind: FieldType.FVar(Context.toComplexType(Context.getType(v))),
        pos: Context.currentPos()
      });
    }
    return fields;
  }
  
  public static function addObjectData(name:String, type:String) {
    var df = dataFields["TmxObject"];
    if (df == null) df = dataFields["TmxObject"] = new Map();
    df[name] = type;
  }
  
  public static function addTilesetData(name:String, type:String) {
    var df = dataFields["TmxTileset"];
    if (df == null) df = dataFields["TmxTileset"] = new Map();
    df[name] = type;
  }
  
  public static function addLayerData(name:String, type:String) {
    var df = dataFields["TmxLayer"];
    if (df == null) df = dataFields["TmxLayer"] = new Map();
    df[name] = type;
  }
  
  public static function addMapData(name:String, type:String) {
    var df = dataFields["TmxMap"];
    if (df == null) df = dataFields["TmxMap"] = new Map();
    df[name] = type;
  }
  
}
#end