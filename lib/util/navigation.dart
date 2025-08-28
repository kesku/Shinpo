import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Route<T> platformPageRoute<T>({
  required WidgetBuilder builder,
  RouteSettings? settings,
  bool fullscreenDialog = false,
}) {
  if (Platform.isIOS || Platform.isMacOS) {
    return CupertinoPageRoute<T>(
      builder: builder,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
    );
  }
  return MaterialPageRoute<T>(
    builder: builder,
    settings: settings,
    fullscreenDialog: fullscreenDialog,
  );
}
