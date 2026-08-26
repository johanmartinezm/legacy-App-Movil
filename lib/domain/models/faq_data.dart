/// Las preguntas frecuentes, en las cuatro secciones que pide el documento de
/// alcance ("FAQ (4 secciones)").
///
/// El contenido vive en la app y no en el backend a proposito: son respuestas
/// sobre como funciona la aplicacion, cambian con ella y se despliegan con ella.
/// Si algun dia hay que editarlas sin publicar una version, tendran que pasar a
/// una tabla y a un modulo del panel.
///
/// **Cada respuesta describe lo que la app hace hoy.** Al cambiar una funcion,
/// esta lista es parte del cambio: una FAQ que promete algo que ya no ocurre
/// hace mas dano que no tener FAQ.
library;

class PreguntaFrecuente {
  final String pregunta;
  final String respuesta;

  const PreguntaFrecuente(this.pregunta, this.respuesta);
}

class SeccionFaq {
  final String titulo;
  final List<PreguntaFrecuente> preguntas;

  const SeccionFaq(this.titulo, this.preguntas);
}

const List<SeccionFaq> seccionesFaq = [
  SeccionFaq('Cuenta y acceso', [
    PreguntaFrecuente(
      '¿Cómo creo mi cuenta?',
      'Desde "Crear cuenta" en la pantalla de inicio de sesión. Se elige uno de los tres perfiles '
          '—familia empresaria, empresa o miembro de junta o consejo— y ese perfil adapta lo que se '
          've en la pantalla principal. Puede cambiarse después desde Mi perfil.',
    ),
    PreguntaFrecuente(
      '¿Puedo entrar con Google o con Apple?',
      'Sí. El acceso con Google está disponible en Android y en iPhone. El acceso con Apple aparece '
          'solo en iPhone y iPad, que es donde Apple lo permite.',
    ),
    PreguntaFrecuente(
      'Olvidé mi contraseña',
      'En la pantalla de inicio de sesión, toca "¿Olvidaste tu contraseña?" y escribe tu correo. '
          'Recibirás un enlace para crear una nueva. Si no llega en unos minutos, revisa la carpeta '
          'de correo no deseado.',
    ),
    PreguntaFrecuente(
      '¿Cómo elimino mi cuenta?',
      'En Mi perfil, opción "Eliminar mi cuenta". El borrado es permanente y se hace desde la propia '
          'app, sin tener que escribir a nadie. Se eliminan tus datos personales; los mensajes que '
          'hayas enviado a otras personas dejan de mostrar tu identidad.',
    ),
  ]),
  SeccionFaq('Comunidad y foros', [
    PreguntaFrecuente(
      '¿Los foros son anónimos?',
      'En los foros participas con un alias, no con tu nombre. El alias se elige una vez y es el '
          'mismo en todos los foros, para que se pueda seguir una conversación sin exponer quién eres.',
    ),
    PreguntaFrecuente(
      '¿Puedo escribirle a otro miembro?',
      'Sí. El chat es entre dos personas: envías una invitación a conectar desde el directorio de '
          'miembros y, cuando la acepta, pueden conversar. No hay chats de grupo.',
    ),
    PreguntaFrecuente(
      '¿Qué son las sinergias?',
      'Publicaciones donde un miembro propone una oportunidad concreta —un socio, un proveedor, una '
          'alianza— y el resto puede comentarla o mostrar interés. Se publican desde el Comité de '
          'sinergias.',
    ),
    PreguntaFrecuente(
      'Alguien se comporta de forma inapropiada',
      'Puedes bloquear a esa persona o reportar una publicación desde el menú de sus mensajes. Al '
          'bloquear, deja de verte y de poder escribirte, y desaparece de tu directorio. Los bloqueos '
          'se pueden deshacer en Mi perfil, en "Cuentas bloqueadas". Los reportes los revisa el equipo '
          'de Legacy Network.',
    ),
  ]),
  SeccionFaq('Eventos', [
    PreguntaFrecuente(
      '¿Cómo me inscribo a un evento?',
      'Abre el evento desde la sección Eventos y toca el botón de reservar. Si el evento es gratuito, '
          'tu cupo queda confirmado en ese momento. Si tiene costo, la inscripción queda pendiente '
          'hasta completar el pago.',
    ),
    PreguntaFrecuente(
      '¿Dónde veo mi credencial de acceso?',
      'En Mi credencial, dentro de Mi perfil. Es un código QR que el equipo escanea al llegar al '
          'evento para registrar tu asistencia.',
    ),
    PreguntaFrecuente(
      '¿Puedo armar mi propia agenda?',
      'En los eventos con varios talleres puedes elegir a cuáles asistir y verlos juntos en Mi '
          'agenda. También puedes quitar los que ya no te interesen.',
    ),
    PreguntaFrecuente(
      '¿Puedo inscribir a otra persona?',
      'Sí. Al reservar puedes indicar los datos del participante si no eres tú quien asiste. Esos '
          'datos se guardan cifrados y solo se usan para la organización del evento.',
    ),
    PreguntaFrecuente(
      '¿Qué pasa con las encuestas?',
      'Después de un evento puedes calificar cada taller y responder una encuesta general. Las '
          'respuestas ayudan a preparar los siguientes y solo las ve el equipo organizador.',
    ),
  ]),
  SeccionFaq('Privacidad y notificaciones', [
    PreguntaFrecuente(
      '¿Qué datos guarda Legacy Network sobre mí?',
      'Los que registras: nombre, correo, teléfono, fecha de nacimiento, documento, empresa y cargo, '
          'además de lo que publicas en la app. Los datos personales y los mensajes se guardan '
          'cifrados. El detalle completo está en la política de privacidad, enlazada desde Avisos '
          'legales.',
    ),
    PreguntaFrecuente(
      '¿Quién ve mi perfil?',
      'Los demás miembros de la comunidad. Desde Mi perfil puedes controlar si tu perfil es público, '
          'si aceptas mensajes de personas con las que aún no has conectado y si se muestra tu '
          'actividad.',
    ),
    PreguntaFrecuente(
      '¿Por qué no me llegan las notificaciones?',
      'Revisa que las notificaciones estén activadas para Legacy Network en los ajustes de tu teléfono. '
          'Con la app abierta en pantalla no aparece el aviso del sistema: el mensaje se muestra '
          'dentro de la propia app.',
    ),
    PreguntaFrecuente(
      '¿Cómo contacto al equipo?',
      'Desde Mi perfil, opción Contáctenos: escribes tu mensaje y te respondemos al correo de tu '
          'cuenta.',
    ),
  ]),
];
