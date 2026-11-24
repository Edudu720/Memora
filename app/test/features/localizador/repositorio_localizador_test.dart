import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/assistente/data/chamada_com_renovacao.dart';
import 'package:memora/features/autenticacao/data/ultimo_acesso_local.dart';
import 'package:memora/features/localizador/data/fontes/fonte_localizador_api.dart';
import 'package:memora/features/localizador/data/repositorios/repositorio_localizador_api.dart';
import 'package:memora/features/localizador/data/repositorios/repositorio_localizador_simulado.dart';
import 'package:memora/features/localizador/domain/entidades/categoria_servico.dart';
import 'package:memora/features/localizador/domain/entidades/estabelecimento_servico.dart';
import 'package:memora/features/localizador/domain/repositorios/repositorio_localizador.dart';
import 'package:memora/services/ambiente/ambiente.dart';
import 'package:memora/services/ambiente/composicao.dart';
import 'package:memora_api/memora_api.dart' as api;

import '../../suporte/aceite_em_memoria.dart';
import '../assistente/suporte_da_api_falsa.dart';

class _UltimoAcessoEmMemoria implements UltimoAcesso {
  String? _id;

  @override
  Future<String?> identificador() async => _id;

  @override
  Future<void> lembrar(String identificador) async => _id = identificador;

  @override
  Future<void> esquecer() async => _id = null;
}

void main() {
  Map<String, Object?> payloadSucesso() => <String, Object?>{
    'consultaInterpretada': <String, Object?>{
      'categoriaIdentificada': 'SAUDE',
      'termoChave': 'posto de saúde',
      'mensagemExplicativa': 'Buscando postos de saúde em Campinas - SP',
    },
    'regiaoOrigem': <String, Object?>{
      'descricao': 'Campinas - SP',
      'latitude': -22.9099,
      'longitude': -47.0626,
      'modo': 'REGIAO_MANUAL',
    },
    'totalEncontrado': 1,
    'estabelecimentos': <Object?>[
      <String, Object?>{
        'id': 'osm:node:998877',
        'nome': 'Centro de Saúde Centro - Campinas',
        'categoria': 'SAUDE',
        'subtituloTipo': 'Posto de Saúde',
        'endereco': <String, Object?>{
          'logradouro': 'Av. Francisco Glicério',
          'numero': '100',
          'bairro': 'Centro',
          'cidade': 'Campinas',
          'estado': 'SP',
          'cep': '13012-000',
          'textoFormatado': 'Av. Francisco Glicério, 100 - Centro, Campinas - SP',
        },
        'latitude': -22.9056,
        'longitude': -47.0608,
        'distanciaMetros': 420.0,
        'distanciaFormatada': '420 metros',
        'telefone': null,
        'horarioFuncionamento': null,
        'horarioConfirmado': false,
        'fonte': 'OPEN_STREET_MAP',
        'avisoTransparencia': null,
      },
    ],
  };

  group('FR-006/FR-007 — Fonte e Repositório real do Localizador', () {
    test('normaliza /servicos/buscar quando baseUrl termina com /v1 e renova token após 401', () async {
      final CofreEmMemoria cofre = CofreEmMemoria(
        acesso: 'token-vencido',
      );
      final RenovadorFalso renovador = RenovadorFalso(cofre);
      final AdaptadorFalso adaptador = AdaptadorFalso((RequestOptions op, int n) async {
        if (n == 1) {
          return respostaJson(401, <String, Object>{'erro': 'EXPIRADO'});
        }
        return respostaJson(200, payloadSucesso());
      });

      final api.MemoraApi cliente = clienteFalso(adaptador);
      final RepositorioLocalizadorApi repo = RepositorioLocalizadorApi(
        fonte: FonteLocalizadorApi(
          cliente.dio,
          chamadas: ChamadaComRenovacao(
            cliente: cliente,
            cofre: cofre,
            renovar: renovador.renovar,
          ),
        ),
      );

      final ResultadoBuscaServicos resultado = await repo.buscarServicos(
        categoria: CategoriaServico.saude,
        regiaoManual: 'Campinas, SP',
      );

      expect(adaptador.pedidos.length, 2);
      expect(adaptador.pedidos[0].path, '/servicos/buscar');
      expect(adaptador.pedidos[0].headers['Authorization'], 'Bearer token-vencido');
      expect(adaptador.pedidos[1].headers['Authorization'], 'Bearer acesso-2');
      expect(renovador.chamadas, 1);

      expect(resultado.ehDemonstracao, isFalse);
      expect(resultado.descricaoRegiao, 'Campinas - SP');
      expect(resultado.latitudeRegiao, closeTo(-22.9099, 0.0001));
      expect(resultado.longitudeRegiao, closeTo(-47.0626, 0.0001));
      expect(resultado.estabelecimentos.single.nome, 'Centro de Saúde Centro - Campinas');
    });

    test('usa /api/v1/servicos/buscar quando baseUrl não termina em /v1', () async {
      final AdaptadorFalso adaptador = AdaptadorFalso(
        (RequestOptions op, int n) async => respostaJson(200, payloadSucesso()),
      );
      final Dio dio = Dio(BaseOptions(baseUrl: 'http://servidor.teste'))
        ..httpClientAdapter = adaptador;

      final FonteLocalizadorApi fonte = FonteLocalizadorApi(dio);
      await fonte.buscarServicos(regiaoManual: 'Campinas, SP');

      expect(adaptador.pedidos.single.path, '/api/v1/servicos/buscar');
    });

    test('envia o código de categoria que o servidor reconhece (SERVICOS_PUBLICOS com sublinhado)', () async {
      const Map<CategoriaServico, String> esperado = <CategoriaServico, String>{
        CategoriaServico.saude: 'SAUDE',
        CategoriaServico.servicosPublicos: 'SERVICOS_PUBLICOS',
        CategoriaServico.emergencia: 'EMERGENCIA',
        CategoriaServico.cotidiano: 'COTIDIANO',
      };
      final AdaptadorFalso adaptador = AdaptadorFalso(
        (RequestOptions op, int n) async => respostaJson(200, payloadSucesso()),
      );
      final Dio dio = Dio(BaseOptions(baseUrl: 'http://servidor.teste/v1'))
        ..httpClientAdapter = adaptador;
      final FonteLocalizadorApi fonte = FonteLocalizadorApi(dio);

      for (final CategoriaServico categoria in CategoriaServico.values) {
        await fonte.buscarServicos(categoria: categoria, regiaoManual: 'Campinas, SP');
      }

      final List<Object?> enviados = adaptador.pedidos
          .map((RequestOptions p) => (p.data as Map<String, dynamic>)['categoria'])
          .toList();
      expect(enviados, CategoriaServico.values.map((CategoriaServico c) => esperado[c]).toList());
      for (final CategoriaServico categoria in CategoriaServico.values) {
        expect(CategoriaServico.porCodigo(esperado[categoria]), categoria);
      }
    });

    test('propaga erro sem acionar dados fictícios simulados quando servidor retorna 503', () async {
      final AdaptadorFalso adaptador = AdaptadorFalso(
        (RequestOptions op, int n) async => respostaJson(503, <String, Object>{
          'mensagem': 'OpenStreetMap indisponível',
        }),
      );
      final api.MemoraApi cliente = clienteFalso(adaptador);
      final RepositorioLocalizadorApi repo = RepositorioLocalizadorApi(
        fonte: FonteLocalizadorApi(cliente.dio),
      );

      await expectLater(
        () => repo.buscarServicos(regiaoManual: 'Campinas, SP'),
        throwsException,
      );
    });
  });

  group('FR-006 — Composição por ambiente', () {
    test('instancia RepositorioLocalizadorApi com servidor real e Simulado offline', () {
      final Composicao real = Composicao.resolver(
        ambiente: const Ambiente(
          urlBase: 'http://127.0.0.1:8080/v1',
          usaServidorReal: true,
        ),
        cofre: CofreEmMemoria(),
        ultimoAcesso: _UltimoAcessoEmMemoria(),
        aceiteDoAviso: AceiteEmMemoria(),
      );
      expect(real.localizador, isA<RepositorioLocalizadorApi>());

      final Composicao offline = Composicao.resolver(
        ambiente: const Ambiente(
          urlBase: 'http://127.0.0.1:8080/v1',
          usaServidorReal: false,
        ),
        cofre: CofreEmMemoria(),
        ultimoAcesso: _UltimoAcessoEmMemoria(),
        aceiteDoAviso: AceiteEmMemoria(),
      );
      expect(offline.localizador, isA<RepositorioLocalizadorSimulado>());
    });
  });

  group('FR-008 — Segurança no modo de demonstração simulado', () {
    test('todos os estabelecimentos simulados possuem telefone == null (inclusive emergência)', () async {
      for (final EstabelecimentoServico est
          in RepositorioLocalizadorSimulado.todosOsEstabelecimentos) {
        expect(est.telefone, isNull);
        expect(est.temTelefone, isFalse);
      }

      final RepositorioLocalizadorSimulado repo = RepositorioLocalizadorSimulado();
      final ResultadoBuscaServicos resultado = await repo.buscarServicos(
        categoria: CategoriaServico.emergencia,
      );

      expect(resultado.ehDemonstracao, isTrue);
      expect(resultado.descricaoRegiao.toLowerCase(), contains('demonstra'));
      expect(resultado.estabelecimentos, isNotEmpty);
      expect(
        resultado.estabelecimentos.every((EstabelecimentoServico e) => e.telefone == null),
        isTrue,
      );
    });
  });
}
