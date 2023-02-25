package tiled.project;

typedef PropertyIterator = KeyValueIterator<String, RawPropertyValue>;

abstract RawPropertyValue(Dynamic) from String from PropertyIterator to String {
  
  @:to public inline function toInt(): Int {
    return Std.parseInt(this);
  }
  
  @:to public inline function toFloat(): Float {
    return Std.parseFloat(this);
  }
  
  @:to public inline function toBool(): Bool {
    return this == "true";
  }
  
  @:to public inline function toProps(): PropertyIterator {
    return this;
  }
  
}