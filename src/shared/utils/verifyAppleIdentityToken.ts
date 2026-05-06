import { createHash } from "crypto";
import https from "https";
import jwt from "jsonwebtoken";
import jwkToPem from "jwk-to-pem";
import type { RSA } from "jwk-to-pem";

const APPLE_ISSUER = "https://appleid.apple.com";

export interface AppleIdTokenPayload {
    sub: string;
    email?: string;
    email_verified?: boolean;
}

interface Jwk {
    kid?: string;
    [key: string]: unknown;
}

let jwksCache: { keys: Jwk[]; fetchedAt: number } | null = null;
const JWKS_TTL_MS = 60 * 60 * 1000;

function fetchAppleJwks(): Promise<Jwk[]> {
    return new Promise((resolve, reject) => {
        https
            .get("https://appleid.apple.com/auth/keys", (res) => {
                let data = "";
                res.on("data", (chunk: string) => {
                    data += chunk;
                });
                res.on("end", () => {
                    try {
                        const json = JSON.parse(data) as { keys?: Jwk[] };
                        resolve(json.keys ?? []);
                    } catch (e) {
                        reject(e);
                    }
                });
            })
            .on("error", reject);
    });
}

async function getAppleSigningKeys(): Promise<Jwk[]> {
    const now = Date.now();
    if (jwksCache && now - jwksCache.fetchedAt < JWKS_TTL_MS) {
        return jwksCache.keys;
    }
    const keys = await fetchAppleJwks();
    jwksCache = { keys, fetchedAt: now };
    return keys;
}

/**
 * Verifica identityToken de Sign in with Apple (JWKS Apple).
 * `audience` debe ser el Bundle ID de la app iOS (ej. com.example.app).
 */
export async function verifyAppleIdentityToken(
    identityToken: string,
    options: { audience: string; rawNonce: string },
): Promise<AppleIdTokenPayload> {
    const decoded = jwt.decode(identityToken, { complete: true });
    if (!decoded || typeof decoded === "string" || !decoded.header.kid) {
        throw new Error("Token inválido");
    }

    let keys = await getAppleSigningKeys();
    let jwk = keys.find((k) => k.kid === decoded.header.kid);
    if (!jwk) {
        jwksCache = null;
        keys = await getAppleSigningKeys();
        jwk = keys.find((k) => k.kid === decoded.header.kid);
    }
    if (!jwk) {
        throw new Error("Clave Apple no encontrada");
    }

    // jwk-to-pem espera JWK RSA estándar (Apple usa RS256)
    const pem = jwkToPem(jwk as unknown as RSA);
    const payload = jwt.verify(identityToken, pem, {
        algorithms: ["RS256"],
        issuer: APPLE_ISSUER,
        audience: options.audience,
    }) as jwt.JwtPayload;

    const sub = typeof payload.sub === "string" ? payload.sub : "";
    if (!sub) {
        throw new Error("Token sin subject");
    }

    const expectedNonce = createHash("sha256").update(options.rawNonce).digest("hex");
    const nonceClaim = payload.nonce;
    if (typeof nonceClaim !== "string" || nonceClaim !== expectedNonce) {
        throw new Error("Nonce inválido");
    }

    const emailRaw = typeof payload.email === "string" ? payload.email.trim().toLowerCase() : undefined;
    const ev = payload.email_verified;
    const emailVerified = ev === true || ev === "true";
    const email = emailRaw && emailVerified ? emailRaw : undefined;

    return { sub, email, email_verified: emailVerified };
}
