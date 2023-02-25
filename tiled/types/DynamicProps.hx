package tiled.types;

/**
  An object type defined by the `objecttypes.xml` file.
  
  1.9+: Defined in .tiled-project
**/
@:structInit
class TmxDynamicClass {
  
  /**
    The shape/outline color of the object type.
  **/
  public var color:Int;
  /**
    Additional default properties of the object type.
  **/
  public var properties:Properties;
  
}

@:structInit
class TmxDynamicEnum {
  /**
    Whether the enum is stored as string.
  **/
  public var isString: Bool;
  /**
    Whether the enum is multi-choice/flags.
    
    For string enums they are stored as comma-separated strings.
    For int enums they are stored as bitmask.
  **/
  public var isFlags: Bool;
  
  #if tiled_metadata
  public var names: Array<String>;
  #end
}