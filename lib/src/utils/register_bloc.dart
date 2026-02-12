import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

extension RegisterBloc on GetIt {
  T registerBloc<T extends StateStreamableSource>(
    T instance, {
    String? instanceName,
  }) {
    return registerSingleton<T>(
      instance,
      dispose: (bloc) => bloc.close(),
    );
  }

  void registerLazyBloc<T extends StateStreamableSource>(
    FactoryFunc<T> factoryFunc, {
    String? instanceName,
  }) {
    registerLazySingleton<T>(
      factoryFunc,
      dispose: (bloc) => bloc.close(),
    );
  }

  T registerBlocIfAbsent<T extends StateStreamableSource>(
    T instance, {
    String? instanceName,
  }) {
    return !isRegistered<T>()
      ? registerBloc<T>(
          instance,
          instanceName: instanceName,
        )
      : get<T>();
  }

  void registerLazyBlocIfAbsent<T extends StateStreamableSource>(
    FactoryFunc<T> factoryFunc, {
    String? instanceName,
  }) {
    if (!isRegistered<T>()) {
      registerLazyBloc<T>(
        factoryFunc,
        instanceName: instanceName,
      );
    }
  }
}
