import { PrismaClient, Session } from "@prisma/client";

export default interface SessionRepository {
  create(params: {
    userId: number;
    refreshHash: string;
    userAgent?: string;
    ip?: string;
    expiresAt: Date;
  }): Promise<Session>;

  findById(id: string): Promise<Session | null>;
  findValidByUser(userId: number): Promise<Session[]>;
  revokeById(id: string): Promise<void>;
  revokeAllByUser(userId: number): Promise<void>;
  findByHash(refreshHash: string): Promise<Session | null>;
}


