import * as admin from 'firebase-admin';

let firebaseApp: admin.app.App | null = null;

export const initializeFirebase = () => {
  if (!firebaseApp) {
    try {
      // Para desarrollo - usar credenciales por defecto o archivo de servicio
      firebaseApp = admin.initializeApp({
        // Si tienes un archivo de credenciales, descomenta la siguiente línea:
        // credential: admin.credential.cert(require('path/to/serviceAccountKey.json')),
        
        // Para desarrollo sin credenciales (modo mock)
        credential: admin.credential.applicationDefault(),
      });
      console.log('Firebase Admin SDK initialized successfully');
    } catch (error) {
      console.warn('Firebase initialization failed, using mock mode:', error);
      // Inicializar en modo mock para desarrollo
      firebaseApp = admin.initializeApp({
        projectId: 'manejapp-dev',
      });
    }
  }
  return firebaseApp;
};

export const getFirebaseApp = () => {
  if (!firebaseApp) {
    return initializeFirebase();
  }
  return firebaseApp;
};