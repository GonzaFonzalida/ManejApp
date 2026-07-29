# Google Sign-In en Web: origen no autorizado

Si en la consola del navegador aparece **"The given origin is not allowed for the given client ID"** o **"Not signed in with the identity provider"** (FedCM/GSI):

1. Entrá a [Google Cloud Console](https://console.cloud.google.com/) → **APIs & Services** → **Credentials**.
2. Abrí el **OAuth 2.0 Client ID** que usás para la app web (tipo **Web application**).
3. En **Authorized JavaScript origins** agregá:
   - `http://localhost:7357`
   - `http://127.0.0.1:7357`
   - Y el puerto que uses si corrés con otro (ej. `http://localhost:XXXX`).
4. Guardá los cambios.

La app puede seguir usándose con **email y contraseña** aunque Google falle en web.
