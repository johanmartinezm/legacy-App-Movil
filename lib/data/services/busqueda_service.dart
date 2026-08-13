import '../../domain/models/content_model.dart';
import '../../domain/models/event_model.dart';
import '../../domain/models/program_model.dart';
import '../../domain/models/resultado_busqueda.dart';
import '../../domain/models/synergy_model.dart';
import '../../domain/utils/busqueda_global.dart';
import '../models/user_model.dart';
import 'custom_content_service.dart';
import 'event_service.dart';
import 'graphql_service.dart';
import 'synergy_service.dart';

/// Reune en una sola lista todo lo que la busqueda global puede encontrar.
///
/// Las fuentes se piden **en paralelo y de forma independiente**: si una falla
/// —el GraphQL de WordPress y el de la escuela son de terceros y se caen solos—
/// el resto de la busqueda sigue funcionando en vez de quedarse en blanco. Antes
/// un fallo de WordPress dejaba la lupa sin resultados y con un error rojo.
class BusquedaService {
  final GraphqlService _graphql;
  final CustomContentService _contenidoPropio;
  final EventService _eventos;
  final SynergyService _sinergias;

  BusquedaService({
    GraphqlService? graphql,
    CustomContentService? contenidoPropio,
    EventService? eventos,
    SynergyService? sinergias,
  })  : _graphql = graphql ?? GraphqlService(),
        _contenidoPropio = contenidoPropio ?? CustomContentService(),
        _eventos = eventos ?? EventService(),
        _sinergias = sinergias ?? SynergyService();

  /// `miembros` llega ya cargado desde el ChatProvider: necesita sesion y el
  /// provider ya lo tiene en memoria, asi que pedirlo otra vez seria un viaje
  /// de mas.
  Future<List<ResultadoBusqueda>> cargarTodo({
    List<UserModel> miembros = const [],
  }) async {
    final resultados = await Future.wait([
      _sinFallar(() => _graphql.getPosts(first: 50).then((r) => r.posts.map((p) => p.toContentItem()).toList())),
      _sinFallar(() => _contenidoPropio.getCustomContents().then((l) => l.map((c) => c.toContentItem()).toList())),
      _sinFallar(() => _eventos.getEvents()),
      _sinFallar(() => _graphql.getPrograms(first: 20)),
      _sinFallar(() => _sinergias.getSynergies()),
    ]);

    return [
      ...(resultados[0] as List<ContentItem>).map(deContenido),
      ...(resultados[1] as List<ContentItem>).map(deContenido),
      ...(resultados[2] as List<EventModel>).map(deEvento),
      ...(resultados[3] as List<GraphqlProgram>).map(dePrograma),
      ...(resultados[4] as List<Synergy>).map(deSinergia),
      ...miembros.map(deMiembro),
    ];
  }

  Future<List<T>> _sinFallar<T>(Future<List<T>> Function() cargar) async {
    try {
      return await cargar();
    } catch (_) {
      return <T>[];
    }
  }
}

// Los mapeadores quedan fuera de la clase para poder probarlos sueltos, sin red.

ResultadoBusqueda deContenido(ContentItem c) => ResultadoBusqueda(
      tipo: TipoResultado.contenido,
      titulo: c.title,
      subtitulo: c.description ?? '',
      origen: c,
      textoBuscable: normalizar('${c.title} ${c.description ?? ''} ${c.category}'),
    );

ResultadoBusqueda deEvento(EventModel e) => ResultadoBusqueda(
      tipo: TipoResultado.evento,
      titulo: e.title,
      // La fecha y el lugar son lo que distingue un evento de otro en una lista
      // de resultados; la descripcion es demasiado larga para una linea.
      subtitulo: [e.date, e.location ?? ''].where((s) => s.isNotEmpty).join(' · '),
      origen: e,
      textoBuscable: normalizar('${e.title} ${e.description} ${e.location ?? ''} ${e.speaker ?? ''} ${e.category}'),
    );

ResultadoBusqueda dePrograma(GraphqlProgram p) => ResultadoBusqueda(
      tipo: TipoResultado.programa,
      titulo: p.name,
      subtitulo: [p.type, p.modality, p.duration].where((s) => s.isNotEmpty).join(' · '),
      origen: p,
      textoBuscable: normalizar('${p.name} ${p.shortDescription ?? ''} ${p.description ?? ''} ${p.type} ${p.modality}'),
    );

ResultadoBusqueda deSinergia(Synergy s) => ResultadoBusqueda(
      tipo: TipoResultado.sinergia,
      titulo: s.title,
      subtitulo: s.category,
      origen: s,
      textoBuscable: normalizar('${s.title} ${s.description} ${s.category}'),
    );

ResultadoBusqueda deMiembro(UserModel u) {
  final nombre = '${u.firstName} ${u.lastName}'.trim();
  return ResultadoBusqueda(
    tipo: TipoResultado.miembro,
    titulo: nombre,
    subtitulo: [u.jobTitle, u.companyName].where((s) => s.isNotEmpty).join(' · '),
    origen: u,
    textoBuscable: normalizar('$nombre ${u.jobTitle} ${u.companyName}'),
  );
}
