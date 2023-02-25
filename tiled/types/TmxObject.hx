package tiled.types;

import tiled.project.TiledProject;
import tiled.project.TiledClass;
import tiled.types.TmxLayer;
import tiled.types.TmxTileset;
using tiled.types.XmlTools;
using tiled.TiledTools;

#if !macro
@:build(tiled.types.Macros.buildExtraFields())
#end
class TmxObject {
  /** Unique ID of the object. **/
  public var id:Int = 0;
  /** The name of the object. An arbitrary string. **/
  public var name:String = "";
  /** The class of the object. An arbitrary string. **/
  public var type:String = "";
  /** The x coordinate of the object in pixels. **/
  public var x:Float = 0;
  /** The y coordinate of the object in pixels. **/
  public var y:Float = 0;
  /** The width of the object in pixels. **/
  public var width:Float = 0;
  /** The height of the object in pixels. **/
  public var height:Float = 0;
  /**
    The rotation of the object clockwise around (x, y).
    
    By default represented in radians, but can be enforced as degrees via `tiled_rotation_degrees` define.
  **/
  public var rotation:Float = 0;
  /** Whether the object is shown or hidden. **/
  public var visible:Bool = true;
  
  /** The object kind. Dictates which fields are available. **/
  public var kind:TmxObjectType;
  
  /**
    A reference to a tile (global ID).
    
    Only present for `kind = TTile`.
  **/
  public var gid:Int;
  /** Whether the object tile should be flipped horizontally. **/
  public var flipHorizontally:Bool;
  /** Whether the object tile should be flipped vertically. **/
  public var flipVertically:Bool;
  /** Whether the object tile should be flipped diagonally. **/
  public var flipDiagonally:Bool;
  /**
    The list of vertex points, relative to the object position.
    
    Only present for `kind = TPolygon` and `TPolyline`.
  **/
  public var vertices:Array<TmxPoint>;
  /**
    The text object rendering information.
    
    Only present for `kind = TText`.
  **/
  public var text:TextInfo;
  
  /** A reference to a template file from which it should inherit properties. **/
  public var template:String;
  
  #if (tiled_props=="project")
  public var tclass: TiledClass;
  #else
  /** The property list of this object. **/
  public var properties:Properties;
  #end
  
  /**
    An image tile corresponding to the object `gid`.
    
    Only present for `kind = TTile`.
  **/
  public var tile: TileImageType;
  
  public function new() {
    
  }
  
  /**
    Realigns the object position from specified alignment to new alignment.
    Usually original alignment is `BottomLeft` or `Bottom` depending on map orientation.
  **/
  public function realign(from:TmxObjectAlignment, to:TmxObjectAlignment, isIsometric:Bool = false) {
    if (from == to) return;
    #if tiled_rotation_degrees
    var cos = Math.cos(rotation * Math.PI / 180);
    var sin = Math.sin(rotation * Math.PI / 180);
    #else
    var cos = Math.cos(rotation);
    var sin = Math.sin(rotation);
    #end
    var x:Float = 0;
    var y:Float = 0;
    switch (from) {
      case Unspecified:
        if (isIsometric) x -= width / 2;
        y -= height;
      case TopLeft: // Do nothing
      case Top: x -= width / 2;
      case TopRight: x -= width;
      case Left: y -= height / 2;
      case Center: x -= width / 2; y -= height / 2;
      case Right: x -= width; y -= height / 2;
      case BottomLeft: y -= height;
      case Bottom: x -= width / 2; y -= height;
      case BottomRight: x -= width; y -= height;
    }
    switch (to) {
      case Unspecified:
        if (isIsometric) x += width / 2;
        y += height;
      case TopLeft: // Do nothing
      case Top: x += width / 2;
      case TopRight: x += width;
      case Left: y += height / 2;
      case Center: x += width / 2; y += height / 2;
      case Right: x += width; y += height / 2;
      case BottomLeft: y += height;
      case Bottom: x += width / 2; y += height;
      case BottomRight: x += width; y += height;
    }
    this.x += x * cos + y * -sin;
    this.y += x * sin + y * cos;
  }
  
  public function loadTemplate(tpl: TmxTemplate) {
    var obj = tpl.object;
    this.name = obj.name;
    this.type = obj.type;
    this.x = obj.x;
    this.y = obj.y;
    this.width = obj.width;
    this.height = obj.height;
    this.rotation = obj.rotation;
    this.visible = obj.visible;
    this.kind = obj.kind;
    this.gid = obj.gid;
    this.flipDiagonally = obj.flipDiagonally;
    this.flipHorizontally = obj.flipHorizontally;
    this.flipVertically = obj.flipVertically;
    this.vertices = obj.vertices; // Make a copy?
    this.text = obj.text; // Make a copy?
    this.tile = obj.tile;
    #if (tiled_props=="project")
    tclass = obj.tclass.transferToObject(this);
    #else
    properties.inherit(obj.properties);
    #end
  }
  
  // Load
  public function loadXML(x:Xml, loader:Tiled, path: String, ?tilesets:Array<TmxTileset>) {
    id = x.iatt('id');
    template = x.att('template', null);
    #if (tiled_props!="project")
    properties = new Properties();
    #end
    if (template == "") template = null;
    if (template != null) {
      var tpl = loader.loadTemplate(template, path);
      loadTemplate(tpl);
    }
    
    name = x.att('name', this.name);
    type = x.typeatt(this.type);
    this.x = x.fatt('x', this.x);
    this.y = x.fatt('y', this.y);
    width = x.fatt('width', this.width);
    height = x.fatt('height', this.height);
    #if tiled_rotation_degrees
    rotation = x.fatt('rotation', this.rotation);
    #else
    if (x.exists('rotation')) rotation = Std.parseFloat(x.get('rotation')) * Math.PI / 180;
    #end
    visible = x.batt('visible', this.visible);
    
    if (x.exists('gid')) {
      var gid:TmxTileIndex = TmxTileIndex.safeParse(x.get('gid'));
      this.gid = gid.gid;
      this.flipHorizontally = gid.flippedHorizontally;
      this.flipVertically = gid.flippedVertically;
      this.flipDiagonally = gid.flippedDiagonally;
      kind = TTile;
      #if (tiled_props=="project")
      var tileType: String = this.type;
      #else
      var inherit: Properties = null;
      #end
      if (tilesets != null) {
        var tile = tilesets.getTile(this.gid);
        if (tile != null) {
          if (type == "") type = tile.type;
          #if (tiled_props=="project")
          tileType = tile.type;
          tclass = tile.tclass.transferToObject(this);
          #else
          inherit = tile.properties;
          #end
          this.tile = tile.imageTile;
          // if (gid.hasFlipFlags()) {
          //   this.tile = tile.imageTile.clone();
          //   if (this.flipHorizontally) this.tile.flipX();
          //   if (this.flipVertically) this.tile.flipY();
          // }
        }
      }
      #if (tiled_props=="project")
      if (tclass == null || (type != "" && type != tileType))
        tclass = TiledProject.initWithFallback(TiledProject.objectFactory[type], this);
      #end
      
      for (el in x) {
        if (el.nodeType == Element && el.nodeName == "properties") {
          #if (tiled_props=="project")
          TiledProject.loadXMLProperties(tclass, el, loader, path);
          #else
          x.loadProps(properties, loader);
          #end
        }
      }
      #if (tiled_props!="project")
      if (inherit != null) properties.inherit(inherit, false);
      #end
    } else if (this.template == null) {
      // TODO: Figure out if template text can be modified
      kind = TRectangle;
      inline function parseVertices(x:Xml) {
        var data = x.att('points').split(' ');
        vertices = [];
        var idx;
        for (pt in data) {
          idx = pt.indexOf(',');
          vertices.push(new TmxPoint(Std.parseFloat(pt.substr(0, idx)), Std.parseFloat(pt.substr(idx+1))));
        }
      }
      for (el in x) {
        if (el.nodeType != Element) continue;
        switch (el.nodeName) {
          case 'properties':
            #if (tiled_props=="project")
            TiledProject.loadXMLProperties(tclass, el, loader, path);
            #else
            properties.loadXML(el, loader);
            #end
          case 'ellipse':
            kind = TEllipse;
          case 'point':
            kind = TPoint;
          case 'polygon':
            kind = TPolygon;
            parseVertices(el);
          case 'polyline':
            kind = TPolyline;
            parseVertices(el);
          case 'text':
            kind = TText;
            text = {
              fontFamily: el.att('fontfamily', 'sans-serif'),
              pixelSize: el.iatt('pixelsize', 16),
              wrap: el.batt('wrap'),
              color: el.catt('color'),
              bold: el.batt('bold'),
              italic: el.batt('italic'),
              underline: el.batt('underline'),
              strikeout: el.batt('strikeout'),
              kerning: el.batt('kerning'),
              halign: TextInfo.ALIGNS[el.att('halign', 'left')],
              valign: TextInfo.ALIGNS[el.att('halign', 'top')],
              text: el.firstChild().nodeValue
            }
        }
      }
    } else {
      // Load properties for templated object
      for (el in x) {
        if (el.nodeType == Element && el.nodeName == "properties") {
          #if (tiled_props=="project")
          TiledProject.loadXMLProperties(tclass, el, loader, path);
          #else
          properties.loadXML(el, loader);
          #end
        }
      }
    }
    #if (tiled_props=="project")
    if (tclass == null) tclass = TiledProject.initWithFallback(TiledProject.objectFactory[type], this);
    #else
    if (type != null && type != "") properties.inherit(loader.getObjectType(type));
    #end
  }
  
  // TODO: loadJson
  // TODO: loadBinary
  
  // TODO: saveBinary
  // TODO: saveJson
  // TODO: saveXML
  
}

@:structInit
class TextInfo {
  
  @:noCompletion
  public static var ALIGNS = ['left' => ALeft, 'right' => ARight, 'top' => ATop, 'bottom' => ABottom, 'center' => ACenter, 'justify' => AJustify];
  
  public var fontFamily:String;
  public var pixelSize:Int;
  public var wrap:Bool;
  public var color:Int;
  public var bold:Bool;
  public var italic:Bool;
  public var underline:Bool;
  public var strikeout:Bool;
  public var kerning:Bool;
  public var halign:TmxTextAlign;
  public var valign:TmxTextAlign;
  public var text:String;
  
}

enum TmxTextAlign {
  ALeft;
  ACenter;
  ARight;
  ATop;
  ABottom;
  AJustify;
}

/**
  The Tiled object kind.
**/
enum TmxObjectType {
  /**
    A tileset tile object.
  **/
  TTile;
  /**
    A polygonal shape.
  **/
  TPolygon;
  /**
    A polygonal open line.
  **/
  TPolyline;
  /**
    A single point.
    
    The `x` and `y` are used to determine the position of the point.
  **/
  TPoint;
  /**
    An ellipse shape.
    
    The `x`, `y`, `width` and `height` are used to determine the size of the ellipse.
  **/
  TEllipse;
  /**
    A rectangular shape.
    
    The `x`, `y`, `width` and `height` are used to determine the size of the rectangle.
  **/
  TRectangle;
  /**
    A block of text.
  **/
  TText;
}