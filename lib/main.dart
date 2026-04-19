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
    _setupController();
  }

  void _setupController() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    if (controller.platform is AndroidWebViewController) {
      (controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
    }

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (!request.url.startsWith('http')) return NavigationDecision.prevent;
            return NavigationDecision.navigate;
          },
          onPageFinished: (url) => _applyProductionLayout(controller),
        ),
      );

    controller.clearCache().then((_) {
      controller.loadRequest(Uri.parse('https://www.tiktok.com/foryou'));
    });
    _controller = controller;
  }

  void _applyProductionLayout(WebViewController controller) {
    controller.runJavaScript("""
      (function() {
        var style = document.createElement('style');
        style.innerHTML = `
          /* 1. RESET GLOBAL DO ESQUELETO DESKTOP (Destrói a faixa preta) */
          #app, #app > div, [class*='DivBodyContainer'], body, html {
            display: block !important;
            width: 100vw !important;
            max-width: 100vw !important;
            padding: 0 !important;
            margin: 0 !important;
            overflow-x: hidden !important;
          }

          /* 2. OCULTAR ELEMENTOS INÚTEIS DO PC */
          [class*='DivSideNavContainer'], 
          [data-e2e='nav-container'], 
          header, 
          [class*='DivHeaderContainer'] { 
            display: none !important; 
            width: 0 !important;
            height: 0 !important;
            position: absolute !important;
          }

          /* 3. EXPANDE O CONTAINER DO FEED PARA 100% DA TELA */
          [class*='DivMainContainer'], 
          [data-e2e='main-container'],
          main {
            width: 100vw !important;
            max-width: 100vw !important;
            margin: 0 !important;
            padding: 0 !important;
            transform: none !important;
          }

          /* 4. CONFIGURAÇÃO DO BLOCO DO VÍDEO (Tela Cheia Real) */
          [data-e2e='recommend-list-item-container'] {
            width: 100vw !important;
            height: 100vh !important;
            padding: 0 !important;
            margin: 0 !important;
            position: relative !important;
            display: flex !important;
            justify-content: center !important;
            align-items: center !important;
          }

          video {
            width: 100vw !important;
            height: 100vh !important;
            object-fit: cover !important; /* Preenche a tela e corta rebarbas laterais */
            position: absolute !important;
            top: 0 !important;
            left: 0 !important;
            z-index: 1 !important;
          }

          /* 5. RESGATA NOME DO AUTOR E LEGENDA (Esquerda Inferior) */
          [class*='DivContentContainer'],
          [class*='DivVideoInfoContainer'],
          [data-e2e='video-author-info'] {
            position: absolute !important;
            bottom: 40px !important;
            left: 15px !important;
            z-index: 999 !important;
            max-width: 70vw !important;
            background: transparent !important;
            text-shadow: 1px 1px 3px rgba(0,0,0,0.8) !important; /* Melhora a leitura sobre o vídeo */
          }

          /* 6. BOTÕES FLUTUANTES (Curtir, Comentar) na Direita */
          [class*='DivActionItemContainer'],
          [data-e2e='feed-active-video-container'] + div {
            position: absolute !important;
            right: 10px !important;
            bottom: 60px !important;
            display: flex !important;
            flex-direction: column !important;
            z-index: 999 !important;
            background: transparent !important;
          }

          /* Remove barras de rolagem nativas */
          ::-webkit-scrollbar { display: none !important; }
        `;
        document.head.appendChild(style);

        // Remove modais insistentes do React
        setInterval(function() {
          var modals = document.querySelectorAll('[data-e2e="login-modal"], div[class*="DivModalContainer"]');
          modals.forEach(m => m.remove());
        }, 1500);
      })();
    """);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: WebViewWidget(controller: _controller)),
    );
  }
}
