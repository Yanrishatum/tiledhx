package tiled.types;

import tiled.project.TiledProject;
import haxe.ds.ListSort;
import tiled.project.TiledClass;
using tiled.types.XmlTools;


#if (!macro && tiled_extra_fields)
@:build(tiled.types.Macros.buildExtraFields())
#end
class TmxLayer {
  
  // General
  /** Unique ID of the layer. **/
  public var id:Int;
  /** The name of the layer. **/
  public var name:String;
  /** The class of the layer. **/
  public var type: String;
  /** Horizontal offset for this layer in pixels. **/
  public var offsetX:Float;
  /** Vertical offset for this layer in pixels. **/
  public var offsetY:Float;
  /** Horizontal parallax factor for this layer. **/
  public var parallaxX: Float;
  /** Vertical parallax factor for this layer. **/
  public var parallaxY: Float;
  
  /** The opacity of the layer as a value from 0 to 1. **/
  public var opacity:Float;
  /** Whether the layer is shown or hidden. **/
  public var visible:Bool;
  /** A tint color that is multiplied with any tiles drawn by this layer. **/
  public var tintColor:Null<Int>;
  
  /** This layer content kind. Dictates which fiels are available. **/
  public var kind:TmxLayerType;
  
  #if (tiled_props=="project")
  public var tclass: TiledClass;
  #else
  /** The property list of this layer. **/
  public var properties:Properties = new Properties();
  #end
  
  // TileLayer
  /**
    The list of tile global IDs in this tile layer.
    
    Only present if `kind = TTileLayer` and `TmxMap.infinite = false`
  **/
  public var tiles:Array<TmxTileIndex>;
  /**
    The list of layer chunks.
    
    Only present if `kind = TTileLayer`.
    
    For non-infinite maps automatically filled with a dummy chunk pointing at `tiles`.
  **/
  public var tileChunks:Array<TileChunk>;
  /**
    For `kind = TTileLayer`: The width of the layer in tiles. Undefined for infinite maps.
    For `kind = TImageLayer`: ...
  **/
  public var width:Int;
  /**
    For `kind = TTileLayer`: The height of the layer in tiles. Undefined for infinite maps.
    For `kind = TImageLayer`: ...
  **/
  public var height:Int;
  
  // ObjectGroup
  /** Whether the objects are drawn according to the order of appearance (false) or sorted by their y-coordinate (true). **/
  public var ysortRender:Bool; // draworder = topdown
  /** The list of the object layer objects. **/
  public var objects:Array<TmxObject>;
  /** The color used to display the objects in this group. **/
  public var color: Null<Int>;
  
  // Image
  public var image:String;
  
  public var imageTile:ImageType;
  
  // Group
  public var subLayers:Array<TmxLayer>;
  
  public function new(kind:TmxLayerType) {
    this.kind = kind;
  }
  
  public function loadXML(x:Xml, map:TmxMap, loader:Tiled) {
    id = x.iatt('id');
    name = x.att('name');
    type = x.att('class');
    offsetX = x.fatt('offsetx');
    offsetY = x.fatt('offsety');
    parallaxX = x.fatt('parallaxx', 1);
    parallaxY = x.fatt('parallaxy', 1);
    opacity = x.fatt('opacity', 1);
    visible = x.batt('visible', true);
    tintColor = x.catt('tintcolor', 0xffffffff);
    
    #if (tiled_props=="project")
    tclass = TiledProject.initWithFallback(TiledProject.layerFactory[type], this);
    #end
    
    switch (kind) {
      case TTileLayer: 
        tileChunks = [];
      case TObjectGroup:
        objects = [];
        color = x.exists('color') ? x.catt('color') : null;
        ysortRender = x.att('draworder', 'topdown') == 'topdown';
      case TImageLayer:
      case TGroup:
        subLayers = [];
    }
    for (el in x) if (el.nodeType == Element) {
      inline function makeLayer(type) {
        var l = new TmxLayer(type);
        l.loadXML(el, map, loader);
        subLayers.push(l);
      }
      switch (el.nodeName) {
        case 'properties':
          #if (tiled_props=="project")
          TiledProject.loadXMLProperties(tclass, el, loader, map.path);
          #else
          properties.loadXML(el, loader);
          #end
          // finalize happens in TmxMap after parsing.
        case 'data':
          // tile data
          var encoding = el.get('encoding');
          var compression = el.get('compression');
          if (encoding == null && compression == null) {
            throw "Raw XML data not supported: Use csv or zlib/gzip for the love of god.";
          }
          width = x.iatt("width", map.width);
          height = x.iatt("height", map.height);
          if (map.infinite) {
            if (encoding == 'csv') {
              for (chunk in el) if (chunk.nodeType == Element) {
                tileChunks.push({
                  x: chunk.iatt('x'),
                  y: chunk.iatt('y'),
                  width: chunk.iatt('width'),
                  height: chunk.iatt('height'),
                  tiles: parseCSV(chunk.iterator().next().nodeValue)
                });
              }
            } else if (encoding == 'base64') {
              for (chunk in el) if (chunk.nodeType == Element) {
                tileChunks.push({
                  x: chunk.iatt('x'),
                  y: chunk.iatt('y'),
                  width: chunk.iatt('width'),
                  height: chunk.iatt('height'),
                  tiles: parseBase64(chunk.iterator().next().nodeValue, compression)
                });
              }
            } else throw "Unknown encoding: " + encoding;
          } else {
            if (encoding == 'csv') {
              tiles = parseCSV(el.iterator().next().nodeValue);
            } else if (encoding == 'base64') {
              tiles = parseBase64(el.iterator().next().nodeValue, compression);
            } else throw "Unknown encoding: " + encoding;
            tileChunks.push({
              x: 0, y: 0, width: width, height: height,
              tiles: tiles
            });
          }
        case 'object':
          // object group
          var obj = new TmxObject();
          obj.loadXML(el, loader, map.path, map.tilesets);
          objects.push(obj);
          map.objects[obj.id] = obj;
        case 'image':
          // image layer
          image = el.att('source');
          width = el.iatt('width');
          height = el.iatt('height');
          imageTile = loader.loadImage(image, map.path);
          if (loader.deLocalizeImagePaths) image = image.normalizePath(map.path);
        case 'layer': makeLayer(TTileLayer);
        case 'objectgroup': makeLayer(TObjectGroup);
        case 'imagelayer': makeLayer(TImageLayer);
        case 'group': makeLayer(TGroup);
      }
    }
    
    #if (tiled_props!="project")
    if (type != null && type != "")
      properties.inherit(loader.getObjectType(type));
    #end
    
  }
  
  // TODO: loadJson
  
  function parseCSV(data:String) {
    var out = [];
    var i = 0;
    var j = 0;
    inline function add() 
      out.push(TmxTileIndex.safeParse(data.substring(j, i)));
    final len = data.length;
    while (i < len) {
      if (data.charCodeAt(i) == ','.code) {
        add();
        j = i + 1;
      }
      i++;
    }
    if (i != j) add();
    return out;
  }
  
  function parseBase64(base64:String, compression:String) {
    var out = [];
    var data = haxe.crypto.Base64.decode(StringTools.trim(base64));
    if (compression != null) {
      switch (compression) {
        case 'gzip':
          #if format
          var o = new haxe.io.BytesOutput();
          new format.gz.Reader(new haxe.io.BytesInput(data)).readData(o);
          data = o.getBytes();
          #else
          throw "GZip compression requires format library";
          #end
        case 'zlib':
          data = haxe.zip.InflateImpl.run(new haxe.io.BytesInput(data));
        case 'zstd':
          throw "ZStd compression not supported";
        case '':
        default: throw "Unknown compression method: " + compression;
      }
    }
    var i = 0;
    while (i < data.length) {
      out.push(data.getInt32(i));
      i += 4;
    }
    return out;
  }
  
}

abstract TmxTileIndex(Int) from Int {
  
  public var flippedHorizontally(get, set):Bool;
  public var flippedVertically(get, set):Bool;
  public var flippedDiagonally(get, set):Bool;
  public var gid(get, set):Int;
  public var raw(get, set):Int;
  
  public static inline function safeParse(val:String):TmxTileIndex return val.parseUint();
  
  public inline function new(idx:Int) this = idx;
  
  inline function get_flippedHorizontally():Bool return this & 0x80000000 != 0;
  inline function get_flippedVertically():Bool return this & 0x40000000 != 0;
  inline function get_flippedDiagonally():Bool return this & 0x20000000 != 0;
  inline function get_gid():Int return (this & 0x1FFFFFFF);
  
  inline function get_raw():Int return this;
  inline function set_raw(v):Int return this = v;
  
  inline function set_flippedHorizontally(v:Bool):Bool {
    this = this & 0x7FFFFFFF | (v ? 0x80000000 : 0);
    return v;
  }
  inline function set_flippedVertically(v:Bool):Bool {
    this = this & 0xBFFFFFFF | (v ? 0x40000000 : 0);
    return v;
  }
  inline function set_flippedDiagonally(v:Bool):Bool {
    this = this & 0xDFFFFFFF | (v ? 0x20000000 : 0);
    return v;
  }
  inline function set_gid(v:Int):Int {
    this = this & 0xE0000000 | v;
    return v;
  }
  
  public inline function hasFlipFlags():Bool {
    return (this & 0xE0000000) != 0;
  }
  
  @:to inline function toInt():Int
    #if tiled_disable_flipping_safeguard return this; #else return this & 0x1FFFFFFF; #end
  
  
}

@:structInit
class TileChunk {
  
  public var x:Int;
  public var y:Int;
  public var width:Int;
  public var height:Int;
  public var tiles:Array<TmxTileIndex>;
  
}


enum TmxLayerType {
  TTileLayer;
  TObjectGroup;
  TImageLayer;
  TGroup;
}