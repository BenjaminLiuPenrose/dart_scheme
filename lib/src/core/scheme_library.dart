library cs61a_scheme.core.scheme_library;

import 'expressions.dart';

/// An interface for defining a collection of built-in Scheme procedures.
///
/// Used loading Dart functions (and other values originating from Dart code)
/// into a Scheme environment. [importAll] should bind all of the library's
/// names in the provided environment.
///
/// The other import functions load one or more of the bindings by first
/// importing all bindings into a child of the provided environment and then
/// copying the selected names over.
///
/// This should almost always be used with the @library annotation to easily
/// add built-in procedures.
abstract class SchemeLibrary {
  /// Loads all bindings.
  ///
  /// If you override and use @library, you should make sure to call super.
  void importAll(Frame env) {
    throw UnimplementedError();
  }

  /// Loads only the single named binding into env.
  void importSingle(Frame env, SchemeSymbol name) {
    import(env, [name]);
  }

  /// Loads only the listed bindings into env.
  void import(Frame env, Iterable<SchemeSymbol> names) {
    Frame inner = Frame(env, env.interpreter);
    importAll(inner);
    for (var name in names) {
      if (inner.bindings.containsKey(name)) {
        env.define(name, inner.bindings[name]);
      }
    }
  }
}

/// Annotation on a SchemeLibrary to generate [importAll].
///
/// When present, all methods within the class that do not start with "import"
/// or an underscore will be added as built-in procedures.
const _Library schemelib = _Library();

class _Library {
  const _Library();
}

/// Annotation to make an OperandBuiltinProcedure.
///
/// This procedure is defined in the extra library, so don't use this inside
/// the core library.
const _NoEval noeval = _NoEval();

class _NoEval {
  const _NoEval();
}

/// Annotation to call turtle.show().
///
/// This may only be used inside of TurtleLibrary.
const _Turtle turtlestart = _Turtle();

class _Turtle {
  const _Turtle();
}

/// Annotation to specify a name other than the function name for the
/// Scheme binding.

/// Annotation to specify MinArgs when built-in takes a list.
/// If not set, defaults to 0 (no minimum)
class MinArgs {
  final int value;
  const MinArgs(this.value);
}

/// Annotation to specify MaxArgs when built-in takes a list.
/// If not set, defaults to -1 (no maximum)
class MaxArgs {
  final int value;
  const MaxArgs(this.value);
}

/// Annotation to trigger event after evaluation, passing a pair of the
/// return value and the current environment.
class TriggerEventAfter {
  final SchemeSymbol id;
  const TriggerEventAfter(this.id);
}
