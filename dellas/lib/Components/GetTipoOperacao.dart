String getTipo(String op) {
  String desc = "";
  switch (op) {
    case "10":
      desc = "10 - Entrada de Mercadoria";
      break;
    case "21":
      desc = "21 - Retirada para Produção";
      break;
    case "20":
      desc = "20 - Devolução da Produção";
      break;
    case "31":
      desc = "31 - Retirada para Venda";
      break;
    case "30":
      desc = "30 - Devolução de Venda";
      break;
    case "41":
      desc = "41 - Saída de Transferência";
      break;
    case "40":
      desc = "40 - Entrada de Transferência";
      break;
    case "90":
      desc = "90 - Contagem de  Inventário";
      break;
    default:
  }
  return desc;
}
