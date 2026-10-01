// Amostras que o validar_tokens.py DEVE reprovar. Nao e compilado: so lido.
// Cada linha com `// ESPERA: <tipo>` precisa gerar achado desse tipo.

final a = EdgeInsets.all(8); // ESPERA: espacamento
final b = EdgeInsets.symmetric(horizontal: 12); // ESPERA: espacamento
final c = EdgeInsets.only(left: 8); // ESPERA: espacamento
final d = EdgeInsets.fromLTRB(MemoraEspacamento.sm, 8, 0, 0); // ESPERA: espacamento
final e = EdgeInsetsDirectional.only(start: 4); // ESPERA: espacamento
final f = Radius.circular(8); // ESPERA: raio
final g = BorderRadius.circular(8); // ESPERA: raio
final h = Color.fromARGB(255, 10, 20, 30); // ESPERA: cor
final i = Color.fromRGBO(10, 20, 30, 1.0); // ESPERA: cor
final j = Color(0xFF112233); // ESPERA: cor
final k = Color(4278190080); // ESPERA: cor
final l = Colors.red; // ESPERA: cor
final m = SizedBox(width: 24); // ESPERA: tamanho
final n = Icon(Icons.add, size: 22); // ESPERA: tamanho
// O `//` dentro de string nao pode esconder o que vem depois:
final o = ['http://x', Colors.blue]; // ESPERA: cor
final p = ['http://x', EdgeInsets.all(3)]; // ESPERA: espacamento
