import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    home: TikTokSlim(),
    debugShowCheckedModeBanner: false,
  ));
}

class TikTokSlim extends StatefulWidget {
  const TikTokSlim({super.key});

  @override
  State<TikTokSlim> createState() => _TikTokSlimState();
}

class _TikTokSlimState extends State<TikTokSlim> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) => _applyAutoLayout(controller),
        ),
      );

    // Limpeza rigorosa: força a rede e evita tentar carregar erros da sessão anterior
    controller.clearCache().then((_) {
      controller.loadRequest(Uri.parse('https://www.tiktok.com/explore'));
    });

    _controller = controller;
  }

  void _applyAutoLayout(WebViewController controller) {
    controller.runJavaScript("""
      (function() {
        if (!document.querySelector('meta[name="viewport"]')) {
          var meta = document.createElement('meta');
          meta.name = 'viewport';
          meta.content = 'width=device-width, initial-scale=0.7, maximum-scale=1.0, user-scalable=no';
          document.getElementsByTagName('head')[0].appendChild(meta);
        }

        var style = document.createElement('style');
        style.innerHTML = `
          [class*='DivDownloadAppBanner'], 
          [class*='ButtonDownloadApp'], 
          [class*='DivHeaderContainer'],
          .tiktok-footer, 
          header, 
          footer { display: none !important; }
          body { overflow-x: hidden !important; background-color: #000000 !important; }
        `;
        document.head.appendChild(style);
      })();
    """);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
