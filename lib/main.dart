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
      ..setUserAgent("Mozilla/5.0 (Linux; Android 13; Pixel 7 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // FIREWALL DE REDE: Impede o TikTok de forçar o uso do app nativo.
            // O bloqueio de URLs do tipo "intent://" evita o crash do WebView (Logotipo do Android)
            if (!request.url.startsWith('http://') && !request.url.startsWith('https://')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (url) => _applyAntiModalHeuristics(controller),
        ),
      );

    controller.clearCache().then((_) {
      // Injeta param url para forçar tema escuro nativamente se suportado
      controller.loadRequest(Uri.parse('https://www.tiktok.com/?theme=dark'));
    });

    _controller = controller;
  }

  void _applyAntiModalHeuristics(WebViewController controller) {
    controller.runJavaScript("""
      (function() {
        var style = document.createElement('style');
        style.innerHTML = `
          /* Bloqueio de seletores mapeados de Banners e Paywalls */
          [class*='bottom-app-banner'], 
          [class*='login-modal'],
          [class*='verify-modal'],
          [id^='app-banner'] { 
            display: none !important; 
          }
          
          /* Restaurando a interatividade da página de forma segura */
          html, body { 
            overflow: auto !important; 
            overflow-y: scroll !important; 
            height: 100% !important; 
            color-scheme: dark !important; 
            background-color: #000000;
          }
        `;
        document.head.appendChild(style);

        // Scanner cíclico de Overlays (Camadas fantasmas que escurecem a tela)
        setInterval(function() {
          // Captura elementos com z-index alto que atuam como fundo do login/cadastro
          var overlays = document.querySelectorAll('div, section');
          overlays.forEach(function(el) {
            var styles = window.getComputedStyle(el);
            if (styles.position === 'fixed' && parseInt(styles.zIndex) >= 90) {
              // Se tiver uma camada transparente alta cobrindo a tela (ex: rgba(0,0,0,0.5)), apaga.
              if (styles.backgroundColor.includes('rgba') || styles.opacity < 1) {
                el.style.display = 'none';
              }
            }
          });
          
          // Tratativa final para manter o scroll do usuário destravado
          if (document.body.style.overflow === 'hidden') {
              document.body.style.overflow = 'auto';
          }
        }, 1000);
      })();
    """);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        // Impede que o notch/furo da câmera corte conteúdo importante no topo
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
