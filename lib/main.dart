import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      // Bypass do bloqueio mobile simulando Chrome no Windows
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) => _applyAutoLayout(),
        ),
      )
      ..loadRequest(Uri.parse('https://www.tiktok.com/explore'));
  }

  void _applyAutoLayout() {
    // Automação: 
    // 1. Injeta meta tag de viewport para permitir zoom via código.
    // 2. Ajusta escala para 0.7 (adapta layout desktop para largura mobile).
    // 3. Oculta elementos pesados e banners de download.
    _controller.runJavaScript("""
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
          body { overflow-x: hidden !important; }
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
