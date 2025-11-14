import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
async function main() {
    console.log('Seeding database...');
    // Create system roles
    const adminRole = await prisma.role.upsert({
        where: { slug: 'admin' },
        update: {},
        create: {
            slug: 'admin',
            description: 'Platform administrator',
            isSystem: true,
        },
    });
    const customerRole = await prisma.role.upsert({
        where: { slug: 'customer' },
        update: {},
        create: {
            slug: 'customer',
            description: 'Venue owner/manager',
            isSystem: true,
        },
    });
    const singerRole = await prisma.role.upsert({
        where: { slug: 'singer' },
        update: {},
        create: {
            slug: 'singer',
            description: 'Singer user',
            isSystem: true,
        },
    });
    // Create permissions
    const permissions = [
        { slug: 'venues:read', description: 'View venues' },
        { slug: 'venues:write', description: 'Create/update venues' },
        { slug: 'venues:delete', description: 'Delete venues' },
        { slug: 'systems:read', description: 'View systems' },
        { slug: 'systems:write', description: 'Create/update systems' },
        { slug: 'systems:delete', description: 'Delete systems' },
        { slug: 'songdb:read', description: 'View song database' },
        { slug: 'songdb:write', description: 'Create/update songs' },
        { slug: 'songdb:delete', description: 'Delete songs' },
        { slug: 'requests:read', description: 'View requests' },
        { slug: 'requests:write', description: 'Create/update requests' },
        { slug: 'requests:delete', description: 'Delete requests' },
        { slug: 'api-keys:read', description: 'View API keys' },
        { slug: 'api-keys:write', description: 'Create/update API keys' },
        { slug: 'api-keys:delete', description: 'Delete API keys' },
        { slug: 'org:read', description: 'View organization' },
        { slug: 'org:write', description: 'Manage organization' },
        { slug: 'billing:read', description: 'View billing' },
        { slug: 'billing:write', description: 'Manage billing' },
    ];
    for (const permission of permissions) {
        await prisma.permission.upsert({
            where: { slug: permission.slug },
            update: {},
            create: permission,
        });
    }
    console.log('Seeding completed successfully!');
    console.log({
        roles: { adminRole, customerRole, singerRole },
        permissionsCount: permissions.length,
    });
}
main()
    .catch((e) => {
    console.error('Seeding error:', e);
    process.exit(1);
})
    .finally(async () => {
    await prisma.$disconnect();
});
//# sourceMappingURL=seed.js.map