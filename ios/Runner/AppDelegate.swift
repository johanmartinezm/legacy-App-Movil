import AuthenticationServices
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let registrar = self.registrar(forPlugin: "BotonAppleNativo") {
      registrar.register(
        FabricaBotonApple(mensajero: registrar.messenger()),
        withId: FabricaBotonApple.identificador
      )
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// MARK: - Boton nativo de Sign in with Apple
//
// Apple rechazo la version 1.0 (21) por la directriz 4: el boton era un
// contenedor propio con el texto "Apple", y el motivo citado fue que el arte del
// logotipo no venia de Apple Design Resources. ASAuthorizationAppleIDButton es
// el boton del propio sistema: no hay ningun recurso grafico que revisar, ni
// tamanos ni colores que se puedan desviar de la guia.
//
// Vive aqui, dentro de AppDelegate.swift, y no en su propio archivo a proposito:
// anadir un .swift nuevo obliga a editar Runner.xcodeproj/project.pbxproj a
// mano, y este proyecto se compila desde GitHub Actions sin un Mac delante donde
// comprobar que el archivo quedo bien referenciado.

class FabricaBotonApple: NSObject, FlutterPlatformViewFactory {
  static let identificador = "legacy/boton-apple"

  private let mensajero: FlutterBinaryMessenger

  init(mensajero: FlutterBinaryMessenger) {
    self.mensajero = mensajero
    super.init()
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?)
    -> FlutterPlatformView
  {
    BotonApple(frame: frame, viewId: viewId, argumentos: args, mensajero: mensajero)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

class BotonApple: NSObject, FlutterPlatformView {
  private let boton: ASAuthorizationAppleIDButton
  private let canal: FlutterMethodChannel

  init(frame: CGRect, viewId: Int64, argumentos: Any?, mensajero: FlutterBinaryMessenger) {
    // El fondo del login es oscuro, asi que el boton va en blanco. Son los dos
    // unicos estilos que la guia permite, mas el blanco con borde.
    var estilo: ASAuthorizationAppleIDButton.Style = .white
    var radio: CGFloat = 12

    if let opciones = argumentos as? [String: Any] {
      if let claro = opciones["claro"] as? Bool, claro == false {
        estilo = .black
      }
      if let r = opciones["radio"] as? NSNumber {
        radio = CGFloat(truncating: r)
      }
    }

    boton = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: estilo)
    boton.cornerRadius = radio
    canal = FlutterMethodChannel(
      name: "\(FabricaBotonApple.identificador)/\(viewId)",
      binaryMessenger: mensajero
    )

    super.init()

    // El boton solo avisa del toque: quien pide la credencial sigue siendo
    // SignInWithApple.getAppleIDCredential en Dart, que es donde esta el resto
    // del flujo (auth_provider.dart).
    boton.addTarget(self, action: #selector(tocado), for: .touchUpInside)
  }

  func view() -> UIView { boton }

  @objc private func tocado() {
    canal.invokeMethod("tocado", arguments: nil)
  }
}
