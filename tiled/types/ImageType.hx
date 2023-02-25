package tiled.types;

using tiled.types.XmlTools;

/**
  The image instance referenced by image layers, tilesets and objects.
  
  See readme for instruction on how to define your own image type.
  
  @see `tiled.Tiled.loadImage` for information about `loadImage` method.
  @see `tiled.Tiled.subRegion` for information about `subRegion` method.
**/
#if heaps
// In order to make working with custom types easier, use `@:forward` metadatas and `from/to`.
// Or define `loadImage` / `subRegion` on your own type and use direct `typedef` instead of abstract.
@:forward @:forwardStatics @:forward.new @:forward.variance
abstract ImageType(h2d.Tile) from h2d.Tile to h2d.Tile {
  
  public static inline function loadImage(path: String, ?relativeTo: String): ImageType {
    #if heeps
    // Heeps adds special handling to gif files and if not explicitly converted to GifImage on load -
    // will cause reinterpret casts error when attempting to load them as GifImage later.
    final res = hxd.Res.load(path.normalizePath(relativeTo));
    if (res.entry.extension == "gif") return res.to(cherry.res.GifImage).toTile();
    else return res.toTile();
    #else
    return hxd.Res.load(path.normalizePath(relativeTo)).toTile();
    #end
  }
  
  public static inline function subRegion(image:ImageType, x:Int, y:Int, w:Int, h:Int, offsetX:Int, offsetY:Int):TileImageType {
    return image.sub(x, y, w, h, offsetX, offsetY);
  }
}

#else
@:forward @:forwardStatics @:forward.new @:forward.variance
abstract ImageType(String) from String to String {
  
  public static inline function loadImage(path: String, ?relativeTo: String): ImageType {
    return path.normalizePath(relativeTo);
  }

  // Use `path#x,y,w,h,offsetX,offsetY` format
  public static inline function subRegion(image:ImageType, x:Int, y:Int, w:Int, h:Int, offsetX:Int, offsetY:Int):ImageType {
    return image + '#$x,$y,$w,$h,$offsetX,$offsetY';
  }
}
#end