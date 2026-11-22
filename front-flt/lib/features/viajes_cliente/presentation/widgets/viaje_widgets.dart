import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/ui/formatos.dart';
import '../../../../core/ui/gav_widgets.dart';
import '../../domain/entities/estado_viaje.dart';
import '../../domain/entities/viaje.dart';

final _fecha = DateFormat('dd/MM/yyyy HH:mm');

String formatearFecha(DateTime? d) => d == null ? '—' : _fecha.format(d);
String formatearPrecio(double? p) => Fmt.pesos(p);

class EstadoViajeChip extends StatelessWidget {
  const EstadoViajeChip(this.estado, {super.key});
  final EstadoViaje estado;

  @override
  Widget build(BuildContext context) {
    final (texto, kind) = switch (estado) {
      EstadoViaje.finalizado => ('Finalizado', GavChipKind.success),
      EstadoViaje.cancelado => ('Cancelado', GavChipKind.danger),
      EstadoViaje.solicitado || EstadoViaje.buscandoConductor => ('Buscando', GavChipKind.neutral),
      EstadoViaje.aceptado => ('Aceptado', GavChipKind.warm),
      EstadoViaje.enCamino => ('En camino', GavChipKind.gold),
      EstadoViaje.enCurso => ('En curso', GavChipKind.gold),
      EstadoViaje.desconocido => ('—', GavChipKind.neutral),
    };
    return GavChip(texto, kind: kind);
  }
}

class ViajeTile extends StatelessWidget {
  const ViajeTile({super.key, required this.viaje, this.onTap});
  final Viaje viaje;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.route)),
        title: Text('Viaje #${viaje.id} · ${formatearPrecio(viaje.precio)}'),
        subtitle: Text(
          '${formatearFecha(viaje.solicitadoEn)}\n'
          'Conductor: ${viaje.tieneConductor ? viaje.conductorNombre : 'sin asignar'}',
        ),
        isThreeLine: true,
        trailing: EstadoViajeChip(viaje.estado),
      );
}
