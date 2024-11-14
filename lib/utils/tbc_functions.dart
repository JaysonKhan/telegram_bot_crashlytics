String escapeMarkdown(String text) {
  return text.replaceAllMapped(RegExp(r'([_*[\]()~`>#+\-=|{}.!])'), (Match match) {
    return '\\${match[0]}';
  });
}
