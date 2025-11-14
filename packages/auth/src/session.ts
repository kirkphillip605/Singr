import { config } from '@singr/config';
import Redis from 'ioredis';
import { v4 as uuidv4 } from 'uuid';

export interface SessionData {
  userId: string;
  email: string;
  roles: string[];
  createdAt: number;
  expiresAt: number;
}

/**
 * Session manager using Redis
 */
export class SessionManager {
  private redis: Redis;
  private readonly SESSION_PREFIX = 'session:';
  private readonly DEFAULT_TTL = 7 * 24 * 60 * 60; // 7 days

  constructor(redisUrl?: string) {
    this.redis = new Redis(redisUrl || config.REDIS_URL);
  }

  /**
   * Create a new session
   */
  async createSession(data: Omit<SessionData, 'createdAt' | 'expiresAt'>): Promise<string> {
    const sessionToken = uuidv4();
    const now = Date.now();
    const expiresAt = now + this.DEFAULT_TTL * 1000;

    const sessionData: SessionData = {
      ...data,
      createdAt: now,
      expiresAt,
    };

    await this.redis.setex(
      `${this.SESSION_PREFIX}${sessionToken}`,
      this.DEFAULT_TTL,
      JSON.stringify(sessionData)
    );

    return sessionToken;
  }

  /**
   * Get session data
   */
  async getSession(sessionToken: string): Promise<SessionData | null> {
    const data = await this.redis.get(`${this.SESSION_PREFIX}${sessionToken}`);
    if (!data) {
      return null;
    }

    const sessionData: SessionData = JSON.parse(data);
    
    // Check if session is expired
    if (sessionData.expiresAt < Date.now()) {
      await this.deleteSession(sessionToken);
      return null;
    }

    return sessionData;
  }

  /**
   * Update session data
   */
  async updateSession(sessionToken: string, data: Partial<SessionData>): Promise<boolean> {
    const existingData = await this.getSession(sessionToken);
    if (!existingData) {
      return false;
    }

    const updatedData = { ...existingData, ...data };
    const ttl = await this.redis.ttl(`${this.SESSION_PREFIX}${sessionToken}`);

    await this.redis.setex(
      `${this.SESSION_PREFIX}${sessionToken}`,
      ttl > 0 ? ttl : this.DEFAULT_TTL,
      JSON.stringify(updatedData)
    );

    return true;
  }

  /**
   * Delete a session
   */
  async deleteSession(sessionToken: string): Promise<boolean> {
    const result = await this.redis.del(`${this.SESSION_PREFIX}${sessionToken}`);
    return result > 0;
  }

  /**
   * Delete all sessions for a user
   */
  async deleteUserSessions(userId: string): Promise<number> {
    const keys = await this.redis.keys(`${this.SESSION_PREFIX}*`);
    let deletedCount = 0;

    for (const key of keys) {
      const data = await this.redis.get(key);
      if (data) {
        const sessionData: SessionData = JSON.parse(data);
        if (sessionData.userId === userId) {
          await this.redis.del(key);
          deletedCount++;
        }
      }
    }

    return deletedCount;
  }

  /**
   * Extend session TTL
   */
  async extendSession(sessionToken: string, additionalSeconds: number): Promise<boolean> {
    const exists = await this.redis.exists(`${this.SESSION_PREFIX}${sessionToken}`);
    if (!exists) {
      return false;
    }

    const currentTTL = await this.redis.ttl(`${this.SESSION_PREFIX}${sessionToken}`);
    await this.redis.expire(
      `${this.SESSION_PREFIX}${sessionToken}`,
      currentTTL + additionalSeconds
    );

    return true;
  }

  /**
   * Close Redis connection
   */
  async disconnect(): Promise<void> {
    await this.redis.quit();
  }
}

// Export singleton instance
export const sessionManager = new SessionManager();
