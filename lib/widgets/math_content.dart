import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MathContentWidget extends StatelessWidget {
  final String content;
  final TextStyle? style;

  const MathContentWidget({super.key, required this.content, this.style});

  @override
  Widget build(BuildContext context) {
    // Check for math content
    if (content.contains(r'$$') || content.contains(r'$')) {
      return MathRenderer(mathText: content);
    } 
    // Check for markdown content
    else if (content.contains('|') || 
             content.contains('#') || 
             content.contains('*') ||
             content.contains('```')) {
      return Markdown(
        data: content,
        selectable: true,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
      );
    } 
    // Plain text
    else {
      return Text(content, style: style ?? const TextStyle(fontSize: 16));
    }
  }
}

class MathRenderer extends StatelessWidget {
  final String mathText;

  const MathRenderer({super.key, required this.mathText});

  @override
  Widget build(BuildContext context) {
    // First preprocess the text to handle special cases
    final processedText = _preprocessMathContent(mathText);
    
    // Split the text by newlines first to handle paragraphs
    final paragraphs = processedText.split(r'\n');
    List<Widget> paragraphWidgets = [];

    for (String paragraph in paragraphs) {
      if (paragraph.isEmpty) {
        // Add an empty space for blank lines
        paragraphWidgets.add(const SizedBox(height: 16));
        continue;
      }

      // Process each paragraph separately
      List<InlineSpan> spans = [];
      String remainingText = paragraph;
      
      while (remainingText.isNotEmpty) {
        // Check for display math first ($$...$$)
        final displayMathMatch = RegExp(r'\$\$(.*?)\$\$', dotAll: true).firstMatch(remainingText);
        
        if (displayMathMatch != null && displayMathMatch.start == 0) {
          // Handle display math at the beginning of the paragraph
          if (spans.isNotEmpty) {
            paragraphWidgets.add(RichText(
              text: TextSpan(
                children: spans, 
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16)
              ),
            ));
            spans = [];
          }
          
          String mathExpression = displayMathMatch.group(1)!.trim();
          paragraphWidgets.add(_buildDisplayMath(mathExpression));
          remainingText = remainingText.substring(displayMathMatch.end);
          continue;
        } 
        
        // Check for inline math ($...$)
        final inlineMathMatch = RegExp(r'\$(.*?)\$').firstMatch(remainingText);
        
        if (inlineMathMatch != null) {
          // Add text before the math expression
          if (inlineMathMatch.start > 0) {
            final textBefore = remainingText.substring(0, inlineMathMatch.start);
            spans.add(TextSpan(text: textBefore));
          }
          
          // Add the math expression
          String mathExpression = inlineMathMatch.group(1)!;
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _buildInlineMath(mathExpression),
          ));
          
          remainingText = remainingText.substring(inlineMathMatch.end);
        } else {
          // No more math expressions, add remaining text
          spans.add(TextSpan(text: remainingText));
          break;
        }
      }

      // Add any remaining spans for this paragraph
      if (spans.isNotEmpty) {
        paragraphWidgets.add(RichText(
          text: TextSpan(
            children: spans,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16),
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphWidgets,
    );
  }

  // Preprocess math content to handle various LaTeX formats
  // Preprocess math content to handle various LaTeX formats
String _preprocessMathContent(String content) {
  // Convert \matrix to bmatrix
  content = content.replaceAllMapped(
    RegExp(r'\\left\[\\begin\{matrix\}(.*?)\\end\{matrix\}\\right\]', dotAll: true),
    (Match m) => r'\begin{bmatrix}' + m.group(1)! + r'\end{bmatrix}'
  );

  // Convert simple [a b; c d] notation to bmatrix
  content = content.replaceAllMapped(
    RegExp(r'\\left\[((?:[^;]+;)+[^]]+)\\right\]'),
    (Match m) => r'\begin{bmatrix}' + m.group(1)!.replaceAll(';', r'\\') + r'\end{bmatrix}'
  );

  // Fix malformed bmatrix endings - ensure proper \end{bmatrix}
  content = content.replaceAll(RegExp(r'\\\\end\{bmatrix\}'), r'\end{bmatrix}');
  content = content.replaceAll(RegExp(r'\\end\{bmatrix\b(?!\})'), r'\end{bmatrix}');
  
  // Fix cases where \end{bmatrix} is missing the closing brace
  content = content.replaceAll(RegExp(r'\\end\{bmatrix(?!\})'), r'\end{bmatrix}');
  
  // Ensure proper row separators in matrices
  content = content.replaceAllMapped(
    RegExp(r'\\begin\{bmatrix\}(.*?)\\end\{bmatrix\}', dotAll: true),
    (Match m) {
      String matrixContent = m.group(1)!;
      
      // Clean up the matrix content
      matrixContent = matrixContent.trim();
      
      // Normalize multiple backslashes to double backslash (row separator)
      matrixContent = matrixContent.replaceAll(RegExp(r'\\{3,}'), r'\\');
      
      // Ensure we don't have trailing row separators
      matrixContent = matrixContent.replaceAll(RegExp(r'\\+$'), '');
      
      // Make sure each row (except the last) ends with exactly \\
      List<String> rows = matrixContent.split(RegExp(r'\\{2,}'));
      for (int i = 0; i < rows.length; i++) {
        rows[i] = rows[i].trim();
      }
      
      // Rejoin with proper separators
      matrixContent = rows.where((row) => row.isNotEmpty).join(r'\\');
      
      return r'\begin{bmatrix}' + matrixContent + r'\end{bmatrix}';
    }
  );

  // Handle other matrix types
  content = content.replaceAllMapped(
    RegExp(r'\\begin\{pmatrix\}(.*?)\\end\{pmatrix\}', dotAll: true),
    (Match m) {
      String matrixContent = m.group(1)!.trim();
      matrixContent = matrixContent.replaceAll(RegExp(r'\\{3,}'), r'\\');
      matrixContent = matrixContent.replaceAll(RegExp(r'\\+$'), '');
      return r'\begin{pmatrix}' + matrixContent + r'\end{pmatrix}';
    }
  );

  // Handle other common LaTeX conversions
  content = content.replaceAll(r'\dfrac', r'\frac');
  content = content.replaceAll(r'\boldsymbol', r'\mathbf');
  content = content.replaceAll(r'\mathrm', r'\text');
  
  // Fix common spacing issues in LaTeX
  content = content.replaceAll(RegExp(r'\\left\s*\('), r'\left(');
  content = content.replaceAll(RegExp(r'\)\s*\\right'), r')\right');
  content = content.replaceAll(RegExp(r'\\left\s*\['), r'\left[');
  content = content.replaceAll(RegExp(r'\]\s*\\right'), r']\right');

  return content;
}
  
  Widget _buildDisplayMath(String expression) {
    expression = _cleanMathExpression(expression);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Math.tex(
        expression,
        textStyle: const TextStyle(fontSize: 18),
        mathStyle: MathStyle.display,
        onErrorFallback: (FlutterMathException e) => _buildMathError(e, expression, isDisplay: true),
      ),
    );
  }
  
  Widget _buildInlineMath(String expression) {
    expression = _cleanMathExpression(expression);
    
    return Math.tex(
      expression,
      textStyle: const TextStyle(fontSize: 16),
      onErrorFallback: (FlutterMathException e) => _buildMathError(e, expression, isDisplay: false),
    );
  }

  Widget _buildMathError(FlutterMathException e, String originalExpression, {required bool isDisplay}) {
    print("Math Error: ${e.message} in expression: $originalExpression");
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Math Error: ${e.message}",
            style: TextStyle(
              color: Colors.red,
              fontSize: isDisplay ? 16 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Expression: $originalExpression",
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: isDisplay ? 14 : 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
  
  String _cleanMathExpression(String expression) {
    // Normalize line endings and spacing
    expression = expression.replaceAll('\r\n', '\n').trim();
    
    // Remove trailing LaTeX spacing commands like "\ " or "\ \ " 
    expression = expression.replaceAll(RegExp(r'(\\ )+$'), '');
    
    // Remove other trailing whitespace and backslashes
    expression = expression.replaceAll(RegExp(r'[\\\s]+$'), '');
    
    // Handle unnecessary braces around single characters or simple expressions
    // This helps with expressions like {sw} -> sw
    // expression = expression.replaceAllMapped(
    //   RegExp(r'\{([a-zA-Z]+)\}(?![_^])'), // Match {letters} not followed by subscript/superscript
    //   (Match m) => '${m.group(1)!} ',
    // );
    
    // Clean up malformed spacing commands in the middle of expressions
    expression = expression.replaceAll(RegExp(r'\\ (?=\s|$)'), ' '); // Replace "\ " with regular space
    expression = expression.replaceAll(RegExp(r'\\(?=\s)'), ''); // Remove lone backslashes before spaces
    
    // Normalize multiple spaces to single spaces
    expression = expression.replaceAll(RegExp(r'\s+'), ' ');
    
    // Handle common problematic patterns
    expression = expression.replaceAll(RegExp(r'\\{2,}'), r'\\'); // Multiple backslashes
    
    return expression.trim();
  }
}
