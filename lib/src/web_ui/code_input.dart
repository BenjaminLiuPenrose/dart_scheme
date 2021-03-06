library web_ui.code_input;

import 'dart:async';
import 'dart:html';

import 'package:cs61a_scheme/cs61a_scheme.dart';

import 'highlight.dart';

const List<SchemeSymbol> noIndentForms = [
  SchemeSymbol("let"),
  SchemeSymbol("define"),
  SchemeSymbol("lambda"),
  SchemeSymbol("define-macro")
];

class CodeInput {
  Element element;
  bool _active = true;
  final List<StreamSubscription> _subs = [];

  Function(String code) runCode;
  Function(int parens) parenListener;

  CodeInput(Element log, this.runCode, {this.parenListener}) {
    element = SpanElement()
      ..classes = ['code-input']
      ..contentEditable = 'true';
    _subs.add(element.onKeyPress.listen(_onInputKeyPress));
    _subs.add(element.onKeyDown.listen(_keyListener));
    _subs.add(element.onKeyUp.listen(_keyListener));
    log.append(element);
    element.focus();
    parenListener ??= (_) => null;
    parenListener(missingParens);
  }

  String get text => element.text;

  set text(String newText) {
    element.text = newText;
    highlight(atEnd: true);
  }

  bool get active => _active;

  int get missingParens => countParens(text);

  void deactivate() {
    _active = false;
    element.contentEditable = 'false';
    for (var sub in _subs) {
      sub.cancel();
    }
  }

  Future highlight(
      {bool saveCursor = false, int cursor, bool atEnd = false}) async {
    if (saveCursor) {
      await highlightSaveCursor(element);
    } else if (cursor != null) {
      await highlightCustomCursor(element, cursor);
    } else if (atEnd) {
      await highlightAtEnd(element, element.text);
    } else {
      element.innerHtml = highlightText(element.text);
    }
  }

  Future _onInputKeyPress(KeyboardEvent event) async {
    if ((missingParens ?? -1) > 0 &&
        event.shiftKey &&
        event.keyCode == KeyCode.ENTER) {
      event.preventDefault();
      element.text = element.text.trimRight() + ')' * missingParens + '\n';
      runCode(element.text);
      await delay(100);
      await highlight();
    } else if ((missingParens ?? -1) == 0 && event.keyCode == KeyCode.ENTER) {
      event.preventDefault();
      element.text = element.text.trimRight() + '\n';
      runCode(element.text);
      await delay(100);
      await highlight();
    } else if ((missingParens ?? 0) > 0 && KeyCode.ENTER == event.keyCode) {
      event.preventDefault();
      int cursor = findPosition(element, window.getSelection().getRangeAt(0));
      String newInput = element.text;
      String first = newInput.substring(0, cursor) + "\n";
      String second = "";
      if (cursor != newInput.length) {
        second = newInput.substring(cursor);
      }
      int spaces = _countSpace(newInput, cursor);
      element.text = first + " " * spaces + second;
      await highlight(cursor: cursor + spaces + 1);
    } else {
      await delay(5);
      await highlight(saveCursor: true);
    }
    parenListener(missingParens);
  }

  /// Determines how much space to indent the next line, based on parens
  int _countSpace(String inputText, int position) {
    List<String> splitLines = inputText.substring(0, position).split("\n");
    // If the cursor is at the end of the line but not the end of the input, we
    // must find that line and start counting parens from there
    String refLine;
    int totalMissingCount = 0;
    for (refLine in splitLines.reversed) {
      // Truncate to position of cursor when in middle of the line
      totalMissingCount += countParens(refLine);
      // Find the first line with an open paren but no close paren
      if (totalMissingCount >= 1) break;
    }
    if (totalMissingCount == 0) {
      return 0;
    }
    int strIndex = refLine.indexOf("(");
    while (strIndex < (refLine.length - 1)) {
      int nextClose = refLine.indexOf(")", strIndex + 1);
      int nextOpen = refLine.indexOf("(", strIndex + 1);
      // Find the open paren that corresponds to the missing closed paren
      if (totalMissingCount > 1) {
        totalMissingCount -= 1;
      } else if (nextOpen == -1 || nextOpen < nextClose) {
        Iterable<Expression> tokens = tokenizeLine(refLine.substring(strIndex));
        Expression symbol = tokens.elementAt(1);
        // Align subexpressions if any exist; otherwise, indent by two spaces
        if (symbol == const SchemeSymbol("(")) {
          return strIndex + 1;
        } else if (noIndentForms.contains(symbol)) {
          return strIndex + 2;
        } else if (tokens.length > 2) {
          return refLine.indexOf(tokens.elementAt(2).toString(), strIndex + 1);
        } else if (nextOpen == -1) {
          return strIndex + 2;
        }
      } else if (nextClose == -1) {
        return strIndex + 2;
      }
      strIndex = nextOpen;
    }
    return strIndex + 2;
  }

  _keyListener(KeyboardEvent event) async {
    int key = event.keyCode;
    if (key == KeyCode.BACKSPACE) {
      await delay(0);
      parenListener(missingParens);
      await highlight(saveCursor: true);
    } else if (event.ctrlKey && (key == KeyCode.V || key == KeyCode.X)) {
      await delay(0);
      parenListener(missingParens);
      await highlight(saveCursor: true);
    }
  }
}
