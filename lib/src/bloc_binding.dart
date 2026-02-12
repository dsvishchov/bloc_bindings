import 'package:bloc_presentation/bloc_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'utils/register_bloc.dart';

class BlocBinding<B extends StateStreamableSource<S>, S> {
  BlocBinding({
    this.id,
    this.value,
    this.create,
    this.listener,
    this.listenWhen,
  });

  final String? id;
  final B Function()? create;
  B? value;
  final BlocWidgetListener<S>? listener;
  final BlocListenerCondition<S>? listenWhen;

  void register(GetIt scope) {
    value = scope.registerBloc<B>(
      create!(),
      instanceName: id
    );
  }

  B? findInScopes(List<GetIt> scopes) {
    return scopes.where(
      (scope) => scope.isRegistered<B>(instanceName: id),
    ).firstOrNull?.get<B>();
  }

  BlocProvider<B>? get blocProvider {
    if (value != null) {
      return BlocProvider<B>.value(
        value: value!,
      );
    }
    return null;
  }

  BlocListener<B, S>? get blocListener {
    if (listener != null) {
      return BlocListener<B, S>(
        listener: listener!,
        listenWhen: listenWhen,
      );
    }
    return null;
  }

  void watch(BuildContext context) => context.watch<B>();

  Type get blocType => B;
  Type get stateType => S;
}

/// Extends [BlocBinding] by also providing support for presentation events via [BlocPresentationListener]
class BlocBindingWithPresentation<B extends BlocPresentationMixin<S, E>, S, E> extends BlocBinding<B, S> {
  BlocBindingWithPresentation({
    super.id,
    super.value,
    super.create,
    super.listener,
    super.listenWhen,
    this.presentationListener,
  });

  final BlocPresentationWidgetListener<E>? presentationListener;

  BlocPresentationListener<B, E>? get blocPresentationListener {
    if (presentationListener != null) {
      return BlocPresentationListener<B, E>(
        listener: presentationListener!,
      );
    }
    return null;
  }

  Type get presentationEventType => E;
}

class BlocBindingNotFoundException implements Exception {
  BlocBindingNotFoundException(this.blocType);

  final Type blocType;

  @override
  String toString() => 'Could not find binding for $blocType';
}