package tiled.types;

import tiled.project.PropertyClass;
import tiled.project.TiledProject;
import tiled.project.TiledClass;
import tiled.types.TmxTileset;
using tiled.types.XmlTools;
using tiled.TiledTools;

#if !macro
@:build(tiled.types.Macros.buildExtraFields())
#end
class TmxMap {
  
  #if tiled_metadata
  /** The TMX format version. **/
  public var version:String;
  /** The Tiled version used to save the file. May be a date (for snapshot builds). **/
  public var tiledVersion:String;
  #end
  /** The class of this map. **/
  public var type: String;
  
  /** Map orientation. **/
  public var orientation:MapOrientation;
  /**
    The order in which tiles on tile layers are rendered.
    
    In all cases, the map is drawn row-by-row.
  **/
  public var renderOrder:MapRenderOrder;
  /**
    The compression level to use for tile layer data.
    
    -1 means to use the algorithm default.
  **/
  public var compressionLevel:Int;
  
  /** The map width in tiles. **/
  public var width:Int;
  /** The map height in tiles. **/
  public var height:Int;
  /** The width of a tile. **/
  public var tileWidth:Int;
  /** The height of a tile. **/
  public var tileHeight:Int;
  
  public var pixelWidth(get, never):Int;
  public var pixelHeight(get, never):Int;
  inline function get_pixelWidth() return width * tileWidth;
  inline function get_pixelHeight() return height * tileHeight;
  
  /** X coordinate of the parallax origin in pixels. **/
  public var parallaxOriginX: Float;
  /** Y coordinate of the parallax origin in pixels. **/
  public var parallaxOriginY: Float;
  
  public var backgroundColor:Int;
  #if tiled_metadata
  public var nextLayerId:Int;
  public var nextObjectId:Int;
  #end
  public var infinite:Bool;
  
  #if (tiled_props=="project")
  public var tclass: TiledClass;
  #else
  public var properties:Properties;
  #end
  
  public var tilesets:Array<TmxTileset>;
  public var layers:Array<TmxLayer>;
  /**
    An index of all objects by their ID.
    Can contain gaps, because Tiled does not reuse IDs of deleted objects.
  **/
  public var objects:Array<TmxObject>;
  
  #if tiled_metadata
  // Editor config
  public var chunkWidth:Int = 16;
  public var chunkHeight:Int = 16;
  public var exportTarget:String;
  public var exportFormat:String;
  #end
  
  public var path:String;
  
  public function new(?path:String) {
    this.path = path;
  }
  
  public function loadXML(x:Xml, loader:Tiled): TmxMap {
    if (x.nodeType == Document)
      x = x.firstElement();
    #if tiled_metadata
    version = x.att('version', '1.0');
    tiledVersion = x.att('tiledversion');
    nextLayerId = x.iatt('nextlayerid');
    nextObjectId = x.iatt('nextobjectid');
    #end
    
    orientation = switch(x.get('orientation')) {
      case 'orthogonal': Orthogonal;
      case 'isometric': Isometric;
      case 'staggered': Staggered(x.get('staggeraxis') == 'y', x.get('staggerindex') == 'odd');
      case 'hexagonal': Hexagonal(x.iatt('hexsidelength'), x.get('staggeraxis') == 'y', x.get('staggerindex') == 'odd');
      default: Orthogonal;
    }
    
    renderOrder = switch (x.att('renderoder', 'right-down')) {
      case 'right-down': RightDown;
      case 'right-up': RightUp;
      case 'left-up': LeftUp;
      case 'left-down': LeftDown;
      default: RightDown;
    }
    compressionLevel = x.iatt('compressionlevel', -1);
    
    type = x.att('class');
    width = x.iatt('width');
    height = x.iatt('height');
    tileWidth = x.iatt('tilewidth');
    tileHeight = x.iatt('tileheight');
    
    parallaxOriginX = x.fatt('parallaxoriginx');
    parallaxOriginY = x.fatt('parallaxoriginy');
    
    backgroundColor = x.catt('backgroundcolor', 0, 0);
    infinite = x.batt('infinite');
    
    #if (tiled_props=="project")
    this.tclass = TiledProject.initWithFallback(TiledProject.mapFactory[type], this);
    #else
    properties = new Properties();
    #end
    
    tilesets = [];
    layers = [];
    objects = [];
    
    for (el in x) if (el.nodeType == Element) {
      var l:TmxLayer;
      inline function makeLayer(type) {
        l = new TmxLayer(type);
        l.loadXML(el, this, loader);
        layers.push(l);
      }
      switch (el.nodeName) {
        case 'properties':
          #if (tiled_props=="project")
          TiledProject.loadXMLProperties(tclass, el, loader, path);
          #else
          properties.loadXML(el, loader);
          #end
        case 'tileset': // According to spec always happens before everything else.
          var tset = new TmxTileset();
          tset.path = this.path;
          tset.loadXML(el, this, loader);
          if (!tset.isComplete) {
            var tsx = loader.loadTSX(tset.source, this.path);
            tset.loadTSX(tsx);
          }
          tilesets.push(tset);
        case 'layer': makeLayer(TTileLayer);
        case 'objectgroup': makeLayer(TObjectGroup);
        case 'imagelayer': makeLayer(TImageLayer);
        case 'group': makeLayer(TGroup);
        #if tiled_metadata
        case 'editorsettings':
          for (ed in el) if (ed.nodeType == Element) {
            if (ed.nodeName == 'chunksize') {
              chunkWidth = ed.iatt('width');
              chunkHeight = ed.iatt('height');
            } else if (ed.nodeName == 'export') {
              exportTarget = ed.att('target', null);
              exportFormat = ed.att('format', null);
            }
          }
          // TODO: Editor settings
        #end
      }
    }
    
    #if (tiled_props=="project")
    if (tclass != null) tclass.finalize(objects, path, loader);
    function finalizeProps(layers:Array<TmxLayer>) {
      for (l in layers) {
        l.tclass.finalize(objects, path, loader);
        if (l.objects != null) for (o in l.objects) o.tclass.finalize(objects, path, loader);
        if (l.subLayers != null) finalizeProps(l.subLayers);
      }
    }
    finalizeProps(layers);
    #else
    if (type != null && type != "")
      properties.inherit(loader.getObjectType(type));
    
    function finalizeProps(layers:Array<TmxLayer>, objects:Array<TmxObject>) {
      for (l in layers) {
        l.properties.finalize(objects, path, loader);
        if (l.objects != null) for (o in l.objects) o.properties.finalize(objects, path, loader);
        if (l.subLayers != null) finalizeProps(l.subLayers, objects);
      }
    }
    finalizeProps(layers, objects);
    properties.finalize(objects, path, loader);
    #end
    
    if (loader.flattenLayers) {
      var flat = [];
      function flatten(layer:TmxLayer) {
        for (l in layer.subLayers) {
          l.offsetX += layer.offsetX;
          l.offsetY += layer.offsetY;
          l.opacity *= layer.opacity;
          l.tintColor *= layer.tintColor;
          if (!layer.visible) l.visible = false;
          #if (tiled_props!="project")
          if (loader.inheritGroupPropertiesOnFlatten) l.properties.inherit(layer.properties);
          #end
          if (l.kind == TGroup) flatten(l);
          else flat.push(l);
        }
      }
      for (l in layers) {
        if (l.kind == TGroup) flatten(l);
        else flat.push(l);
      }
      layers = flat;
    }
    return this;
  }
  
  public function realignObjects(to:TmxObjectAlignment) {
    for (o in objects) {
      if (o != null && o.kind == TTile) {
        var tset = tilesets.getTileset(o.gid);
        o.realign(tset.objectAlignment, to, orientation == Isometric);
      }
    }
    for (tset in tilesets) tset.objectAlignment = to;
  }
  
  
  public function flatIterator():Iterator<TmxLayer> {
    return new FlatIterator(this.layers);
  }
}

private class FlatIterator {
  
  var stack: Array<{ caret: Int, layers: Array<TmxLayer> }>;
  var nest:Array<Array<TmxLayer>>;
  var carets:Array<Int>;
  public inline function new(root:Array<TmxLayer>) {
    stack = root.length == 0 ? [] : [{ caret: 0, layers: root }];
    nest = [root];
    carets = root.length == 0 ? [] : [0];
  }
  
  public inline function hasNext():Bool {
    var s;
    return stack.length > 0 && (s = stack[stack.length-1]).caret != s.layers.length;
  }
  
  public inline function next():TmxLayer {
    var s = stack[stack.length - 1];
    var l = s.layers[s.caret++];
    if (l.subLayers != null && l.subLayers.length > 0) {
      stack.push({ caret: 0, layers: l.subLayers });
    } else {
      while (s != null && s.caret == s.layers.length) {
        stack.pop();
        s = stack[stack.length - 1];
      }
    }
    return l;
    
  }
  
}

// staggeraxis -> x/y
// staggerindex -> even/odd
enum MapOrientation {
  Orthogonal;
  Isometric;
  /**
    The staggered orientation refers to an isometric map using staggered axes.
    @param staggerYAxis Determines which axis (“x” or “y”) is staggered.
    @param staggerIndexOdd Determines whether the “even” or “odd” indexes along the staggered axis are shifted.
  **/
  Staggered(staggerYAxis:Bool, staggerIndexOdd:Bool);
  /**
    The hexagonal orientation refers to an map consisting of hexagonally-shaped tiles.
    @param sideLength Determines the width or height (depending on the staggered axis) of the tile’s edge, in pixels.
    @param staggerYAxis Determines which axis (“x” or “y”) is staggered.
    @param staggerIndexOdd Determines whether the “even” or “odd” indexes along the staggered axis are shifted.
  **/
  Hexagonal(sideLength:Int, staggerYAxis:Bool, staggerIndexOdd:Bool);
}

enum MapRenderOrder {
  RightDown;
  RightUp;
  LeftDown;
  LeftUp;
}