import Foundation

public class Factory<T> {

  public typealias CreateClosure = (attributes: [String: Any]) -> T
  public typealias AttributeClosure = (options: [String: Any]) -> Any
  public typealias OptionClosure = () -> Any
  public typealias AfterClosure = (item: T, options: [String: Any]) -> Void
  public typealias SequenceClosure = (Int) -> Any

  let create: CreateClosure
  var sequence: Int = 1
  var attributes: [String: AttributeClosure] = [:]
  var options: [String: OptionClosure] = [:]
  var after: [AfterClosure] = []

  public init(_ create: CreateClosure) {
    self.create = create
  }

  /// Defines an attribute that has a random UUID String assign to it.
  ///
  /// - parameter key: the key to set a UUIDv5
  /// - returns: It self
  public func uuid(key: String) -> Self {
    self.attr(key) { _ in
      return NSUUID().UUIDString
    }
    return self
  }

  /// Defines an attribute that will auto-increment every time it gets 
  /// generated, useful for identifiers you want to be unique. The sequence 
  /// will be unique per factory.
  ///
  /// Supports an optional closure, if provided, the closure’s result will be 
  /// used as the attribute value. The sequence value, will be passed in as the 
  /// first argument. Useful if you want predictable unique string values.
  ///
  /// - parameter key: attribute name
  /// - parameter closure: optional closure, its result will be used as the 
  ///   attribute value
  /// - returns: It self
  public func sequence(key: String, closure: SequenceClosure? = nil) -> Self {
    self.attr(key) { _ in
      let sequence = self.sequence
      self.sequence += 1
      if let closure = closure {
        return closure(sequence)
      }
      return sequence
    }
    return self
  }

  /// Defines an attribute
  /// 
  /// - parameter key: attribute name
  /// - parameter value: attribute value
  /// - returns: It self
  public func attr(key: String, value: Any) -> Self {
    self.attributes[key] = { _ in value }
    return self
  }

  /// Defines an attribute, that uses the passed in closure to generate the 
  /// value, it will be invoked everytime `build` is called.
  ///
  /// - parameter key: attribute name
  /// - parameter closure: closure to generate the attribute value
  /// - returns: It self
  public func attr(key: String, closure: AttributeClosure) -> Self {
    self.attributes[key] = closure
    return self
  }

  /// Defines an option that will be available when creating dynamic attributes,
  /// and in `after` callbacks.
  ///
  /// - parameter key: attribute name
  /// - parameter value: option value, if this is an `OptionClosure` it will be 
  ///   invoked instead of returned
  /// - returns: It self
  public func option(key: String, @autoclosure(escaping) value: OptionClosure) -> Self {
    self.options[key] = value
    return self
  }

  /// Adds a callback that will be invoked after the model is created, and 
  /// before it is return in by the `build` function.
  ///
  /// - parameter callback: callback to be invoked right after creating the 
  ///   object
  /// - returns: It self
  public func after(callback: AfterClosure) -> Self {
    self.after.append(callback)
    return self
  }

  /// Builds the object
  ///
  /// - parameter attributes: additional attributes
  /// - parameter options: additional options
  /// - returns: The built object
  public func build(attributes: [String: Any] = [:], options: [String: Any] = [:]) -> T {
    let options = self.options(options)
    let attributes = self.attributes(attributes, options: options)
    let item = self.create(attributes: attributes)
    for callback in self.after {
      callback(item: item, options: options)
    }
    return item
  }

  func attributes(var attributes: [String: Any], options: [String: Any]) -> [String: Any] {
    for (key, value) in self.attributes where attributes[key] == nil {
      attributes[key] = value(options: options)
    }
    return attributes
  }

  func options(var options: [String: Any]) -> [String: Any] {
    for (key, value) in self.options where options[key] == nil {
      options[key] = value()
    }
    return options
  }

}