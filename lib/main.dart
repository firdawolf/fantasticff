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
    // This schedules a callback to be executed after the first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestPermissions();
    });
  }

  /// Checks the status of required permissions and requests them if needed.
  /// If permanently denied, it shows a dialog to open settings.
  Future<void> _checkAndRequestPermissions() async {
    // A map of permissions we need to check.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission
          .locationWhenInUse, // More common and user-friendly than .location
    ].request();

    // bool isPermanentlyDenied = statuses.values.any(
    //   (status) => status.isPermanentlyDenied,
    // );

    // if (isPermanentlyDenied) {
    //   if (mounted) showAlertDialog(context);
    // }
    // if (mounted) showAlertDialog(context);
  }

  showAlertDialog(context) => showCupertinoDialog<void>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('Permission Denied'),
      content: const Text('Allow access to Camera and Location'),
      actions: <CupertinoDialogAction>[
        CupertinoDialogAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,

          onPressed: () => openAppSettings(),
          child: const Text('Open Settings'),
        ),
      ],
    ),
  );

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
          'Location permission is necessary to provide accurate navigation and location-based services. Please enable it in app settings.';
    }

    // Ensure the context is available and mounted before showing a dialog.
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('$permissionName Permission Required'),
            content: Text(content),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Open Settings'),
                onPressed: () {
                  // This function from permission_handler opens the app's settings screen.
                  openAppSettings();
                  Navigator.of(context).pop();
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
              if (resource == PermissionResourceType.CAMERA) {
                permissionsToRequest.add(Permission.camera);
              }
            }

            Map<Permission, PermissionStatus> statuses =
                await permissionsToRequest.request();

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
