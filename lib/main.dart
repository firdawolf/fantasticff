import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  // It's important to ensure Flutter bindings are initialized before using them.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Removed the camera permission request from here
    // Only request location permission upfront if needed for your app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationPermission();
      _checkCameraPermission();
    });
  }

  /// Only check location permission if you need it immediately
  /// Remove this if you want location to also be on-demand
  Future<void> _checkLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isPermanentlyDenied) {
      if (mounted) _showSettingsDialog(Permission.locationWhenInUse);
    }
  }

  Future<void> _checkCameraPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final cameraStatus = statuses[Permission.camera];

    if (cameraStatus != null && cameraStatus.isPermanentlyDenied) {
      if (mounted) {
        _showSettingsDialog(Permission.camera);
      }
    }
  }

  /// Shows a dialog explaining why the permission is needed and provides a
  /// button to open the app settings.
  void _showSettingsDialog(Permission permission) {
    String permissionName = '';
    String content = '';

    // Customize the message based on the permission.
    if (permission == Permission.camera) {
      permissionName = 'Camera';
      content =
          'Camera permission is required to scan QR codes and other features. Please enable it in app settings.';
    } else if (permission == Permission.locationWhenInUse ||
        permission == Permission.location) {
      permissionName = 'Location';
      content =
          'Location permission is necessary to provide accurate navigation to user so it can be view on the map screen';
    }

    // Ensure the context is available and mounted before showing a dialog.
    if (mounted) {
      showCupertinoDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text('$permissionName Permission Required'),
            content: Text(content),
            actions: <CupertinoDialogAction>[
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Open Settings'),
                onPressed: () {
                  Navigator.of(context).pop();
                  // This function from permission_handler opens the app's settings screen.
                  openAppSettings();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri("https://fantasticff.my")),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            geolocationEnabled: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
          ),
          // This handler is for permission requests initiated by the web page.
          onPermissionRequest: (controller, request) async {
            List<Permission> permissionsToRequest = [];

            for (final resource in request.resources) {
              // if (resource == PermissionResourceType.CAMERA) {
              //   permissionsToRequest.add(Permission.camera);
              // } else if (resource == PermissionResourceType.MICROPHONE) {
              //   permissionsToRequest.add(Permission.microphone);
              // }
              // Add other permissions as needed
            }

            if (permissionsToRequest.isEmpty) {
              // If no permissions we handle, allow by default
              return PermissionResponse(
                resources: request.resources,
                action: PermissionResponseAction.GRANT,
              );
            }

            // Request the permissions
            Map<Permission, PermissionStatus> statuses =
                await permissionsToRequest.request();

            // Check if any permission was permanently denied
            bool hasPermanentlyDenied = statuses.entries.any(
              (entry) => entry.value.isPermanentlyDenied,
            );

            // Show settings dialog for permanently denied permissions
            if (hasPermanentlyDenied) {
              for (final entry in statuses.entries) {
                if (entry.value.isPermanentlyDenied) {
                  _showSettingsDialog(entry.key);
                  break; // Show dialog for first permanently denied permission
                }
              }
            }

            // Check if all requested permissions are granted
            bool allGranted = statuses.values.every(
              (status) => status.isGranted,
            );

            return PermissionResponse(
              resources: request.resources,
              action: allGranted
                  ? PermissionResponseAction.GRANT
                  : PermissionResponseAction.DENY,
            );
          },

          // This handler is for geolocation requests initiated by the web page.
          onGeolocationPermissionsShowPrompt:
              (InAppWebViewController controller, String origin) async {
                final status = await Permission.locationWhenInUse.request();

                if (status.isGranted) {
                  return GeolocationPermissionShowPromptResponse(
                    origin: origin,
                    allow: true,
                    retain: true,
                  );
                }

                if (status.isPermanentlyDenied) {
                  _showSettingsDialog(Permission.locationWhenInUse);
                }

                return GeolocationPermissionShowPromptResponse(
                  origin: origin,
                  allow: false,
                  retain: false,
                );
              },
        ),
      ),
    );
  }
}
