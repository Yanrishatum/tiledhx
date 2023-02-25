package tiled.project;

import tiled.types.TmxTileset;
import tiled.types.TmxMap;
import tiled.types.TmxObject;
import tiled.Tiled;

/**
  This is a macro-interface that marks class as a Tiled class.
  
  Do not implement any of the interface methods, as they are automatically generated via build macro.
**/
@:keepSub
@:autoBuild(tiled._internal.ProjectMacro.buildClass())
@:using(tiled.project.TiledClass.TiledClassTools)
interface TiledClass {
  #if (tiled_props=="project")
  function loadProperties(properties: PropertyIterator, loader: Tiled, path: String): Void;
  function finalize(objects: Array<TmxObject>, path: String, loader: Tiled): Void;
  /**
    Only works for classes that supports `initObject`, for any others will return `null`.
    
    Used when `Tiled.transferTileClassToObject` is enabled to copy the TiledClass instance from the tile to an object.
  **/
  function transferToObject(obj: TmxObject): TiledClass;
  /**
    Only works for classes that support `initTileset`, for any others will return `null`.
    
    Used when map tileset copies data from TSX tileset.
  **/
  function transferToTileset(tset: TmxTileset): TiledClass;
  
  /*
  // Declare any of the following to enable usage on said types:
  public static function initObject(object: TmxObject): TiledClass
  public static function initTile(tile: TmxTile): TiledClass
  public static function initLayer(layer: TmxLayer): TiledClass
  public static function initTileset(tileset: TmxTileset): TiledClass
  public static function initMap(map: TmxMap): TiledClass
  public static function initProperty(other: TiledClass): TiledClass
  public static function initWangColor(color: WangColor): TiledClass
  public static function initWangSet(wang: WangSet): TiledClass
  // Or for single-type classes make constructor take that type:
  public function new(obj: TmxObject)
  */
  #end
}

class TiledClassTools {
  /** Helper **/
  public static inline function to<T: TiledClass>(tclass: TiledClass): T { return cast tclass; }
  public static inline function isA<T>(tclass: TiledClass, cl: Class<T>): Bool { return Std.isOfType(tclass, cl); }
  public static inline function as<T: TiledClass>(tclass: TiledClass, cl: Class<T>): Null<T> { return Std.downcast(tclass, cl); }
  
}