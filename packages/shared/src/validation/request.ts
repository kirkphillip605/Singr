import { z } from 'zod';

export const createRequestSchema = z.object({
  venueId: z.string().uuid('Invalid venue ID'),
  systemId: z.string().uuid('Invalid system ID'),
  singerName: z.string().min(1, 'Singer name is required'),
  artist: z.string().min(1, 'Artist is required'),
  title: z.string().min(1, 'Title is required'),
  keyChange: z.number().int().min(-12).max(12).default(0),
  notes: z.string().max(500).optional(),
});

export const updateRequestSchema = z.object({
  status: z.enum(['pending', 'approved', 'rejected', 'completed', 'canceled']).optional(),
  priority: z.number().int().min(0).max(10).optional(),
  position: z.number().int().min(0).optional(),
  notes: z.string().max(500).optional(),
});

export const requestQuerySchema = z.object({
  venueId: z.string().uuid().optional(),
  systemId: z.string().uuid().optional(),
  singerProfileId: z.string().uuid().optional(),
  status: z.enum(['pending', 'approved', 'rejected', 'completed', 'canceled']).optional(),
  search: z.string().optional(),
  page: z.coerce.number().min(1).default(1),
  limit: z.coerce.number().min(1).max(100).default(50),
  sortBy: z.enum(['requestedAt', 'position', 'priority']).default('position'),
  sortOrder: z.enum(['asc', 'desc']).default('asc'),
});

export type CreateRequestInput = z.infer<typeof createRequestSchema>;
export type UpdateRequestInput = z.infer<typeof updateRequestSchema>;
export type RequestQueryInput = z.infer<typeof requestQuerySchema>;
