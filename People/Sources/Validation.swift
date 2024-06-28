import ComposableArchitecture
import SwiftUI

enum ValidationKey<Model>: Hashable {
  case model
  case key(PartialKeyPath<Model>)
}

@ObservableState
struct ValidationResult: Equatable {
  static let valid = ValidationResult()
  
  private(set) var isValid = true
  var error: LocalizedStringKey? {
    errors.first
  }
  
  var errors: [LocalizedStringKey] = [] {
    didSet {
      isValid = errors.isEmpty
    }
  }
}

@ObservableState
@dynamicMemberLookup
struct ValidationState<Model>: Equatable {
  var allValid: Bool {
    validations.values.allSatisfy { $0.errors.isEmpty }
  }
  private var validations: [ValidationKey<Model>: ValidationResult] = [:]
  
  subscript(key: ValidationKey<Model>) -> ValidationResult {
    get { validations[key] ?? .valid }
    set { validations[key] = newValue }
  }
  
  subscript<Value>(keyPath: KeyPath<Model, Value>) -> ValidationResult {
    get { self[.key(keyPath)] }
    set { self[.key(keyPath)] = newValue }
  }
  
  subscript<Value>(dynamicMember keyPath: KeyPath<Model, Value>) -> ValidationResult {
    get { self[keyPath] }
    set { self[keyPath] = newValue }
  }
  
  mutating func validate(_ model: Model, with validator: Validate<Model>) {
    validations = validations.mapValues { _ in .valid }
    validator.validate(model, &self)
  }
 
  mutating func validate(_ model: Model, @ValidationBuilder<Model> with build: () -> Validate<Model>) {
    validate(model, with: build())
  }
  
  mutating func validate(_ model: Model, @ValidationBuilder<Model> with build: (ModelProxy<Model>) -> Validate<Model>) {
    validate(model, with: build(.init()))
  }
}

@resultBuilder
struct ValidationBuilder<Model> {
  static func buildBlock(_ components: Validate<Model>...) -> Validate<Model> {
    Validate { model, state in
      for component in components {
        component.validate(model, &state)
      }
    }
  }
}

struct Validate<Model> {
  typealias Validation = (Model, inout ValidationState<Model>) -> Void
  let validate: Validation
  
  init(validate: @escaping Validation) {
    self.validate = validate
  }
  
  init(@ValidationBuilder<Model> build: () -> Validate<Model>) {
    self = build()
  }
  
  init(@ValidationBuilder<Model> build: (ModelProxy<Model>) -> Validate<Model>) {
    self = build(.init())
  }
}

enum Validity: Equatable {
  case valid
  case invalid
}

struct ModelValidator<Model> {
  typealias Validation = (Model) -> Validity
  let validationKey: ValidationKey<Model>
  let validate: Validation
  
  init(validationKey: ValidationKey<Model> = .model, validate: @escaping Validation) {
    self.validationKey = validationKey
    self.validate = validate
  }
  
  init<Value>(keyPath: KeyPath<Model, Value>, validate: @escaping Validation) {
    self.init(validationKey: .key(keyPath), validate: validate)
  }
  
  func `else`(_ error: LocalizedStringKey) -> Validate<Model> {
    .init { model, validations in
      if validate(model) == .invalid {
        validations[validationKey].errors.append(error)
      }
    }
  }
}

@resultBuilder
struct ModelValidatorBuilder<Model> {
  static func buildBlock(_ components: [ModelValidator<Model>]...) -> [ModelValidator<Model>] {
    components.flatMap { $0 }
  }
  static func buildExpression(_ expression: ModelValidator<Model>) -> [ModelValidator<Model>] {
    [expression]
  }
}

struct FieldProxy<Model, Value> {
  let keyPath: KeyPath<Model, Value>
}

extension FieldProxy where Value == String {
  var isNotEmpty: ModelValidator<Model> {
    .init(keyPath: keyPath) { model in
      model[keyPath: keyPath].isEmpty ? .invalid : .valid
    }
  }
  func count(greaterThanOrEqualTo minimumCount: Int) -> ModelValidator<Model> {
    .init(keyPath: keyPath) { model in
      model[keyPath: keyPath].count >= minimumCount ? .valid : .invalid
    }
  }
  func contains(_ substring: any StringProtocol) -> ModelValidator<Model> {
    .init(keyPath: keyPath) { model in
      model[keyPath: keyPath].range(of: substring) == nil ? .invalid : .valid
    }
  }
  func doesNotContain(_ substring: any StringProtocol) -> ModelValidator<Model> {
    .init(keyPath: keyPath) { model in
      model[keyPath: keyPath].range(of: substring) == nil ? .valid : .invalid
    }
  }
}

@dynamicMemberLookup
struct ModelProxy<Model> {
  subscript<Value>(dynamicMember keyPath: KeyPath<Model, Value>) -> FieldProxy<Model, Value> {
    FieldProxy(keyPath: keyPath)
  }
}

