import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ivy_path/services/material_service.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PDFViewerScreen extends StatefulWidget {
  final String source;
  final String title;
  final bool isUrl;

  const PDFViewerScreen({
    super.key,
    required this.source,
    required this.title,
    required this.isUrl,
  });

  
  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  final MaterialService _materialService = MaterialService();
  File materialFile = File('');
  bool isloading = false;

  @override
  void initState() {
    if(!widget.isUrl) {
      isloading = true;
      _getMaterial();
    }
    
    super.initState();
  }

  void _getMaterial() async {
    final material = await _materialService.getLocalMaterial(int.parse(widget.source));
    if(material != null) {
      setState(() {
        materialFile = material;
        isloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: widget.isUrl
          ? SfPdfViewer.network(
              widget.source,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              enableDoubleTapZooming: true,
            )
          : isloading ? null : SfPdfViewer.file(
              materialFile,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              enableDoubleTapZooming: true,
            ),
    );
  }
}
