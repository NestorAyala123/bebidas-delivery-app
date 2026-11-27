import 'package:flutter/material.dart';

import '../routes/auth_routes.dart';
import '../../../location/presentation/routes/location_routes.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bebidas Delivery'),
        leading: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(Icons.local_bar, color: colors.primary),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    clipBehavior: Clip.antiAlias,
                    padding: EdgeInsets.all(
                      constraints.maxWidth >= 620 ? 36 : 24,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.primary,
                          Color.lerp(colors.primary, colors.tertiary, 0.55)!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: LayoutBuilder(
                      builder: (context, heroConstraints) {
                        final isWide = heroConstraints.maxWidth >= 540;
                        final copy = Column(
                          crossAxisAlignment: isWide
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.center,
                          children: [
                            Text(
                              'BEBIDAS · COMERCIOS · EVENTOS',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colors.onPrimary.withValues(alpha: 0.78),
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: isWide
                                  ? TextAlign.left
                                  : TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Todo para brindar, en un solo lugar.',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.12,
                                color: colors.onPrimary,
                              ),
                              textAlign: isWide
                                  ? TextAlign.left
                                  : TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Encuentra comercios, coordina tu entrega y '
                              'conecta con servicios para tus eventos.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colors.onPrimary.withValues(alpha: 0.86),
                                height: 1.45,
                              ),
                              textAlign: isWide
                                  ? TextAlign.left
                                  : TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              alignment: isWide
                                  ? WrapAlignment.start
                                  : WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colors.surface,
                                    foregroundColor: colors.primary,
                                  ),
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    AuthRoutes.login,
                                  ),
                                  icon: const Icon(Icons.login),
                                  label: const Text('Iniciar Sesión'),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colors.onPrimary,
                                    side: BorderSide(
                                      color: colors.onPrimary.withValues(
                                        alpha: 0.65,
                                      ),
                                    ),
                                  ),
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    AuthRoutes.register,
                                  ),
                                  icon: const Icon(Icons.person_add_alt_1),
                                  label: const Text('Crear cuenta'),
                                ),
                              ],
                            ),
                          ],
                        );

                        final illustration = _HeroIllustration(
                          primary: colors.onPrimary,
                          accent: colors.tertiaryContainer,
                        );

                        return isWide
                            ? Row(
                                children: [
                                  Expanded(flex: 6, child: copy),
                                  const SizedBox(width: 20),
                                  Expanded(flex: 4, child: illustration),
                                ],
                              )
                            : Column(
                                children: [
                                  illustration,
                                  const SizedBox(height: 12),
                                  copy,
                                ],
                              );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Explora la plataforma',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Elige una sección para conocer sus herramientas.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: constraints.maxWidth >= 620 ? 2 : 1,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: constraints.maxWidth >= 620 ? 3.2 : 4.2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _WelcomeShortcut(
                        icon: Icons.storefront_outlined,
                        title: 'Administrar comercios',
                        onTap: () => Navigator.pushNamed(context, '/stores'),
                      ),
                      _WelcomeShortcut(
                        icon: Icons.map_outlined,
                        title: 'Ver mapa de comercios cercanos',
                        onTap: () =>
                            Navigator.pushNamed(context, LocationRoutes.mapa),
                      ),
                      _WelcomeShortcut(
                        icon: Icons.celebration_outlined,
                        title: 'Servicios para Eventos',
                        onTap: () => Navigator.pushNamed(context, '/eventos'),
                      ),
                      _WelcomeShortcut(
                        icon: Icons.forum_outlined,
                        title: 'Chat y avisos',
                        onTap: () => Navigator.pushNamed(context, '/chat'),
                      ),
                      _WelcomeShortcut(
                        icon: Icons.receipt_long_outlined,
                        title: 'Mis pedidos',
                        onTap: () => Navigator.pushNamed(context, '/pedidos'),
                      ),
                      _WelcomeShortcut(
                        icon: Icons.handshake_outlined,
                        title: 'Negociar entrega',
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/entregas/negociacion',
                          arguments: 'req-demo-01',
                        ),
                      ),
                      _WelcomeShortcut(
                        icon: Icons.history_outlined,
                        title: 'Historial de entregas',
                        onTap: () =>
                            Navigator.pushNamed(context, '/entregas/historial'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  final Color primary;
  final Color accent;

  const _HeroIllustration({required this.primary, required this.accent});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 176,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 156,
          height: 156,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withValues(alpha: 0.1),
          ),
        ),
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withValues(alpha: 0.12),
          ),
          child: Icon(Icons.local_bar, size: 66, color: primary),
        ),
        Positioned(
          left: 18,
          bottom: 10,
          child: _HeroBadge(icon: Icons.storefront, color: accent),
        ),
        Positioned(
          right: 12,
          top: 16,
          child: _HeroBadge(icon: Icons.delivery_dining, color: accent),
        ),
        Positioned(
          right: 25,
          bottom: 12,
          child: _HeroBadge(icon: Icons.celebration, color: accent),
        ),
      ],
    ),
  );
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _HeroBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 23,
    backgroundColor: color,
    foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
    child: Icon(icon, size: 23),
  );
}

class _WelcomeShortcut extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _WelcomeShortcut({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.secondaryContainer,
                foregroundColor: colors.onSecondaryContainer,
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: colors.outline),
            ],
          ),
        ),
      ),
    );
  }
}
