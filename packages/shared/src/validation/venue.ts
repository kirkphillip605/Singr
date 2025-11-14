import { z } from 'zod';

export const createVenueSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  urlName: z
    .string()
    .min(2, 'URL name must be at least 2 characters')
    .regex(
      /^[a-z0-9-]+$/,
      'URL name must contain only lowercase letters, numbers, and hyphens'
    ),
  description: z.string().optional(),
  address: z.string().optional(),
  city: z.string().optional(),
  state: z.string().optional(),
  postalCode: z.string().optional(),
  country: z.string().default('US'),
  phone: z.string().optional(),
  website: z.string().url('Invalid URL').optional().or(z.literal('')),
  timezone: z.string().default('UTC'),
  latitude: z.number().min(-90).max(90).optional(),
  longitude: z.number().min(-180).max(180).optional(),
  isActive: z.boolean().default(true),
  settings: z.record(z.any()).optional(),
  metadata: z.record(z.any()).optional(),
});

export const updateVenueSchema = createVenueSchema.partial();

export const venueQuerySchema = z.object({
  search: z.string().optional(),
  city: z.string().optional(),
  state: z.string().optional(),
  isActive: z.boolean().optional(),
  page: z.coerce.number().min(1).default(1),
  limit: z.coerce.number().min(1).max(100).default(20),
  sortBy: z.enum(['name', 'createdAt', 'updatedAt']).default('name'),
  sortOrder: z.enum(['asc', 'desc']).default('asc'),
});

export type CreateVenueInput = z.infer<typeof createVenueSchema>;
export type UpdateVenueInput = z.infer<typeof updateVenueSchema>;
export type VenueQueryInput = z.infer<typeof venueQuerySchema>;
