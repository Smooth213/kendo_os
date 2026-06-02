import 'package:flutter/material.dart';

class InternalRouter {
  static Widget getRoute(String routeName) {
    switch (routeName) {
      case 'observability-dashboard':
        return const Scaffold(
          body: Center(child: Text('Internal Observability Dashboard')),
        );
      case 'audit-log':
        return const Scaffold(body: Center(child: Text('Internal Audit Log')));
      case 'rule-config':
        return const Scaffold(
          body: Center(child: Text('Internal Rule Config Panel')),
        );
      case 'master-management':
        return const Scaffold(
          body: Center(child: Text('Internal Master Management')),
        );
      default:
        return const Scaffold(
          body: Center(
            child: Text('🔒 Access Denied: Unknown internal privilege target.'),
          ),
        );
    }
  }
}
