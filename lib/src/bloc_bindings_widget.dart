import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import 'bloc_binding.dart';
export 'bloc_binding.dart';

/// [BlocBindingsWidget] provides a convenient way to handle providing,
/// listening and watching for multiple blocs state changes.
///
/// Each bloc is defined using [BlocBinding] which aggregates an interfaces
/// of [BlocProvider], [BlocListener]. A separate variation for handling
/// bloc presentation events is provided by [BlocBindingWithPresentation].
///
/// [BlocBindingsWidget] uses get_it for managing blocs lifecycle instead of
/// using a more common way of handling it using [BlocProvider] `create`
/// method which handles bloc disposal automatically. This leads to a way
/// more convenient way to access all blocs without a need for BuildContext.
///
/// To use [BlocBindingsWidget] one should inherit from it and override
/// [bindings] getter to provide all required bindings to be scoped.
///
/// Bloc for any binding can be provided in 3 different ways:
/// - by using existing `value` (same as [BlocProvider.value]);
/// - by using `create` function, in this case bloc will be created in
/// the current scope when element is mounted to the tree and disposed
/// when element is unomounted (same as [BlocProvider] `create`))
/// - by not providing either `value` nor `create`, in this case bloc
/// will be looked up in scopes of all ancestors, which is an alternative
/// for `context.read` approach.
abstract class BlocBindingsWidget extends StatelessWidget {
  const BlocBindingsWidget({
    required GlobalKey key,
  }) : super(key: key);

  List<BlocBinding> get bindings;

  B blocs<B extends StateStreamableSource>([String? id]) =>
    ((key as GlobalKey).currentContext as _BlocsBindingsElement).blocs<B>(id);

  @override
  StatelessElement createElement() => _BlocsBindingsElement(this);
}

class _BlocsBindingsElement extends StatelessElement {
  _BlocsBindingsElement(super.widget);

  final scope = GetIt
   .asNewInstance()
   ..enableRegisteringMultipleInstancesOfOneType();
  final List<GetIt> ancestors = [];

  late final List<BlocBinding> bindings;

  @override
  void mount(Element? parent, dynamic newSlot) {
    final widget = this.widget as BlocBindingsWidget;

    parent?.visitAncestorElements((element) {
      if (element is _BlocsBindingsElement) {
        ancestors.add(element.scope);
      }
      return true;
    });
    ancestors.add(GetIt.I);

    bindings = List.from(widget.bindings);

    if (bindings.isNotEmpty) {
      for (final binding in bindings) {
        if (binding.create != null) {
          binding.register(scope);
        }
      }
    }

    super.mount(parent, newSlot);
  }

  @override
  void unmount() {
    scope.reset();
    super.unmount();
  }

  @override
  Widget build() {
    return providers(
      presentationListeners(
        listeners(
          Builder(builder: (context) {
            watch(context);
            return super.build();
          }),
        ),
      ),
    );
  }

  B blocs<B extends StateStreamableSource>([String? id]) {
    final binding = bindings.where(
      (binding) => (binding.blocType == B) && (binding.id == id),
    ).firstOrNull as BlocBinding<B, dynamic>?;

    if (binding == null) {
      throw BlocBindingNotFoundException(B);
    }

    return binding.value ?? binding.findInScopes(ancestors)!;
  }

  Widget providers(Widget child) {
    final providers = bindings.map(
      (binding) => binding.blocProvider,
    ).nonNulls.toList();

    return (providers.isNotEmpty)
      ? MultiBlocProvider(
          providers: providers,
          child: child,
        )
      : child;
  }

  Widget listeners(Widget child) {
    final listeners = bindings.map(
      (binding) => binding.blocListener,
    ).nonNulls.toList();

    return (listeners.isNotEmpty)
      ? MultiBlocListener(
          listeners: listeners,
          child: child,
        )
      : child;
  }

  Widget presentationListeners(Widget child) {
    final presentationListeners = bindings.whereType<BlocBindingWithPresentation>().map(
      (provider) => provider.blocPresentationListener,
    ).nonNulls.toList();

    return (presentationListeners.isNotEmpty)
      ? MultiProvider(
          providers: presentationListeners,
          child: child,
        )
      : child;
  }

  void watch(BuildContext context) {
    for (final binding in bindings) {
      if (binding.watch) {
        binding.watchBloc(context);
      }
    }
  }
}