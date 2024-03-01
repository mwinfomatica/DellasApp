
class PrinterHelper {
  //FORMATS PRINTER ITENS PEDIDO CUPOM
  static String formatPrimaryHeader = "%-20s %2s %5s %5s %n";
  static String formatSecundaryHeader = "%-20s %5s %7s %6s %n";
  static String formatItensPedidos = "%-8s %6s %7s %7s %n";
  static String charsetDefault = "windows-1250";
  static int sizeFontItensPedidos = 0;

  //SIZE
  static int normalSizeText = 0;
  static int onlyBoldText = 1;
  static int boldWithMediumText = 2;
  static int boldWithLargeText = 3;

  //ALIGN
  static int escAlignLeft = 0;
  static int escAlignCenter = 1;
  static int escAlignRight = 2;
}
