import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/componentes/ilustracao/memora_animada/agenda_da_anfitria.dart';

/// A agenda dos comportamentos da anfitriã (feature 013, T088, FR-049): eles
/// "se alternam sem padrão óbvio".
void main() {
  List<PassoDaAgenda> passos(int semente, int quantos) {
    final AgendaDaAnfitria agenda = AgendaDaAnfitria(semente: semente);
    return <PassoDaAgenda>[for (int i = 0; i < quantos; i++) agenda.proximo()];
  }

  /// Só os comportamentos, sem as pausas entre eles.
  List<ComportamentoDaAnfitria> comportamentos(
    List<PassoDaAgenda> lista,
  ) => <ComportamentoDaAnfitria>[
    for (final PassoDaAgenda p in lista)
      if (p.comportamento != ComportamentoDaAnfitria.descansar) p.comportamento,
  ];

  test('o mesmo comportamento nunca vem duas vezes seguidas', () {
    for (int semente = 0; semente < 20; semente++) {
      final List<ComportamentoDaAnfitria> c = comportamentos(
        passos(semente, 200),
      );
      for (int i = 1; i < c.length; i++) {
        expect(c[i], isNot(c[i - 1]), reason: 'semente $semente, posicao $i');
      }
    }
  });

  test('entre um comportamento e outro ela descansa', () {
    final List<PassoDaAgenda> p = passos(3, 100);
    for (int i = 0; i < p.length - 1; i++) {
      final bool a = p[i].comportamento == ComportamentoDaAnfitria.descansar;
      final bool b =
          p[i + 1].comportamento == ComportamentoDaAnfitria.descansar;
      expect(a && b, isFalse, reason: 'duas pausas seguidas em $i');
      if (!a) {
        expect(b, isTrue, reason: 'um comportamento sem pausa depois, em $i');
      }
    }
  });

  test('o descanso tem duração variada, e nunca é longo demais', () {
    final Set<double> duracoes = <double>{};
    for (final PassoDaAgenda p in passos(5, 300)) {
      if (p.comportamento != ComportamentoDaAnfitria.descansar) continue;
      expect(p.duracao, inInclusiveRange(1.2, 4.5));
      duracoes.add(double.parse(p.duracao.toStringAsFixed(1)));
    }
    expect(
      duracoes.length,
      greaterThan(10),
      reason: 'pausas todas iguais viram relogio',
    );
  });

  test(
    'todos os comportamentos aparecem; olhar é o mais comum, pular o mais raro',
    () {
      final Map<ComportamentoDaAnfitria, int> contagem =
          <ComportamentoDaAnfitria, int>{};
      for (final ComportamentoDaAnfitria c in comportamentos(
        passos(11, 2000),
      )) {
        contagem[c] = (contagem[c] ?? 0) + 1;
      }
      for (final ComportamentoDaAnfitria c in ComportamentoDaAnfitria.values) {
        if (c == ComportamentoDaAnfitria.descansar) continue;
        expect(contagem[c], greaterThan(0), reason: '$c nunca aconteceu');
      }
      final int olhar = contagem[ComportamentoDaAnfitria.olharEmVolta]!;
      final int pular = contagem[ComportamentoDaAnfitria.pular]!;
      expect(olhar, greaterThan(pular * 2));
      for (final ComportamentoDaAnfitria c in contagem.keys) {
        expect(contagem[c]!, greaterThanOrEqualTo(pular), reason: '$c');
      }
    },
  );

  test(
    'não é um ciclo: nenhuma volta curta se repete, e cada semente é outra',
    () {
      final List<ComportamentoDaAnfitria> c = comportamentos(passos(2, 400));
      for (int volta = 1; volta <= 8; volta++) {
        int iguais = 0;
        for (int i = volta; i < c.length; i++) {
          if (c[i] == c[i - volta]) iguais++;
        }
        // Um ciclo de `volta` comportamentos daria 100% de igualdade. Um sorteio
        // não passa de uns 60% (o "nunca repete" já força diferenças em volta 1).
        expect(
          iguais / (c.length - volta),
          lessThan(0.75),
          reason: 'a sequencia se repete a cada $volta comportamentos',
        );
      }
      final List<ComportamentoDaAnfitria> a = comportamentos(passos(1, 60));
      final List<ComportamentoDaAnfitria> b = comportamentos(passos(2, 60));
      expect(a, isNot(b));
    },
  );

  test('os lados do olhar e da inclinação também mudam', () {
    final Set<double> lados = <double>{
      for (final PassoDaAgenda p in passos(9, 200)) p.sinal,
    };
    expect(lados, containsAll(<double>[-1, 1]));
  });
}
