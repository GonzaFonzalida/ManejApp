import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:manejapp/services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  static const routeName = '/payment';

  final int drivingClassId;
  final int amount;
  final String description;
  final String? payerEmail;

  const PaymentScreen({
    super.key,
    required this.drivingClassId,
    required this.amount,
    required this.description,
    this.payerEmail,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _loading = false;
  String? _preferenceId;
  String? _initPoint;
  String? _paymentId;
  String _statusMessage = 'Sin iniciar';

  Future<void> _createPreferenceAndOpen() async {
    setState(() {
      _loading = true;
      _statusMessage = 'Creando preferencia...';
    });

    try {
      final pref = await ApiService.mpCreatePreference(
        drivingClassId: widget.drivingClassId,
        amount: widget.amount,
        description: widget.description,
        payerEmail: widget.payerEmail,
      );

      _preferenceId = (pref['preferenceId'] ?? pref['id'])?.toString();
      _initPoint = (pref['initPoint'] ??
              pref['sandboxInitPoint'] ??
              pref['init_point'])
          ?.toString();

      setState(() {
        _statusMessage = 'Preferencia creada';
      });

      if (_initPoint != null) {
        final url = Uri.parse(_initPoint!);
        await launchUrl(url, mode: LaunchMode.externalApplication);
        setState(() {
          _statusMessage = 'Checkout abierto en Mercado Pago';
        });
      } else {
        setState(() {
          _statusMessage = 'No recibí initPoint del backend';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _checkStatus() async {
    if (_paymentId == null && _preferenceId == null) {
      setState(() {
        _statusMessage = 'No tengo paymentId ni preferenceId para consultar.';
      });
      return;
    }
    setState(() {
      _loading = true;
    });
    try {
      final id = _paymentId ?? _preferenceId!;
      final res = await ApiService.mpGetPaymentStatus(id);
      setState(() {
        _statusMessage = 'Estado: ${res['status'] ?? res.toString()}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error consultando estado: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago con Mercado Pago'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: const Text('Clase a pagar'),
              subtitle: Text(
                'Clase #${widget.drivingClassId} • \$${widget.amount}\n${widget.description}',
              ),
            ),
            const SizedBox(height: 16),
            if (_preferenceId != null)
              SelectableText('Preference ID: $_preferenceId'),
            if (_paymentId != null)
              SelectableText('Payment ID: $_paymentId'),
            const SizedBox(height: 8),
            Text(_statusMessage),
            const Spacer(),
            if (_loading) const CircularProgressIndicator(),
            if (!_loading) ...[
              ElevatedButton.icon(
                onPressed: _createPreferenceAndOpen,
                icon: const Icon(Icons.payment),
                label: const Text('Pagar con Mercado Pago'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _checkStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('Consultar estado'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
