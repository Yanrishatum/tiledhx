package tiled.types;

// TODO: Json schema
typedef TmxJsonObject = {
  var id:Int;
  var name:String;
  var type:String;
  
  var x:Float;
  var y:Float;
  var height:Float;
  var width:Float;
  var rotation:Float;
  var visible:Bool;
  
  var gid:Int;
  var ellipse:Bool;
  var point:Bool;
  var polygon:Array<TmxJsonPoint>;
  var polyline:Array<TmxJsonPoint>;
  var text:TmxJsonText;
  
  var properties:Array<TmxJsonProperty>;
  var template:String;
}

typedef TmxJsonText = {
  var fontfamily:String;
  var pixelsize:Int;
  var color:String;
  var text:String;
  
  var wrap:Bool;
  var bold:Bool;
  var italic:Bool;
  var underline:Bool;
  var strikeout:Bool;
  var kerning:Bool;
  
  var halign:String;
  var valign:String;
}

typedef TmxJsonProperty = {
  var name:String;
  var type:TiledPropertyMemberKind;
  @:optional var value:Dynamic;
  @:optional var propertyType:String;
}

typedef TmxJsonPoint = {
  var x:Float;
  var y:Float;
}

// 1.9+ properties/project
typedef TiledProjectFile = {
  var automappingRulesFile: String;
  var commands: Array<Dynamic>;
  var extensionsPath: String;
  var folders: Array<String>;
  var propertyTypes: Array<TiledPropertyType>;
}

private typedef TiledPropertyTypeBase = {
  var id: Int;
  var name: String;
  var type: TiledPropertyKind;
}

private typedef TiledPropertyTypeEnum = {
  /** Only present on enum properties. **/
  @:optional var storageType: TiledEnumStorageKind;
  /** Only present on enum properties. **/
  @:optional var values: Array<String>;
  /** Only present on enum properties. **/
  @:optional var valuesAsFlags: Bool;
}

private typedef TiledPropertyTypeClass = {
  /**
    Only present on class properties.
    
    "#AARRGGBB" / "#RRGGBB" format.
  **/
  @:optional var color: String;
  /** Only present on class properties. **/
  @:optional var members: Array<TmxJsonProperty>;
  /** Only present on class properties. **/
  @:optional var useAs: Array<TiledClassUseAs>;
}

typedef TiledPropertyType = TiledPropertyTypeBase & TiledPropertyTypeEnum & TiledPropertyTypeClass;
typedef TiledClassDescriptor = TiledPropertyTypeBase & TiledPropertyTypeClass;
typedef TiledEnumDescriptor = TiledPropertyTypeBase & TiledPropertyTypeEnum;

enum abstract TiledPropertyMemberKind(String) from String to String {
  var KClass = "class";
  var KFile = "file";
  var KBool = "bool";
  var KFloat = "float";
  var KInt = "int";
  var KObject = "object";
  var KColor = "color";
  var KString = "string";
}

enum abstract TiledClassUseAs(String) {
  var UAProperty = "property";
  var UAMap = "map";
  var UALayer = "layer";
  var UAObject = "object";
  var UATile = "tile";
  var UATileset = "tileset";
  var UAWangcolor = "wangcolor";
  var UAWangset = "wangset";
}

enum abstract TiledPropertyKind(String) {
  var KClass = "class";
  var KEnum = "enum";
}

enum abstract TiledEnumStorageKind(String) {
  var KInt = "int";
  var KString = "string";
}