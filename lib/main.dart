import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Importação obrigatória para acessar APIs nativas do Android no nível de produção
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

    // Factory Pattern: Inicializa o controlador com base nas especificações da plataforma
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Define fundo branco inicialmente para mitigar o artefato visual de alocação da GPU
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) => _applyAutoLayout(controller),
        ),
      )
      ..loadRequest(Uri.parse('https://www.tiktok.com/explore'));

    // Configurações Críticas (Nível de Produção) exclusivas para Android
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController androidController = controller.platform as AndroidWebViewController;
      // Impede que o TikTok trave a renderização do DOM aguardando interação do usuário para mídia
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }

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
