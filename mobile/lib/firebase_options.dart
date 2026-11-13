import 'package:firebase_core/firebase_core.dart';

/// Proyecto Firebase de Atlas Motors (`atlas-motors-cl`).
/// La API key de una app cliente de Firebase no es secreta: identifica el
/// proyecto. Lo que protege los datos son las reglas de Firestore y el login.
const firebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyA4bbFDB8uqFx28_z0AYwnktZ-x6uxNZmg',
  appId: '1:42236350951:ios:3defe495f70d2697dd6d42',
  messagingSenderId: '42236350951',
  projectId: 'atlas-motors-cl',
  storageBucket: 'atlas-motors-cl.firebasestorage.app',
  iosBundleId: 'cl.atlasmotors.atlasInspecciones',
);
