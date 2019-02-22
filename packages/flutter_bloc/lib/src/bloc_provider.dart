import 'package:flutter/material.dart';

import 'package:bloc/bloc.dart';

/// A Flutter widget which provides a bloc to its children via `BlocProvider.of(context)`.
/// It is used as a DI widget so that a single instance of a bloc can be provided
/// to multiple widgets within a subtree.
class BlocProvider<T extends Bloc<dynamic, dynamic>> extends InheritedWidget {
  /// The [Bloc] which is to be made available throughout the subtree
  final T bloc;

  /// The [Widget] and its descendants which will have access to the [Bloc].
  final Widget child;

  BlocProvider({
    Key key,
    @required this.bloc,
    this.child,
  })  : assert(bloc != null),
        super(key: key);

  /// Method that allows widgets to access the bloc as long as their `BuildContext`
  /// contains a `BlocProvider` instance.
  static T of<T extends Bloc<dynamic, dynamic>>(BuildContext context) {
    final type = _typeOf<BlocProvider<T>>();
    final BlocProvider<T> provider =
        context.ancestorInheritedElementForWidgetOfExactType(type)?.widget;

    if (provider == null) {
      throw FlutterError(
          'BlocProvider.of() called with a context that does not contain a Bloc of type $T.\n'
          'No ancestor could be found starting from the context that was passed '
          'to BlocProvider.of<$T>(). This can happen '
          'if the context you use comes from a widget above the BlocProvider.\n'
          'The context used was:\n'
          '  $context');
    }
    return provider?.bloc;
  }

  /// Clone the current [BlocProvider] with a new child [Widget].
  /// All other values, including [Key] and [Bloc] are preserved.
  BlocProvider<T> copyWith(Widget child) {
    return BlocProvider<T>(
      key: key,
      bloc: bloc,
      child: child,
    );
  }

  /// Necessary to obtain generic [Type]
  /// https://github.com/dart-lang/sdk/issues/11923
  static Type _typeOf<T>() => T;

  @override
  bool updateShouldNotify(BlocProvider oldWidget) => false;
}

/// A [BlocProvider] that merges multiple [BlocProvider] widgets into one.
///
/// [BlocProviderTree] improves the readability and eliminates the need
/// to nest multiple [BlocProviders].
///
/// By using [BlocProviderTree] we can go from:
///
/// ```dart
/// BlocProvider<BlocA>(
///   bloc: BlocA(),
///   child: BlocProvider<BlocB>(
///     bloc: BlocB(),
///     child: BlocProvider<BlocC>(
///       value: BlocC(),
///       child: ChildA(),
///     )
///   )
/// )
/// ```
///
/// to:
///
/// ```dart
/// BlocProviderTree(
///   blocProviders: [
///     BlocProvider<BlocA>(bloc: BlocA()),
///     BlocProvider<BlocB>(bloc: BlocB()),
///     BlocProvider<BlocC>(bloc: BlocC()),
///   ],
///   child: ChildA(),
/// )
/// ```
///
/// [BlocProviderTree] converts the [BlocProvider] list
/// into a tree of nested [BlocProvider] widgets.
/// As a result, the only advantage of using [BlocProviderTree] is improved
/// readability due to the reduction in nesting.
class BlocProviderTree extends StatelessWidget {
  /// The [BlocProvider] list which is converted into a tree of [BlocProvider] widgets.
  /// The tree of [BlocProvider] widgets is created in order meaning the first [BlocProvider]
  /// will be the top-most [BlocProvider] and the last [BlocProvider] will be the parent
  /// of the `child` [Widget].
  final List<BlocProvider> blocProviders;

  /// The [Widget] and its descendants which will have access every [Bloc] provided by `blocProviders`.
  /// This [Widget] will be a direct descendent of the last [BlocProvider] in `blocProviders`.
  final Widget child;

  BlocProviderTree({
    Key key,
    @required this.blocProviders,
    @required this.child,
  })  : assert(blocProviders != null),
        assert(child != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget tree = child;
    for (final blocProvider in blocProviders.reversed) {
      tree = blocProvider.copyWith(tree);
    }
    return tree;
  }
}
