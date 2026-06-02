import 'package:flutter/material.dart';
import 'package:kendo_os/presentation/match_router.dart';

class PublicRouter {
  static Widget getRoute(String routeName, String id) {
    switch (routeName) {
      case 'home':
        return const Scaffold(body: Center(child: Text('Public Home Screen')));
      case 'match':
      case 'viewer':
        return MatchRouter(matchId: id);
      case 'settings':
        return const Scaffold(
          body: Center(child: Text('Public Settings Screen')),
        );
      case 'manual':
        return const Scaffold(
          body: Center(child: Text('Public Manual Screen')),
        );
      default:
        return const Scaffold(
          body: Center(
            child: Text('🔒 Access Denied: Route outside public definition.'),
          ),
        );
    }
  }
}
