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
      // ENGINE DE DESKTOP: Retornamos ao UA de PC. O Servidor libera o feed infinito para convidados.
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // FIREWALL DE REDE
            if (!request.url.startsWith('http://') && !request.url.startsWith('https://')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (url) => _injectDesktopToMobileCSS(controller),
        ),
      );

    controller.clearCache().then((_) {
      // Força a entrada direta no feed principal
      controller.loadRequest(Uri.parse('https://www.tiktok.com/foryou'));
    });

    _controller = controller;
  }

  // CORE DA SOLUÇÃO: Muta o layout Desktop para Mobile
  void _injectDesktopToMobileCSS(WebViewController controller) {
    controller.runJavaScript("""
      (function() {
        // 1. Adapta o Viewport do motor do navegador para proporção de celular
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
        document.head.appendChild(meta);

        // 2. Injeção Cirúrgica de CSS
        var style = document.createElement('style');
        style.innerHTML = `
          /* Destrói Cabeçalho, Barra Lateral, Popups de Login e Banners */
          [data-e2e="nav-container"], 
          [data-e2e="top-wrapper"], 
          [id^='header'],
          [class*='login-modal'],
          #app-header,
          .tiktok-top-wrapper,
          .tiktok-nav-container {
            display: none !important;
            opacity: 0 !important;
            pointer-events: none !important;
          }

          /* Força o contêiner central a ocupar toda a largura (100vw) */
          [data-e2e="main-container"], 
          #main-content-homepage_hot,
          .tiktok-main-container {
            width: 100vw !important;
            max-width: 100vw !important;
            padding: 0 !important;
            margin: 0 !important;
            background-color: #000000 !important;
          }

          /* Converte os blocos de vídeo para tela cheia com snap scroll (9:16) */
          [data-e2e="recommend-list-item-container"],
          .tiktok-recommend-list-item-container {
            height: 100vh !important;
            width: 100vw !important;
            max-width: 100vw !important;
            display: flex !important;
            justify-content: center !important;
            align-items: center !important;
          }

          /* Remove as bordas do vídeo, forçando preenchimento via object-fit */
          video {
            object-fit: cover !important;
            border-radius: 0 !important;
          }

          /* Oculta as barras de rolagem nativas para estética de App */
          ::-webkit-scrollbar {
            display: none !important;
          }
          html, body {
            scrollbar-width: none !important;
            overflow-x: hidden !important;
            background-color: #000000 !important;
            color-scheme: dark !important;
          }
        `;
        document.head.appendChild(style);

        // 3. Destruidor cíclico de camadas intrusivas remanescentes
        setInterval(function() {
          var modals = document.querySelectorAll('[data-e2e="login-modal"], div[class*="DivModalContainer"]');
          modals.forEach(m => m.remove());
          
          if(document.body.style.overflow === 'hidden') {
             document.body.style.overflow = 'auto';
          }
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
