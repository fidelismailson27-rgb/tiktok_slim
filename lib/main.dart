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
          /* 1. OCULTA ELEMENTOS INÚTEIS DO TOPO E CABEÇALHO */
          header, 
          [class*='DivHeaderContainer'] { 
            display: none !important; 
          }

          /* 2. RECENTRALIZA O CONTEÚDO PRINCIPAL E TELA CHEIA */
          [class*='DivMainContainer'], 
          [data-e2e='main-container'],
          main {
            margin-left: 0 !important;
            padding-left: 0 !important;
            width: 100vw !important;
            max-width: 100vw !important;
          }

          [data-e2e='recommend-list-item-container'] {
            width: 100vw !important;
            height: 100vh !important;
            display: flex !important;
            flex-direction: column !important;
            position: relative !important;
          }

          video {
            width: 100vw !important;
            height: 100vh !important;
            object-fit: cover !important;
          }

          /* 3. TRANSFORMA A BARRA LATERAL EM BOTTOM NAV (RODAPÉ) */
          [class*='DivSideNavContainer'], 
          [data-e2e='nav-container'] { 
            display: flex !important; 
            position: fixed !important;
            bottom: 0 !important;
            left: 0 !important;
            width: 100vw !important;
            height: 60px !important;
            background-color: #000000 !important;
            z-index: 9999 !important; /* Mantém sempre visível acima do vídeo */
            border-top: 1px solid #333 !important;
            overflow: hidden !important;
          }

          /* Modifica o flex para alinhar os botões em linha horizontal */
          [class*='DivSideNavContainer'] > div,
          [class*='DivMainNavContainer'] {
             display: flex !important;
             flex-direction: row !important;
             width: 100vw !important;
             justify-content: space-around !important;
             align-items: center !important;
          }

          /* Oculta os links mortos ou seções inteiras que não cabem na tela mobile */
          [class*='DivDiscoverContainer'],
          [class*='DivUserListContainer'],
          [class*='DivFooterContainer'],
          [data-e2e='suggest-accounts'],
          .custom-scrollbar::-webkit-scrollbar {
            display: none !important;
          }

          /* 4. BOTÕES FLUTUANTES À DIREITA (Ajustado para não conflitar com o rodapé) */
          [class*='DivActionItemContainer'],
          [data-e2e='feed-active-video-container'] + div {
            position: absolute !important;
            right: 10px !important;
            bottom: 80px !important; /* Subiu 80px para dar espaço à Bottom Nav */
            display: flex !important;
            flex-direction: column !important;
            z-index: 999 !important;
            visibility: visible !important;
            opacity: 1 !important;
          }

          /* Limpeza geral de Scroll */
          ::-webkit-scrollbar { display: none !important; }
          html, body { overflow-x: hidden !important; background: #000; }
        `;
        document.head.appendChild(style);
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
