import { prisma } from '@config/prismaClient';

interface BlacklistedToken {
  jti: string;
  expiresAt: Date;
}

export class TokenBlacklistService {
  private static blacklistedTokens = new Set<string>();

  static async blacklistToken(jti: string, expiresAt: Date): Promise<void> {
    this.blacklistedTokens.add(jti);
    
    // Store in database for persistence across server restarts
    try {
      await prisma.$executeRaw`
        INSERT INTO blacklisted_tokens (jti, expires_at) 
        VALUES (${jti}, ${expiresAt})
        ON CONFLICT (jti) DO NOTHING
      `;
    } catch (error) {
      console.error('Failed to persist blacklisted token:', error);
    }
  }

  static isBlacklisted(jti: string): boolean {
    return this.blacklistedTokens.has(jti);
  }

  static async loadBlacklistedTokens(): Promise<void> {
    try {
      const tokens = await prisma.$queryRaw<BlacklistedToken[]>`
        SELECT jti FROM blacklisted_tokens 
        WHERE expires_at > NOW()
      `;
      
      tokens.forEach(token => {
        this.blacklistedTokens.add(token.jti);
      });
    } catch (error) {
      console.error('Failed to load blacklisted tokens:', error);
    }
  }

  static async cleanupExpiredTokens(): Promise<void> {
    try {
      await prisma.$executeRaw`
        DELETE FROM blacklisted_tokens 
        WHERE expires_at <= NOW()
      `;
    } catch (error) {
      console.error('Failed to cleanup expired tokens:', error);
    }
  }
}