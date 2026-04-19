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
      // MUDANÇA CRÍTICA: User-Agent Mobile Android para requisitar a UI nativa
      ..setUserAgent("Mozilla/5.0 (Linux; Android 13; Pixel 7 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) => _applyMobileLayout(controller),
        ),
      );

    controller.clearCache().then((_) {
      // Direciona direto para o feed raiz
      controller.loadRequest(Uri.parse('https://www.tiktok.com/'));
    });

    _controller = controller;
  }

  void _applyMobileLayout(WebViewController controller) {
    // Injeção de código para neutralizar os bloqueadores da versão Mobile Web
    controller.runJavaScript("""
      (function() {
        var style = document.createElement('style');
        style.innerHTML = `
          /* Elimina Banners de "Abrir no App" e Cookie popups */
          div[class*='DivAppBanner'], 
          div[class*='DivDownloadBanner'], 
          div[class*='DivModalContainer'], 
          div[class*='DivOpenApp'],
          div[id^='app-banner'],
          .tiktok-cookie-banner,
          [data-e2e="bottom-app-banner"] { 
            display: none !important; 
            opacity: 0 !important; 
            pointer-events: none !important; 
          }
          
          /* Força a tela a ser interativa. O TikTok trava o 'overflow' quando tenta forçar o download */
          html, body { 
            overflow: auto !important; 
            overflow-y: scroll !important; 
            height: 100% !important; 
            position: static !important;
            background-color: #000000 !important;
          }
        `;
        document.head.appendChild(style);

        // Loop defensivo: SPA (Single Page Applications) carregam elementos via lazy-loading.
        // Isso destrói os modais de bloqueio caso o React do TikTok tente renderizá-los após o scroll.
        setInterval(function() {
          var modals = document.querySelectorAll("div[class*='DivModalContainer'], [class*='bottom-app-banner']");
          modals.forEach(function(el) { el.remove(); });
          
          // Garante que o scroll do body nunca seja bloqueado
          document.body.style.overflow = 'auto';
        }, 1500);
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
