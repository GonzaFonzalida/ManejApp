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

      if (!mounted) return;

      final data = pref['data'] as Map<String, dynamic>? ?? pref;
      _preferenceId = (data['preferenceId'] ?? data['id'])?.toString();
      _initPoint = (data['initPoint'] ?? data['sandboxInitPoint'] ?? data['init_point'])?.toString();

      setState(() {
        _statusMessage = 'Preferencia creada';
      });

      if (_initPoint != null && _initPoint!.isNotEmpty) {
        final url = Uri.parse(_initPoint!);
        final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
        if (mounted) {
          setState(() {
            _statusMessage = launched ? 'Checkout abierto en Mercado Pago' : 'No se pudo abrir Mercado Pago';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _statusMessage = 'Error: No se recibió URL de pago';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear pago: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
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
        backgroundColor: const Color(0xFF003087),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detalle del pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Clase:', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text('#${widget.drivingClassId}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monto:', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text('\$${widget.amount}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF003087))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(widget.description, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
            if (_preferenceId != null) ...[
              const SizedBox(height: 12),
              Text('ID: $_preferenceId', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
            const Spacer(),
            if (_loading)
              const CircularProgressIndicator()
            else ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _createPreferenceAndOpen,
                  icon: const Icon(Icons.payment),
                  label: const Text('Pagar con Mercado Pago'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003087),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _checkStatus,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Consultar estado'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF003087),
                    side: const BorderSide(color: Color(0xFF003087)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
