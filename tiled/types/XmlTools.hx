package tiled.types;

import haxe.io.Path;

/**
  Helper class to work with Tiled XML
**/
class XmlTools {
  
  /** Get attribute `name` if it exists or `def` otherwise. **/
  public static inline function att(x:Xml, name:String, def:String = '') return x.exists(name) ? x.get(name) : def;
  /** Get attribute `name` as Int if it exists or `def` otherwise. **/
  public static inline function iatt(x:Xml, name:String, def:Int = 0) return x.exists(name) ? Std.parseInt(x.get(name)) : def;
  /** Get attribute `name` as Float if it exists or `def` otherwise. **/
  public static inline function fatt(x:Xml, name:String, def:Float = 0) return x.exists(name) ? Std.parseFloat(x.get(name)) : def;
  /**
    Get attribute `name` as Bool if it exists or `def` otherwise.
    Value considered `true` when it's either a string `true` (case-insensitive) or `1`.
  **/
  public static inline function batt(x:Xml, name:String, def:Bool = false) {
    if (x.exists(name)) {
      var v = x.get(name);
      return v.toLowerCase() == 'true' || v == '1';
    } else return def;
  }
  
  public static inline function typeatt(x: Xml, def: String = "") {
    return x.exists('class') ? x.get('class') : (x.exists('type') ? x.get('type') : def);
  }
  
  /** Get attribute `name` as color Int if it exists or `def` otherwise. **/
  public static inline function catt(x:Xml, name:String, def:Int = 0, fillAlpha:Int = 0xff) {
    return parseColor(x.get(name), def, fillAlpha);
  }
  
  /**
    Parses a `#`-prefixed color.
  **/
  public static function parseColor(s: String, def: Int = 0, fillAlpha: Int = 0xff) {
    if (s == null) return def;
    if (s.charCodeAt(0) == '#'.code) s = s.substr(1);
    
    if (s.length == 6) return Std.parseInt('0x' + s) | (fillAlpha<<24);
    else return Std.parseInt('0x' + s);
  }
  
  /**
    Find and load `properties` child node into `props`.
  **/
  public static inline function loadProps(x:Xml, props:Properties, loader: Tiled) {
    for (el in x) if (el.nodeType == Element && el.nodeName == 'properties') props.loadXML(el, loader);
  }
  
  /**
    Normalized the `path` relative to the `relativeTo` file.
  **/
  public static inline function normalizePath(path:String, relativeTo:String):String {
    return relativeTo != null ? Path.join([Path.directory(relativeTo), path]) : Path.normalize(path);
  }
  
  /**
    Parses a uint written in decimal by parsing it as an Int64.
    The Int64 parse happens only for strings of length 10, as to not go the slow path every time for non-flipped tiles.
    
    Specifically used for tile IDs, as Tiled uses high bits as flip flags,
    which in turn writes value as an unparseable uint for most Haxe targets if used with `Std.parseInt`.
  **/
  public static inline function parseUint(val:String):Int {
    return if (val.length == 10) haxe.Int64.parseString(val).low; //Std.int(Std.parseFloat(val));
    else Std.parseInt(val);
  }
}
