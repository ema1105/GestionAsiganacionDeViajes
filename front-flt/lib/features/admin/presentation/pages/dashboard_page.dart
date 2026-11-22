import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/gav_colors.dart';
import '../../../../core/theme/gav_theme.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../admin_providers.dart';
import '../embed/dashboard_embed.dart';

/// Mockup admin 10 · Dashboard BI (Power BI embebido).
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardUrlProvider);
    final g = context.gav;

    return Scaffold(
      backgroundColor: g.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GavTopBar(
                eyebrow: 'GAV · Admin',
                title: 'Dashboard',
                subtitle: 'Analítica corporativa integrada · Microsoft Power BI',
                onBack: () => context.pop(),
              ),
              GavCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.grid_view_rounded, size: 18, color: g.gold),
                    const SizedBox(width: 10),
                    Expanded(child: Text('GAV Analytics', style: GavText.strong(context, size: 13.5))),
                    GavChip(
                      async.hasValue ? 'Conectado' : (async.hasError ? 'Sin conexión' : 'Conectando'),
                      kind: async.hasValue
                          ? GavChipKind.success
                          : (async.hasError ? GavChipKind.danger : GavChipKind.neutral),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: async.when(
                    data: (url) => url.isEmpty
                        ? const EmptyView(mensaje: 'El backend no devolvió la URL del reporte.')
                        : buildDashboardEmbed(url),
                    loading: () => const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.insert_chart_outlined, color: Color(0xFF8A867F)),
                          SizedBox(height: 8),
                          Text(
                            'Cargando informe analítico…',
                            style: TextStyle(color: Color(0xFF8A867F), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    error: (e, _) => ErrorView(
                      message: 'No se pudo cargar el dashboard.',
                      onRetry: () => ref.invalidate(dashboardUrlProvider),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GavButton(
                label: 'Abrir en Power BI  ↗',
                kind: GavButtonKind.ghost,
                expand: true,
                height: 48,
                onPressed: async.value == null || async.value!.isEmpty
                    ? null
                    : () => launchUrl(Uri.parse(async.value!), mode: LaunchMode.externalApplication),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
