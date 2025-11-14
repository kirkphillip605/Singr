import jwt from 'jsonwebtoken';
import { config } from '@singr/config';

export interface JWTPayload {
  userId: string;
  email: string;
  roles: string[];
  type: 'access' | 'refresh';
}

/**
 * Generate an access token
 */
export function generateAccessToken(payload: Omit<JWTPayload, 'type'>): string {
  return jwt.sign(
    { ...payload, type: 'access' },
    config.JWT_PRIVATE_KEY,
    {
      algorithm: 'ES256',
      expiresIn: config.JWT_ACCESS_TTL,
      issuer: config.JWT_ISSUER,
      audience: config.JWT_AUDIENCE,
    }
  );
}

/**
 * Generate a refresh token
 */
export function generateRefreshToken(payload: Omit<JWTPayload, 'type'>): string {
  return jwt.sign(
    { ...payload, type: 'refresh' },
    config.JWT_PRIVATE_KEY,
    {
      algorithm: 'ES256',
      expiresIn: config.JWT_REFRESH_TTL,
      issuer: config.JWT_ISSUER,
      audience: config.JWT_AUDIENCE,
    }
  );
}

/**
 * Verify and decode a JWT token
 */
export function verifyToken(token: string): JWTPayload {
  try {
    const decoded = jwt.verify(token, config.JWT_PUBLIC_KEY, {
      algorithms: ['ES256'],
      issuer: config.JWT_ISSUER,
      audience: config.JWT_AUDIENCE,
    });
    return decoded as JWTPayload;
  } catch (error) {
    throw new Error('Invalid token');
  }
}

/**
 * Decode a token without verifying (for debugging)
 */
export function decodeToken(token: string): JWTPayload | null {
  try {
    const decoded = jwt.decode(token);
    return decoded as JWTPayload;
  } catch (error) {
    return null;
  }
}
