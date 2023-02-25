package tiled;

import tiled.types.ImageType;
import tiled.types.Properties;
import tiled.types.TmxTileset;

/**
  Helper methods to work with the Tiled maps.
  
  Use by adding `using tiled.TiledTools;` in your imports or `import.hx` file.
**/
class TiledTools {
  
  /**
    Find the corresponding `TmxTileset` to which the given global ID belongs.
    @returns The `TmxTileset` given global ID belongs to or `null` if `gid` is `0`.
  **/
  public static function getTileset(sets:Array<TmxTileset>, gid:Int):TmxTileset {
    if (gid == 0) return null;
    var i = 0;
    while (++i < sets.length) if (sets[i].firstGid > gid)
      return sets[i - 1];
    return sets[i - 1];
  }
  
  /**
    Find the corresponding `TmxTile` that belongs to the given global ID.
    @returns The `TmxTile` that given global ID belongs to or `null` if `gid` is `0`.
  **/
  public static function getTile(sets:Array<TmxTileset>, gid:Int):TmxTile {
    if (gid == 0) return null;
    var i = 0;
    while (++i < sets.length) if (sets[i].firstGid > gid) {
      var tset = sets[i - 1];
      return tset.tiles[gid - tset.firstGid];
    }
    var tset = sets[i - 1];
    return tset.tiles[gid - tset.firstGid];
  }
  
  /**
    Find the corresponding `ImageType` that belongs to the given global ID.
    @returns The `ImageType` that given global ID belongs to or `null` if `gid` is `0`.
  **/
  public static function getImage(sets:Array<TmxTileset>, gid:Int):ImageType {
    if (gid == 0) return null;
    var i = 0;
    while (++i < sets.length) if (sets[i].firstGid > gid) {
      var tset = sets[i - 1];
      return tset.imageTiles[gid - tset.firstGid];
    }
    var tset = sets[i - 1];
    return tset.imageTiles[gid - tset.firstGid];
  }
  
}