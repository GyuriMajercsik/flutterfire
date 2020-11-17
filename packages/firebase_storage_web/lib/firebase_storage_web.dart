// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase/firebase.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';
import 'package:flutter/services.dart'
    show MethodCall, MethodChannel, PlatformException, StandardMethodCodec;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Firebase storage web implementation
class FirebaseStorageWeb extends FirebaseStoragePlatform {
  /// registration method channel
  static void registerWith(Registrar registrar) {
    print('Registering with web');
    final MethodChannel channel = MethodChannel(
      'plugins.flutter.io/firebase_storage',
      const StandardMethodCodec(),
      registrar.messenger,
    );
    final FirebaseStorageWeb instance = FirebaseStorageWeb();
    channel.setMethodCallHandler(instance.handleMethodCall);
  }

  /// handling method calls
  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'uploadFileFromWeb':
        final String url = call.arguments['folderReference'];
        final String base64Content = call.arguments['base64Content'];
        final String fileName = call.arguments['fileName'];
        return _uploadFileFromWeb(url, fileName, base64Content);
      case 'removeFileFromWeb':
        final String url = call.arguments['fileUrl'];
        return _removeFileFromWeb(url);
      default:
        throw PlatformException(
            code: 'Unimplemented',
            details: "The url_launcher plugin for web doesn't implement "
                "the method '${call.method}'");
    }
  }

  @override
  Future<String> uploadFileFromWeb(
    String folderReference,
    String fileName,
    String base64Content,
  ) {
    return _uploadFileFromWeb(folderReference, fileName, base64Content);
  }

  /// removing from firebase storage
  Future<String> removeFileFromWeb(String fileUrl) {
    return _removeFileFromWeb(fileUrl);
  }

  /// returns the uploaded file's Firebase Storage URL
  Future<String> _uploadFileFromWeb(
    String folderReference,
    String fileName,
    String base64Content,
  ) async {
    var uploadTask =
        storage().ref(folderReference).child(fileName).putString(base64Content);

    var uploadTaskSnapshot = await uploadTask.future;
    if (uploadTaskSnapshot.state == firebase.TaskState.SUCCESS) {
      Uri downloadURL = await uploadTaskSnapshot.ref.getDownloadURL();
      return downloadURL.toString();
    }
    return null;
  }

  Future<dynamic> _removeFileFromWeb(String fileUrl) async {
    return storage().refFromURL(fileUrl).delete();
  }

  int get maxOperationRetryTime => Duration(minutes: 2).inMilliseconds;
  int get maxUploadRetryTime => Duration(minutes: 10).inMilliseconds;
  int get maxDownloadRetryTime => Duration(minutes: 10).inMilliseconds;

  @override
  FirebaseStoragePlatform delegateFor({FirebaseApp app, String bucket}) {
    return this;
  }
}
