part of '../leaf_webview.dart';

enum LFWebViewEventType {
  mailto,
  tel,
  geo,
}

typedef LFWebViewOnBeforeLoaded = Function();
typedef LFWebViewOnLoaded = Function();
typedef LFWebViewOnLoaderBuilder = Widget Function();
typedef LFWebViewOnCreateWebViewController = Function(
    WebViewController webViewController);
typedef LFWebViewOnPageStarted = Function();
typedef LFWebViewOnPageFinished = Function();
typedef LFWebViewOnHeightFinished = Function(double height);
typedef LFWebViewOnNavigationDecision = bool Function(
    LFWebViewEventType? type, String url);
typedef LFWebViewOnUrlChange = Function(String? url);
typedef LFWebViewOnHttpError = Function(HttpResponseError error);
typedef LFWebViewOnJavaScriptAlertDialogIOS = Future<bool?> Function(
    JavaScriptAlertDialogRequest request);
typedef LFWebViewOnJavaScriptConfirmDialogIOS = Future<bool?> Function(
    JavaScriptConfirmDialogRequest request);
typedef LFWebViewOnJavaScriptTextInputDialogIOS = Future<String?> Function(
    JavaScriptTextInputDialogRequest request);

class LFWebView extends StatefulWidget {
  final LFWebViewController controller;
  final Uri? uri;
  final String? htmlString;
  final String? htmlFile;
  final String? assetFile;
  final bool fullScreen;
  final double initHeight;
  final Color backgroundColor;
  final bool allowAllowOrientation;
  final bool allowsBackForwardNavigationGestures;
  final bool useHybridComposition;
  final bool isInspectable;

  /// Opt-in loading overlay recovery (SAZO fork). When false (default) the
  /// behavior is identical to upstream v2.4.5-dev+2. When true:
  /// - main-frame web resource errors release the loading overlay,
  /// - a JS/parse failure while measuring height still releases the overlay,
  /// - mailto:/tel:/geo: are matched by scheme prefix instead of substring.
  final bool useLoadingOverlayRecovery;
  final String? userAgent;
  final Duration? loaderDelay;
  final LFWebViewOnBeforeLoaded? onInitBeforeLoaded;
  final LFWebViewOnLoaded? onInitLoaded;
  final LFWebViewOnCreateWebViewController? onCreateWebViewController;
  final LFWebViewOnPageStarted? onPageStarted;
  final LFWebViewOnPageFinished? onPageFinished;
  final LFWebViewOnLoaderBuilder? onLoaderBuilder;
  final LFWebViewOnHeightFinished? onHeightFinished;
  final LFWebViewOnNavigationDecision? onNavigationDecision;
  final LFWebViewOnUrlChange? onUrlChange;
  final LFWebViewOnHttpError? onHttpError;
  final LFWebViewOnJavaScriptAlertDialogIOS? onJavaScriptAlertDialogIOS;
  final LFWebViewOnJavaScriptConfirmDialogIOS? onJavaScriptConfirmDialogIOS;
  final LFWebViewOnJavaScriptTextInputDialogIOS? onJavaScriptTextInputDialogIOS;

  const LFWebView({
    super.key,
    required this.controller,
    this.uri,
    this.htmlString,
    this.htmlFile,
    this.assetFile,
    this.fullScreen = true,
    this.initHeight = 0.0,
    this.backgroundColor = const Color(0x00000000),
    this.allowAllowOrientation = false,
    this.allowsBackForwardNavigationGestures = true,
    this.useHybridComposition = false,
    this.isInspectable = false,
    this.useLoadingOverlayRecovery = false,
    this.userAgent,
    this.loaderDelay,
    this.onInitBeforeLoaded,
    this.onInitLoaded,
    this.onLoaderBuilder,
    this.onCreateWebViewController,
    this.onPageStarted,
    this.onPageFinished,
    this.onHeightFinished,
    this.onNavigationDecision,
    this.onUrlChange,
    this.onHttpError,
    this.onJavaScriptAlertDialogIOS,
    this.onJavaScriptConfirmDialogIOS,
    this.onJavaScriptTextInputDialogIOS,
  });

  @override
  State<LFWebView> createState() => _LFWebViewState();
}

class _LFWebViewState extends State<LFWebView> {
  late NavigationDelegate _navigationDelegate;

  double _contentHeight = 0.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    final controller = widget.controller;
    final initHeight = widget.initHeight;
    final backgroundColor = widget.backgroundColor;
    final allowAllowOrientation = widget.allowAllowOrientation;
    final allowsBackForwardNavigationGestures =
        widget.allowsBackForwardNavigationGestures;
    final isInspectable = widget.isInspectable;
    final userAgent = widget.userAgent;
    final uri = widget.uri;
    final htmlString = widget.htmlString;
    final htmlFile = widget.htmlFile;
    final assetFile = widget.assetFile;
    final onInitBeforeLoaded = widget.onInitBeforeLoaded;
    final onInitLoaded = widget.onInitLoaded;
    final onCreateWebViewController = widget.onCreateWebViewController;
    final onPageStarted = widget.onPageStarted;
    final onPageFinished = widget.onPageFinished;
    final onJavaScriptAlertDialogIOS = widget.onJavaScriptAlertDialogIOS;
    final onJavaScriptConfirmDialogIOS = widget.onJavaScriptConfirmDialogIOS;
    final onJavaScriptTextInputDialogIOS =
        widget.onJavaScriptTextInputDialogIOS;

    _contentHeight = initHeight;

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController webViewController =
        WebViewController.fromPlatformCreationParams(params);

    if (webViewController.platform is WebKitWebViewController) {
      WebKitWebViewController iOSWebViewController =
          (webViewController.platform as WebKitWebViewController);
      iOSWebViewController.setAllowsBackForwardNavigationGestures(
          allowsBackForwardNavigationGestures);
      iOSWebViewController.setInspectable(isInspectable);
      if (onJavaScriptAlertDialogIOS != null) {
        iOSWebViewController.setOnJavaScriptAlertDialog(
            (JavaScriptAlertDialogRequest request) async {
          await onJavaScriptAlertDialogIOS.call(request);
        });
      }
      if (onJavaScriptConfirmDialogIOS != null) {
        iOSWebViewController.setOnJavaScriptConfirmDialog(
            (JavaScriptConfirmDialogRequest request) async {
          final result = await onJavaScriptConfirmDialogIOS.call(request);
          return result ?? false;
        });
      }
      if (onJavaScriptTextInputDialogIOS != null) {
        iOSWebViewController.setOnJavaScriptTextInputDialog(
            (JavaScriptTextInputDialogRequest request) async {
          final result = await onJavaScriptTextInputDialogIOS.call(request);
          return result ?? '';
        });
      }
    }

    if (webViewController.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      AndroidWebViewController androidWebViewController =
          (webViewController.platform as AndroidWebViewController);
      androidWebViewController.setMediaPlaybackRequiresUserGesture(false);

      // SetCustomWidgetCallbacks
      androidWebViewController.setCustomWidgetCallbacks(
        onShowCustomWidget:
            (Widget child, OnHideCustomWidgetCallback callback) {
          if (allowAllowOrientation) {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
              DeviceOrientation.landscapeRight,
              DeviceOrientation.landscapeLeft,
            ]);
          }
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) => child,
              fullscreenDialog: true,
            ),
          );
        },
        onHideCustomWidget: () {
          if (allowAllowOrientation) {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
          }
          Navigator.of(context).pop();
        },
      );
    }

    _navigationDelegate = NavigationDelegate(
      onProgress: (int progress) {
        Logging.d('[LFWebView] onProgress = ${progress.toString()}');
      },
      onPageStarted: (String url) {
        Logging.d('[LFWebView] onPageStarted = $url');
        setState(() {
          _loading = true;
        });
        onPageStarted?.call();
      },
      onPageFinished: (String url) async {
        Logging.d('[LFWebView] onPageFinished = $url');
        await updateWebViewHeightAfterOnPageFinished();
        onPageFinished?.call();
      },
      onWebResourceError: (WebResourceError error) {
        Logging.d(
            '[LFWebView] onWebResourceError = ${error.errorCode} (mainFrame: ${error.isForMainFrame})');
        // A failed or interrupted main-frame navigation never reaches
        // onPageFinished (e.g. iOS hands a redirect off to an external app),
        // so release the loading overlay here or the screen stays locked.
        // Sub-frame errors (iframes) are ignored. The next onPageStarted
        // raises the overlay again.
        if (widget.useLoadingOverlayRecovery &&
            (error.isForMainFrame ?? true)) {
          if (mounted && _loading) {
            setState(() {
              _loading = false;
            });
          }
        }
      },
      onNavigationRequest: (NavigationRequest request) async {
        Logging.d('[LFWebView] navigationDelegate = ${request.url}');
        return await navigationURLToLinkEvent(request.url);
      },
      onHttpAuthRequest: (HttpAuthRequest request) async {
        Logging.d('[LFWebView] onHttpAuthRequest = ${request.realm}');
      },
      onUrlChange: (UrlChange change) {
        Logging.d('[LFWebView] onUrlChange = ${change.url}');
        widget.onUrlChange?.call(change.url);
      },
      onHttpError: (HttpResponseError error) {
        Logging.d('[LFWebView] onHttpError = ${error.response}');
        widget.onHttpError?.call(error);
      },
    );

    webViewController
      // ..loadRequest(Uri.parse('about:blank'))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(backgroundColor)
      ..setUserAgent(userAgent)
      ..setNavigationDelegate(_navigationDelegate);

    // Set WebViewController
    controller.webViewController = webViewController;

    // OnCreateWebViewController
    onCreateWebViewController?.call(webViewController);

    // Register Channel for Names
    for (var javaScriptChannelName in controller.javaScriptChannelNames) {
      controller.webViewController.addJavaScriptChannel(
        javaScriptChannelName,
        onMessageReceived: (message) {
          controller
              .addJavaScriptMessageStream({javaScriptChannelName: message});
        },
      );
    }

    // Register Channels for Functions
    for (var onRegisterJavaScriptChannel
        in controller.onRegisterJavaScriptChannels) {
      onRegisterJavaScriptChannel.call(webViewController);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await onInitBeforeLoaded?.call();
      if (uri != null) {
        await controller.loadRequest(uri);
      } else if (htmlString != null) {
        await controller.loadHtmlString(htmlString);
      } else if (htmlFile != null) {
        await controller.loadFile(htmlFile);
      } else if (assetFile != null) {
        await controller.loadFlutterAsset(assetFile);
      }
      await onInitLoaded?.call();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final fullScreen = widget.fullScreen;

    double getHeight(BoxConstraints constraints) {
      final maxHeight = constraints.maxHeight;
      double height = 0.0;
      if (fullScreen) {
        height = maxHeight;
      } else {
        height = (maxHeight.isInfinite) ? 0.0 : maxHeight;
      }
      return height;
    }

    late WebViewWidget webViewWidget;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      webViewWidget = WebViewWidget(
        controller: controller.webViewController,
      );
    } else {
      webViewWidget = WebViewWidget.fromPlatformCreationParams(
        params: AndroidWebViewWidgetCreationParams(
          controller: controller.webViewController.platform,
          displayWithHybridComposition: widget.useHybridComposition,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: math.max(getHeight(constraints), _contentHeight),
          child: Stack(
            children: [
              webViewWidget,
              if (_loading)
                if (Platform.isIOS) ...[
                  Positioned.fill(
                    child: PointerInterceptor(
                      intercepting: true,
                      debug: false,
                      child: Container(
                        color: Colors.transparent,
                        child: Center(
                          child: widget.onLoaderBuilder?.call() ?? Container(),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Positioned.fill(
                    child: AbsorbPointer(
                      absorbing: true,
                      child: Container(
                        color: Colors.transparent,
                        child: Center(
                          child: widget.onLoaderBuilder?.call() ?? Container(),
                        ),
                      ),
                    ),
                  ),
                ],
            ],
          ),
        );
      },
    );
  }

  Future<NavigationDecision> navigationURLToLinkEvent(String url) async {
    final onNavigationDecision = widget.onNavigationDecision;
    // With recovery enabled, match the URL scheme, not a substring: an https
    // URL whose path or query contains e.g. 'hotel:' must not be treated as a
    // tel: link. Otherwise keep the upstream substring matching.
    final lowerUrl = url.toLowerCase();
    bool isLink(String scheme) => widget.useLoadingOverlayRecovery
        ? lowerUrl.startsWith(scheme)
        : url.contains(scheme);
    if (isLink('mailto:')) {
      Logging.d('[LFWebView] navigationDelegate :: Mailto clicked! = $url');
      final _ = onNavigationDecision?.call(LFWebViewEventType.mailto, url);
      return NavigationDecision.prevent;
    } else if (isLink('tel:')) {
      Logging.d('[LFWebView] navigationDelegate :: Tel clicked! = $url');
      final _ = onNavigationDecision?.call(LFWebViewEventType.tel, url);
      return NavigationDecision.prevent;
    } else if (isLink('geo:')) {
      Logging.d('[LFWebView] navigationDelegate :: GEO clicked! = $url');
      final _ = onNavigationDecision?.call(LFWebViewEventType.geo, url);
      return NavigationDecision.prevent;
    }
    if (onNavigationDecision != null) {
      final allow = onNavigationDecision.call(null, url);
      return allow ? NavigationDecision.navigate : NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  Future<void> updateWebViewHeightAfterOnPageFinished() async {
    final controller = widget.controller;
    final webViewController = controller.webViewController;
    // With recovery enabled, a JS evaluation or parse failure here must not
    // skip releasing the loading overlay below.
    try {
      final readyState = await webViewController
          .runJavaScriptReturningResult('document.readyState');
      Logging.d('[LFWebView] readyState: $readyState');
      if (readyState == 'complete' || readyState == '"complete"') {
        final height = await webViewController
            .runJavaScriptReturningResult('document.body.scrollHeight');
        final heightStr = height.toString();
        final documentHeight = double.parse(heightStr);
        Logging.d('[LFWebView] DocumentHeight: $documentHeight');
        final fullScreen = widget.fullScreen;
        if (!fullScreen) {
          if (context.mounted) {
            setState(() {
              _contentHeight = documentHeight;
            });
          }
        }
        widget.onHeightFinished?.call(documentHeight);
      }
    } catch (e) {
      // Upstream behavior: the failure propagates and the overlay stays.
      if (!widget.useLoadingOverlayRecovery) rethrow;
      Logging.d('[LFWebView] updateWebViewHeight error: $e');
    }
    if (context.mounted) {
      final loaderDelay = widget.loaderDelay;
      if (loaderDelay != null) {
        await Future.delayed(loaderDelay);
      }
      setState(() {
        _loading = false;
      });
    }
  }
}
