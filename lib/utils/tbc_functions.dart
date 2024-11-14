String escapeMarkdown(String text) {
  return text.replaceAllMapped(RegExp(r'([_*`$begin:math:display$$end:math:display$])'), (match) => '\\${match[0]}');
}
