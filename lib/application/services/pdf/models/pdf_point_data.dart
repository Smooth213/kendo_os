class PdfPlayerSpan {
  final String name;
  final int startIndex;
  int endIndex;
  PdfPlayerSpan(this.name, this.startIndex, this.endIndex);
}

class PdfPointData {
  final String mark;
  final bool isFirstOverall;
  PdfPointData(this.mark, this.isFirstOverall);
}