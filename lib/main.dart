import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'domain/providers/cart_provider.dart';
import 'domain/providers/auth_provider.dart';
import 'domain/providers/favorites_provider.dart';
import 'domain/providers/events_provider.dart';
import 'domain/providers/chat_provider.dart';
import 'domain/providers/notification_provider.dart';
import 'domain/providers/banner_provider.dart';
import 'domain/providers/block_provider.dart';
import 'data/services/event_service.dart';
import 'data/services/chat_service.dart';
import 'data/config/config_service.dart';
import 'config/theme/app_theme.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/forgot_password_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/informandote/informandote_screen.dart';
import 'presentation/screens/legal_notice_screen.dart';
import 'presentation/screens/profile_selection_screen.dart';
import 'presentation/screens/splash_screen.dart';

import 'presentation/screens/cart/cart_screen.dart';
import 'presentation/screens/cart/checkout_screen.dart';
import 'presentation/screens/cart/confirmation_screen.dart';
import 'presentation/screens/favorites/favorites_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/profile/usuarios_bloqueados_screen.dart';
import 'presentation/screens/profile/mi_credencial_screen.dart';
import 'presentation/screens/profile/profile_edit_screen.dart';
import 'presentation/screens/informandote/article_detail_screen.dart';
import 'presentation/screens/informandote/video_detail_screen.dart';
import 'domain/models/content_model.dart';
import 'presentation/screens/asesoria/asesoria_screen.dart';
import 'presentation/screens/books/books_screen.dart';
import 'presentation/screens/chat/chatbot_screen.dart';
import 'presentation/screens/programs/programs_screen.dart';
import 'presentation/screens/programs/program_detail_screen.dart';
import 'presentation/screens/chat/chat_list_screen.dart';
import 'presentation/screens/payment_callback_screen.dart';
import 'presentation/screens/chat/individual_chat_screen.dart';
import 'presentation/screens/chat/community_members_screen.dart';
import 'presentation/screens/comunidad/miembros_info_screen.dart';
import 'domain/models/program_model.dart';
import 'presentation/screens/main_layout.dart';
import 'presentation/screens/community/synergy_list_screen.dart';
import 'presentation/screens/community/synergy_detail_screen.dart';
import 'presentation/screens/community/synergy_create_screen.dart';
import 'domain/models/synergy_model.dart';
import 'presentation/screens/books/book_detail_screen.dart';
import 'domain/models/book_model.dart';
import 'presentation/screens/legacy_plus/legacy_plus_screen.dart';
import 'presentation/screens/notifications/notifications_screen.dart';
import 'domain/providers/forum_provider.dart';
import 'presentation/screens/forums/forums_list_screen.dart';
import 'presentation/screens/forums/forum_proposal_screen.dart';
import 'presentation/screens/forums/forum_thread_screen.dart';
import 'domain/models/forum_model.dart';
import 'domain/models/event_model.dart';
import 'domain/utils/notificacion_destino.dart';
import 'presentation/screens/eventos/event_purchase_detail_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Mensaje recibido en segundo plano: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigService.initialize();

  // Inicialización de Firebase con configuración de FlutterFire.
  // firebase_options.dart no tiene configuración para web: DefaultFirebaseOptions
  // lanza UnsupportedError y, al estar antes de runApp, la app no arrancaba en
  // Chrome. Se omite en web para poder desarrollar ahí; las notificaciones push
  // en web quedan fuera hasta que se registre la app web en Firebase.
  if (!kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  final authProvider = AuthProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ForumProvider>(
          create: (_) => ForumProvider(authProvider),
          update: (_, auth, previous) => previous ?? ForumProvider(auth),
        ),
        ChangeNotifierProvider(
          create: (_) => EventsProvider(eventService: EventService()),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (_) => ChatProvider(ChatService('')),
          update: (_, auth, previous) =>
              previous!..updateToken(auth.token ?? ''),
        ),
        ChangeNotifierProxyProvider<AuthProvider, BannerProvider>(
          create: (_) => BannerProvider(),
          update: (_, auth, previous) => previous!..updateToken(auth.token),
        ),
        // Bloquear y reportar personas (directriz 1.2 de Apple).
        ChangeNotifierProxyProvider<AuthProvider, BlockProvider>(
          create: (_) => BlockProvider(),
          update: (_, auth, previous) => previous!..updateToken(auth.token),
        ),
      ],
      child: const MyAppWrapper(),
    ),
  );
}

class MyAppWrapper extends StatefulWidget {
  const MyAppWrapper({super.key});

  @override
  State<MyAppWrapper> createState() => _MyAppWrapperState();
}

class _MyAppWrapperState extends State<MyAppWrapper> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _router = _buildRouter(authProvider);
    _initPushNotifications();
  }

  void _initPushNotifications() async {
    // En web Firebase no se inicializa (ver main): sin esto, FirebaseMessaging
    // .instance revienta en el initState y la app no llega a pintar.
    if (kIsWeb) return;

    final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

    // Solicitar permisos (Crucial para iOS, y para Android 13+)
    NotificationSettings settings = await firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('Estado de permisos concedidos: ${settings.authorizationStatus}');

    // Obtener el Token FCM
    String? token;
    try {
      token = await firebaseMessaging.getToken();
      print("---------------- FCM TOKEN ----------------");
      print(token);
      print("-------------------------------------------");
    } catch (e) {
      print(
        "No se pudo obtener el token FCM (Común en simulador iOS sin APNS): $e",
      );
    }

    // Escuchar mensajes en primer plano (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null && mounted) {
        print('Notificación en primer plano: ${message.notification!.title}');
        Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).addNotification(
          title: message.notification!.title ?? '',
          body: message.notification!.body ?? '',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${message.notification!.title}: ${message.notification!.body}',
            ),
            backgroundColor: const Color(0xFF0B1A2E),
          ),
        );
      }
    });

    // Manejar la apertura de la app al presionar una notificación (Segundo plano)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('El usuario abrió la app desde la notificación: ${message.data}');
      if (message.notification != null && mounted) {
        Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).addNotification(
          title: message.notification!.title ?? '',
          body: message.notification!.body ?? '',
        );
      }
      abrirNovedad(_router, message.data);
    });

    // Con la app cerrada del todo, el toque no llega por onMessageOpenedApp:
    // Firebase lo guarda y hay que preguntarlo al arrancar. Sin esto, abrir la
    // app desde una notificación con la app terminada no navegaba a ninguna
    // parte.
    final inicial = await firebaseMessaging.getInitialMessage();
    if (inicial != null && mounted) {
      abrirNovedad(_router, inicial.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MyApp(router: _router);
  }

  GoRouter _buildRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isSplash = state.uri.path == '/';
        final isLoggingIn = state.uri.path == '/login';

        if (state.uri.path == '/register' ||
            state.uri.path == '/legal-notice' ||
            state.uri.path == '/profile-selection' ||
            state.uri.path == '/forgot-password' ||
            isSplash) {
          return null;
        }

        if (!isAuthenticated && !isLoggingIn) {
          return '/login';
        }

        if (isAuthenticated && isLoggingIn) {
          return '/home';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(
          path: '/legal-notice',
          builder: (context, state) => const LegalNoticeScreen(),
        ),
        GoRoute(
          path: '/profile-selection',
          builder: (context, state) => const ProfileSelectionScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) {
            final role = state.uri.queryParameters['role'];
            final extraData = state.extra as Map<String, dynamic>?;
            return RegisterScreen(role: role, socialData: extraData);
          },
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/payment-callback',
          builder: (context, state) {
            // El backend añade ?tx_id=... a la URL de retorno antes de dársela
            // a la pasarela, así que el id de la transacción está garantizado
            // se llame como se llame lo que CredibanCo agregue por su cuenta.
            // Se aceptan los nombres antiguos por si llega un enlace viejo.
            final q = state.uri.queryParameters;
            final txId = q['tx_id'] ?? q['order_id'] ?? q['orderId'] ?? '';
            return PaymentCallbackScreen(orderId: txId);
          },
        ),

        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) {
                final tabIndex =
                    int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
                return HomeScreen(initialIndex: tabIndex);
              },
            ),
            GoRoute(
              path: '/informandote',
              builder: (context, state) => const InformandoteScreen(),
            ),
            GoRoute(
              path: '/asesoria',
              builder: (context, state) => const AsesoriaScreen(),
            ),
            GoRoute(
              path: '/libros',
              builder: (context, state) => const BooksScreen(),
            ),
            GoRoute(
              path: '/book-detail',
              builder: (context, state) {
                final book = state.extra as GraphqlBook;
                return BookDetailScreen(book: book);
              },
            ),
            GoRoute(
              path: '/chatbot',
              builder: (context, state) => const ChatBotScreen(),
            ),
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
            GoRoute(
              path: '/legacy-plus',
              builder: (context, state) => const LegacyPlusScreen(),
            ),
            GoRoute(
              path: '/programas',
              builder: (context, state) => const ProgramsScreen(),
            ),
            GoRoute(
              path: '/programa-detalle',
              builder: (context, state) {
                final program = state.extra as GraphqlProgram;
                return ProgramDetailScreen(program: program);
              },
            ),
            GoRoute(
              path: '/chat-list',
              builder: (context, state) => const ChatListScreen(),
            ),
            GoRoute(
              path: '/individual-chat/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                final title = state.uri.queryParameters['title'] ?? 'Chat';
                return IndividualChatScreen(connectionId: id, chatTitle: title);
              },
            ),
            GoRoute(
              path: '/comunidad-miembros',
              builder: (context, state) => const CommunityMembersScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/cuentas-bloqueadas',
              builder: (context, state) => const UsuariosBloqueadosScreen(),
            ),
            GoRoute(
              path: '/profile-edit',
              builder: (context, state) => const ProfileEditScreen(),
            ),
            GoRoute(
              path: '/mi-credencial',
              builder: (context, state) => const MiCredencialScreen(),
            ),
            GoRoute(
              path: '/miembros-info',
              builder: (context, state) => const MiembrosInfoScreen(),
            ),
            GoRoute(
              path: '/comite-sinergias',
              builder: (context, state) => const SynergyListScreen(),
            ),
            GoRoute(
              path: '/comite-sinergias/detalle',
              builder: (context, state) {
                final synergy = state.extra as Synergy;
                return SynergyDetailScreen(synergy: synergy);
              },
            ),
            GoRoute(
              path: '/comite-sinergias/crear',
              builder: (context, state) => const SynergyCreateScreen(),
            ),
            GoRoute(
              path: '/forums',
              builder: (context, state) => const ForumsListScreen(),
            ),
            GoRoute(
              path: '/forum-propose',
              builder: (context, state) => const ForumProposalScreen(),
            ),
            GoRoute(
              path: '/forum-thread',
              builder: (context, state) {
                final forum = state.extra as Forum;
                return ForumThreadScreen(forum: forum);
              },
            ),
          ],
        ),

        GoRoute(
          path: '/article-detail',
          builder: (context, state) {
            final article = state.extra as ContentItem;
            return ArticleDetailScreen(article: article);
          },
        ),
        GoRoute(
          path: '/video-detail',
          builder: (context, state) {
            final video = state.extra as ContentItem;
            return VideoDetailScreen(video: video);
          },
        ),
        // Detalle de un evento de la API, el mismo que abre la pestaña
        // "Eventos". Necesita ruta propia para poder llegar a él desde una
        // notificación.
        //
        // Ojo: NO es EventDetailScreen, que trabaja con EventItem y se alimenta
        // del JSON estático de assets/data/events_data.json. Los eventos que
        // notifica el backend son EventModel.
        GoRoute(
          path: '/evento',
          builder: (context, state) {
            final evento = state.extra as EventModel;
            return EventPurchaseDetailScreen(event: evento);
          },
        ),
        GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
        GoRoute(
          path: '/checkout',
          builder: (context, state) => const CheckoutScreen(),
        ),
        GoRoute(
          path: '/confirmation',
          builder: (context, state) => const ConfirmationScreen(),
        ),
        GoRoute(
          path: '/favorites',
          builder: (context, state) => const FavoritesScreen(),
        ),
      ],
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  const MyApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Legacy App',
      theme: AppTheme.lightTheme,
      scrollBehavior: MyCustomScrollBehavior(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
