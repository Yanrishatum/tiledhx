package tiled.types;

import tiled.project.TiledProject;
import tiled.project.TiledClass;
import tiled.types.TmxMap;
using tiled.types.XmlTools;

/**
  The Tiled tileset structure.
**/
#if (!macro && tiled_extra_fields)
@:build(tiled.types.Macros.buildExtraFields())
#end
class TmxTileset {
  
  /** The first global tile ID of this tileset (this global ID maps to the first tile in this tileset). **/
  public var firstGid:Int;
  /**
    If this tileset is stored in an external TSX file, this attribute refers to that file.
    
    @see `isComplete` to check if this tileset was merged with the TSX source.
  **/
  public var source:String;
  /**
    Whether this is an incomplete tileset (and needs to be merged with `source` tileset) or a complete one.
    
    None of the fields other than `firstGid`, `path` and `source` are initialized for incomplete tilesets.
  **/
  public var isComplete:Bool;
  
  /** The name of this tileset. **/
  public var name:String;
  /** The class of this tileset. **/
  public var type: String;
  /**
    The (maximum) width of the tiles in this tileset.
    
    Irrelevant for image collection tilesets, but stores the maximum tile width.
  **/
  public var tileWidth:Int;
  /**
    The (maximum) height of the tiles in this tileset.
    
    Irrelevant for image collection tilesets, but stores the maximum tile height.
  **/
  public var tileHeight:Int;
  
  /**
    The spacing in pixels between the tiles in this tileset.
    
    Irrelevant for image collection tilesets.
  **/
  public var spacing:Int;
  /**
    The margin around the tiles in this tileset.
    
    Irrelevant for image collection tilesets.
  **/
  public var margin:Int;
  
  /**
    The number of tiles in this tileset.
    
    Note that there can be tiles with a higher ID than the tile count, in case the tileset is an image collection from which tiles have been removed.
  **/
  public var tileCount:Int;
  /**
    The number of tile columns in the tileset.
    
    For image collection tilesets it is editable and is used when displaying the tileset.
  **/
  public var columns:Int;
  /**
    Controls the alignment for tile objects.
    
    The default value is unspecified, for compatibility reasons. When unspecified, tile objects use BottomLeft in Orthogonal mode and Bottom in Isometric mode.
  **/
  public var objectAlignment:TmxObjectAlignment;
  /**
    The size to use when rendering tiles from this tileset on a tile layer.
  **/
  public var tileRenderSize: TmxTileRenderSize;
  /**
    The fill mode to use when rendering tiles from this tileset.
    
    Only relevant when the tiles are not rendered at their native size (e.g. `tileRenderSize = Grid`),
    so this applies to resized tile objects.
  **/
  public var fillMode: TmxFillMode;
  
  /**
    Horizontal offset in pixels, to be applied when drawing a tile from this tileset.
  **/
  public var tileOffsetX:Int;
  /**
    Vertical offset in pixels, to be applied when drawing a tile from this tileset.
  **/
  public var tileOffsetY:Int;
  
  /**
    The source image path to the image containing the tiles.
    
    Note: Embedded images are not supported.
  **/
  public var image:String;
  /**
    Defines a specific color that is treated as transparent.
  **/
  public var imageTransparency:Null<Int>;
  /**
    The image width in pixels.
  **/
  public var imageWidth:Int;
  /**
    The image height in pixels.
  **/
  public var imageHeight:Int;
  
  /**
    Orientation of the grid for the tiles in this tileset.
  **/
  public var gridIsometric:Bool;
  /**
    Width of a grid cell.
    
    Only used in case of isometric orientation, and determines how tile overlays for terrain and collision information are rendered.
  **/
  public var gridWidth:Int;
  /**
    Height of a grid cell.
    
    Only used in case of isometric orientation, and determines how tile overlays for terrain and collision information are rendered.
  **/
  public var gridHeight:Int;
  
  public var tiles:Array<TmxTile>;
  
  #if (tiled_props=="project")
  public var tclass: TiledClass;
  #else
  public var properties:Properties;
  #end
  
  public var path:String;
  
  public var imageTile:ImageType;
  public var imageTiles:Array<TileImageType>;
  
  public var isImageset(get, never):Bool;
  inline function get_isImageset() return image == null;
  
  #if tiled_enable_terrains
  public var terrains:Array<TerrainType>;
  #end
  
  #if tiled_metadata
  
  /** Whether the tiles in this set can be flipped horizontally. **/
  public var allowHFlip: Bool;
  /** Whether the tiles in this set can be flipped vertically. **/
  public var allowVFlip: Bool;
  /** Whether the tiles in this set can be rotated in 90 degree increments. **/
  public var allowRotate: Bool;
  /** Whether untransformed tiles remain preferred, otherwise transformed tiles are used to produce more variations. **/
  public var preferUntransformed: Bool;
  
  /** The list Wang sets in this tileset. **/
  public var wangSets: Array<WangSet>;
  
  #end
  
  public function new(?path:String) {
    this.path = path;
  }
  
  public function loadTSX(tsx:TmxTileset) {
    this.isComplete = true;
    this.name = tsx.name;
    this.type = tsx.type;
    this.tileWidth = tsx.tileWidth;
    this.tileHeight = tsx.tileHeight;
    this.spacing = tsx.spacing;
    this.margin = tsx.margin;
    this.tileCount = tsx.tileCount;
    this.columns = tsx.columns;
    this.objectAlignment = tsx.objectAlignment;
    this.tileRenderSize = tsx.tileRenderSize;
    this.fillMode = tsx.fillMode;
    this.tileOffsetX = tsx.tileOffsetX;
    this.tileOffsetY = tsx.tileOffsetY;
    this.tiles = tsx.tiles;
    this.image = tsx.image;
    this.imageTransparency = tsx.imageTransparency;
    this.imageWidth = tsx.imageWidth;
    this.imageHeight = tsx.imageHeight;
    this.gridIsometric = tsx.gridIsometric;
    this.gridWidth = tsx.gridWidth;
    this.gridHeight = tsx.gridHeight;
    this.imageTile = tsx.imageTile;
    this.imageTiles = tsx.imageTiles;
    #if (tiled_props=="project")
    if (tsx.tclass != null) this.tclass = tsx.tclass.transferToTileset(this);
    #else
    this.properties.inherit(tsx.properties);
    #end
    
    #if tiled_enable_terrains
    this.terrains = tsx.terrains;
    #end
    #if tiled_metadata
    this.wangSets = tsx.wangSets;
    #end
  }
  
  // Load
  public function loadXML(x:Xml, map: TmxMap, loader:Tiled) {
    if (x.nodeType == Document)
      x = x.firstElement();
    // Non-TSX have gid and source
    this.firstGid = x.iatt('firstgid', 1);
    this.source = x.att('source', null);
    if (this.source == "") this.source = null; // Enforce source being null when no source is given.
    this.isComplete = source == null;
    
    // Either tsx or embedded tileset
    if (isComplete) {
      this.name = x.att('name');
      this.type = x.att('class');
      this.tileWidth = x.iatt('tilewidth');
      this.tileHeight = x.iatt('tileheight');
      if (tileWidth == 0 && tileHeight == 0) {
        // Older maps don't store tilewidth/tileheight
        if (map == null) throw "TSX without tile sizes!";
        else {
          tileWidth = map.tileWidth;
          tileHeight = map.tileHeight;
        }
      }
      this.spacing = x.iatt('spacing');
      this.margin = x.iatt('margin');
      this.tileCount = x.iatt('tilecount');
      this.columns = x.iatt('columns');
      this.objectAlignment = switch (x.att('objectalignment', 'unspecified')) {
        case 'unspecified': Unspecified;
        case 'topleft': TopLeft;
        case 'top': Top;
        case 'topright': TopRight;
        case 'left': Left;
        case 'center': Center;
        case 'right': Right;
        case 'bottomleft': BottomLeft;
        case 'bottom': Bottom;
        case 'bottomright': BottomRight;
        default: Unspecified;
      }
      this.tileRenderSize = x.att('tilerendersize', 'tile') == 'grid' ? Grid : Tile;
      this.fillMode = x.att('fillmode', 'stretch') == 'preserve-aspect-fit' ? PreserveAspectFit : Stretch;
      tileOffsetX = 0;
      tileOffsetY = 0;
      tiles = [];
      #if (tiled_props=="project")
      this.tclass = TiledProject.initWithFallback(TiledProject.tilesetFactory[this.type], this);
      #else
      this.properties = new Properties();
      #end
      #if tiled_enable_terrains
      terrains = [];
      #end
      #if tiled_metadata
      wangSets = [];
      #end
      
      for (el in x) {
        if (el.nodeType != Element) continue;
        switch (el.nodeName) {
          case 'tileoffset':
            tileOffsetX = el.iatt('x');
            tileOffsetY = el.iatt('y');
          case 'image':
            // Embedded data is not supported
            image = el.att('source');
            imageTransparency = el.exists('trans') ? el.catt('trans', 0, 0) : null;
            imageWidth = el.iatt('width');
            imageHeight = el.iatt('height');
            if (imageWidth == 0 && imageHeight == 0) {
              imageTile = loader.loadImage(image, this.path);
              var wh = loader.imageSize(imageTile);
              imageWidth = wh.width;
              imageHeight = wh.height;
            }
            if (columns == 0) columns = Std.int((imageWidth - margin) / (tileWidth + spacing));
            if (tileCount == 0) tileCount = columns * Std.int((imageHeight - margin) / (tileHeight + spacing));
            
          case 'grid':
            gridIsometric = el.att('orientation') == 'isometric';
            gridWidth = el.iatt('width', tileWidth);
            gridHeight = el.iatt('height', tileHeight);
          case 'properties':
            #if (tiled_props=="project")
            TiledProject.loadXMLProperties(this.tclass, el, loader, path);
            #else
            properties.loadXML(el, loader);
            if (loader.deLocalizeFileProperties) properties.deLocalize(path);
            #end
          #if tiled_enable_terrains
          case 'terraintypes':
            for (tt in el) {
              if (tt.nodeType == Element) {
                var terrain:TerrainType = { properties: new Properties(), name: tt.att('name'), tile: tt.iatt('tile') };
                tt.loadProps(terrain.properties);
                terrain.properties.deLocalize(path);
                terrains.push(terrain);
              }
            }
          #end
          #if tiled_metadata
          case 'wangsets':
            for (s in el) if (s.nodeType == Element && s.nodeName == 'wangset') {
              var set = new WangSet();
              set.name  = s.att('name');
              set.type = s.att('class');
              set.tile = s.iatt('tile');
              s.loadProps(set.properties, loader);
              if (set.type != null && set.type != "")
                set.properties.inherit(loader.getObjectType(set.type));
              
              for (col in s) if (col.nodeType == Element && col.nodeName == 'wangcolor') {
                var wcolor = new WangColor();
                wcolor.name = col.att('name');
                wcolor.type = col.att('class');
                wcolor.color = col.catt('color');
                wcolor.tile = col.iatt('tile');
                wcolor.probability = col.fatt('probability');
                col.loadProps(wcolor.properties, loader);
                set.colors.push(wcolor);
                if (wcolor.type != null && wcolor.type != "")
                  wcolor.properties.inherit(loader.getObjectType(wcolor.type));
              }
              
              for (tile in s) if (tile.nodeType == Element && tile.nodeName == 'wangtile') {
                var id = tile.att('wangid');
                var ids: Array<WangColor> = [];
                if (id.indexOf(',') == -1) {
                  // Pre 1.5 wang sets
                  var packed = Std.parseInt(id); // Potential bug: If it's stored as uint in decimal instead of 0xCECECECE, it can lead to corrupted data.
                  ids[0] = (packed&0xF         ) == 0 ? null : set.colors[(packed    &0xF)-1];
                  ids[1] = (packed&0xF0        ) == 0 ? null : set.colors[(packed>>4 &0xF)-1];
                  ids[2] = (packed&0xF00       ) == 0 ? null : set.colors[(packed>>8 &0xF)-1];
                  ids[3] = (packed&0xF000      ) == 0 ? null : set.colors[(packed>>12&0xF)-1];
                  ids[4] = (packed&0xF0000     ) == 0 ? null : set.colors[(packed>>16&0xF)-1];
                  ids[5] = (packed&0xF00000  ) == 0 ? null : set.colors[(packed>>20&0xF)-1];
                  ids[6] = (packed&0xF000000   ) == 0 ? null : set.colors[(packed>>24&0xF)-1];
                  ids[7] = (packed&0xF0000000) == 0 ? null : set.colors[(packed>>28&0xF)-1];
                } else {
                  var split = id.split(",");
                  var i = 0;
                  for (col in split) {
                    var colId = Std.parseInt(col);
                    if (colId == null) ids[i++] = null;
                    else ids[i++] = set.colors[colId-1];
                  }
                }
                
                set.tiles.push({
                  tileId: tile.iatt('tileid'),
                  wangId: ids,
                  hflip: tile.batt('hflip'),
                  vflip: tile.batt('vflip'),
                  dflip: tile.batt('dflip')
                });
              }
              wangSets.push(set);
            }
          case 'transformations':
            allowHFlip = el.batt('hflip');
            allowVFlip = el.batt('vflip');
            allowRotate = el.batt('rotate');
            preferUntransformed = el.batt('preferuntransformed');
          #end
        }
      }
      
      if (image != null) {
        if (imageTile == null) imageTile = loader.loadImage(image, this.path);
        imageTiles = loader.loadTileset(imageTile, this);
        if (loader.deLocalizeImagePaths) image = image.normalizePath(this.path);
      } else {
        imageTiles = [];
      }
      
      for (el in x) if (el.nodeType == Element && el.nodeName == 'tile') {
        var t = new TmxTile();
        t.id = el.iatt('id');
        t.type = el.typeatt();
        tiles[t.id] = t;
        #if tiled_metadata
        t.probability = el.fatt('probability', 1);
        #end
        #if tiled_enable_terrains
        if (el.exists('terrain')) {
          var terr = new Array<TerrainType>();
          for (corner in el.get('terrain').split(',')) terr.push(corner == '' ? null : terrains[Std.parseInt(corner)]);
          t.terrains = new TileTerrain(terr);
        }
        #end
        #if (tiled_props=="project")
        t.tclass = TiledProject.initWithFallback(TiledProject.tileFactory[t.type], t);
        #end
        t.tileX = el.iatt('x');
        t.tileY = el.iatt('y');
        t.tileWidth = el.iatt('width', -1);
        t.tileHeight = el.iatt('height', -1);
        t.imageTile = imageTiles[t.id];
        for (tel in el) if (tel.nodeType == Element) {
          switch (tel.nodeName) {
            case 'properties':
              #if (tiled_props=="project")
              TiledProject.loadXMLProperties(t.tclass, tel, loader, path);
              #else
              t.properties.loadXML(tel, loader);
              #end
            case 'image':
              t.image = tel.att('source');
              var image = loader.loadImage(t.image, this.path);
              
              t.imageWidth = tel.iatt('width');
              t.imageHeight = tel.iatt('height');
              t.imageTransparency = tel.catt('trans');
              
              if (t.tileWidth == -1 || t.tileHeight == -1) {
                t.tileWidth = t.imageWidth;
                t.tileHeight = t.imageHeight;
              }
              
              if (image != null) t.imageTile = loader.subRegion(image, t.tileX, t.tileY, t.tileWidth, t.tileHeight, tileOffsetX, tileOffsetY);
              
              if (loader.deLocalizeImagePaths) t.image = t.image.normalizePath(this.path);
              imageTiles[t.id] = t.imageTile;
            case 'animation':
              t.animation = [];
              for (ael in tel) if (ael.nodeType == Element) t.animation.push({ id: ael.iatt('tileid'), duration: ael.iatt('duration') });
            case 'objectgroup':
              for (cel in tel) if (cel.nodeType == Element && cel.nodeName == 'object') {
                var obj = new TmxObject();
                obj.loadXML(cel, loader, path);
                t.collision.push(obj);
              }
              for (obj in t.collision) {
                #if (tiled_props=="project")
                obj.tclass.finalize(t.collision, this.path, loader);
                #else
                obj.properties.finalize(t.collision, this.path, loader);
                #end
              }
          }
        }
        
        #if (tiled_props=="project")
        
        #else
        if (type != null && type != "")
          properties.inherit(loader.getObjectType(type));
        
        if (t.type != null && t.type != "")
          t.properties.inherit(loader.getObjectType(t.type));
        
        if (loader.deLocalizeFileProperties) t.properties.deLocalize(path);
        #end
      }
    }
  }
  
  // TODO: loadJson
  // TODO: loadBinary
  
  // TODO: saveBinary
  // TODO: saveJson
  // TODO: saveXML
  
}

class TmxTile {
  /** The local tile ID within its tileset. **/
  public var id:Int;
  /**
    The type of the tile. Refers to an object type and is used by tile objects.
    
    Referred to as `class` since Tiled 1.9
  **/
  public var type:String;
  
  #if (tiled_props=="project")
  public var tclass: TiledClass;
  #else
  public var properties:Properties = new Properties();
  #end
  
  
  /** The X position of the sub-rectangle representing this tile. **/
  public var tileX: Int;
  /** The Y position of the sub-rectangle representing this tile. **/
  public var tileY: Int;
  /** The width of the sub-rectangle representing this tile. **/
  public var tileWidth:Int;
  /** The height of the sub-rectangle representing this tile. **/
  public var tileHeight:Int;
  
  public var image:String;
  public var imageWidth:Int;
  public var imageHeight:Int;
  /** Defines a specific color that is treated as transparent. **/
  public var imageTransparency: Null<Int>;
  
  public var collision:Array<TmxObject>;
  /** Contains a list of animation frames. **/
  public var animation:Array<TileFrame>;
  
  public var imageTile:TileImageType;
  
  #if tiled_enable_terrains
  /** Defines the terrain type of each corner of the tile. **/
  public var terrains:TileTerrain;
  #end
  #if tiled_metadata
  /** A percentage indicating the probability that this tile is chosen when it competes with others while editing with the terrain tool. **/
  public var probability:Float;
  #end
  
  public function new() {
    collision = [];
  }
}

#if tiled_enable_terrains
@:structInit
class TerrainType {
  public var name:String;
  public var tile:Int;
  public var properties:Properties;
}

abstract TileTerrain(Array<TerrainType>) {
  
  public var topLeft(get, set):TerrainType;
  public var topRight(get, set):TerrainType;
  public var bottomLeft(get, set):TerrainType;
  public var bottomRight(get, set):TerrainType;
  
  public inline function new(terr:Array<TerrainType>) {
    this = terr;
  }
  
  inline function get_topLeft() return this[0];
  inline function get_topRight() return this[1];
  inline function get_bottomLeft() return this[2];
  inline function get_bottomRight() return this[3];
  
  inline function set_topLeft(v) return this[0] = v;
  inline function set_topRight(v) return this[1] = v;
  inline function set_bottomLeft(v) return this[2] = v;
  inline function set_bottomRight(v) return this[3] = v;
}
#end

#if tiled_metadata

//#region WangSets
/** The Wang set descriptor. **/
class WangSet {
  /** The name of the Wang set. **/
  public var name: String;
  /** The class of the Wang set. **/
  public var type: String;
  /** The tile ID of the tile representing this Wang set. **/
  public var tile: Int;
  /** The list of this Wang set custom properties. **/
  public var properties: Properties;
  /** The list of Wang colors (up to 255). **/
  public var colors: Array<WangColor>;
  /** The list of Wang tiles. **/
  public var tiles: Array<WangTile>;
  
  // TODO: Figure out wangset property inheritance.
  // TODO: Implement project mode.
  
  public function new() {
    properties = new Properties();
    colors = [];
    tiles = [];
  }
  
}

/** A color that can be used to define the corner and/or edge of a Wang tile. **/
@:structInit
class WangColor {
  /** The name of this color. **/
  public var name: String;
  /** The class of this color. **/
  public var type: String;
  /** The color value. **/
  public var color: Int;
  /** The tile ID of the tile representing this color. **/
  public var tile: Int;
  /** The relative probability that this color is chosen over others in case of multiple options. **/
  public var probability: Float;
  
  /** The list of this color custom properties. **/
  public var properties: Properties;
  
  public function new() {
    properties = new Properties();
  }
  
}

/** Defines a Wang tile, by referring to a tile in the tileset and associating it with a certain Wang ID. **/
@:structInit
class WangTile {
  /** The tile ID. **/
  public var tileId: Int;
  /** The Wang ID. **/
  public var wangId: WangTileID;
  /** Whether the tile is flipped horizontally. Deprecated since Tiled 1.5 **/
  public var hflip: Bool;
  /** Whether the tile is flipped vertically. Deprecated since Tiled 1.5 **/
  public var vflip: Bool;
  /** Whether the tile is flipped on its diagonal. Deprecated since Tiled 1.5 **/
  public var dflip: Bool;
}

/**
  The Wang tile colors.
**/
abstract WangTileID(Array<WangColor>) from Array<WangColor> {
  
  public var top(get, set):WangColor;
  public var topRight(get, set):WangColor;
  public var right(get, set):WangColor;
  public var bottomRight(get, set):WangColor;
  public var bottom(get, set):WangColor;
  public var bottomLeft(get, set):WangColor;
  public var left(get, set):WangColor;
  public var topLeft(get, set):WangColor;
  
  public inline function new(terr:Array<WangColor>) {
    this = terr;
  }
  
  inline function get_top()           return this[0];
  inline function get_topRight()      return this[1];
  inline function get_right()         return this[2];
  inline function get_bottomRight()   return this[3];
  inline function get_bottom()        return this[4];
  inline function get_bottomLeft()    return this[5];
  inline function get_left()          return this[6];
  inline function get_topLeft()       return this[7];
  
  inline function set_top(v)          return this[0] = v;
  inline function set_topRight(v)     return this[1] = v;
  inline function set_right(v)        return this[2] = v;
  inline function set_bottomRight(v)  return this[3] = v;
  inline function set_bottom(v)       return this[4] = v;
  inline function set_bottomLeft(v)   return this[5] = v;
  inline function set_left(v)         return this[6] = v;
  inline function set_topLeft(v)      return this[7] = v;
}
//#endregion

#end

/**
  A TmxTile animation frame.
**/
@:structInit
class TileFrame {
  /** The local ID of a tile within the parent tileset. **/
  public var id:Int;
  /** How long (in milliseconds) this frame should be displayed before advancing to the next frame. **/
  public var duration:Int;
  // public var image: TileImageType;
}

enum TmxObjectAlignment {
  /** Handle as BottomLeft when in Orthogonal mode, and Bottom in Isometric mode. **/
  Unspecified;
  TopLeft;
  Top;
  TopRight;
  Left;
  Center;
  Right;
  BottomLeft;
  Bottom;
  BottomRight;
}

enum TmxTileRenderSize {
  /** Render tiles unmodified as-is. **/
  Tile;
  /** Render tiles at the tile grid size of the map. **/
  Grid;
}

enum TmxFillMode {
  /** Stretch the tile to fill entire requested area. **/
  Stretch;
  /** Rreserve aspect-ratio of the tile and fit it into the requested area. **/
  PreserveAspectFit;
}
