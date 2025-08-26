import 'package:flutter/cupertino.dart';

/// A GlobalKey to access context outside of widget tree
final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

/// Using a NavigatorObserver to track route changes, notify listeners and to know if route exists in backstack or not
final AppNavigatorObserver routeObserver = AppNavigatorObserver();

class AppNavigatorObserver extends NavigatorObserver {
  static final AppNavigatorObserver _instance =
      AppNavigatorObserver._internal();
  final Set<RouteAware> _listeners = <RouteAware>{};

  factory AppNavigatorObserver() {
    return _instance;
  }

  AppNavigatorObserver._internal();

  final List<Route<dynamic>> _routeStack = <Route<dynamic>>[];

  void subscribe(RouteAware routeAware) {
    _listeners.add(routeAware);
  }

  void unsubscribe(RouteAware routeAware) {
    _listeners.remove(routeAware);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _routeStack.add(route);
    for (RouteAware listener in _listeners) {
      listener.didPush();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _routeStack.remove(route);
    for (RouteAware listener in _listeners) {
      listener.didPop();
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _routeStack.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) {
      _routeStack.remove(oldRoute);
    }
    if (newRoute != null) {
      _routeStack.add(newRoute);
    }
  }

  ///call this function to check if Route exist in backstack or not
  ///
  ///ex: AppNavigatorObserver.doesPageExist(Routes.homePage) //returns true if /home exits in backstack otherwise returns false
  bool doesPageExist(String routeName) {
    return _routeStack.any((Route<dynamic> route) => route.settings.name == routeName);
  }


  /// This function returns list of screens on the backstack
  List<String> getRouteNames() {
    return _routeStack
        .map((Route<dynamic> route) => route.settings.name ?? 'Unnamed Route')
        .toList();
  }

  bool isCurrentPage(String routeName){
    if(_routeStack.isEmpty){
      return false;
    }
    return _routeStack.last.settings.name == routeName;
  }

  bool isPreviousPage(String routeName){
    if(_routeStack.isEmpty){
      return false;
    }
    return _routeStack[_routeStack.length - 2].settings.name == routeName;
  }

}
