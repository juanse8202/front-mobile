import 'package:flutter/material.dart';
import '../services/pago_service.dart';

class PagarConStripe extends StatefulWidget {
  final int ordenTrabajoId;
  final double monto;
  final String ordenNumero;
  final Function(Map<String, dynamic>)? onSuccess;
  final VoidCallback? onCancel;
  final String? token;

  const PagarConStripe({
    super.key,
    required this.ordenTrabajoId,
    required this.monto,
    required this.ordenNumero,
    this.onSuccess,
    this.onCancel,
    this.token,
  });

  @override
  State<PagarConStripe> createState() => _PagarConStripeState();
}

class _PagarConStripeState extends State<PagarConStripe> {
  final PagoService _pagoService = PagoService();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvcController = TextEditingController();
  
  // FocusNodes para controlar el salto entre campos
  final _cardNumberFocus = FocusNode();
  final _expiryDateFocus = FocusNode();
  final _cvcFocus = FocusNode();
  
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _verificando = false;
  bool _pagoExitoso = false;
  String? _error;
  String? _clientSecret;
  String? _paymentIntentId;
  int? _pagoId;
  bool _cardNumberValid = false;
  bool _expiryDateValid = false;
  bool _cvcValid = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvcController.dispose();
    _cardNumberFocus.dispose();
    _expiryDateFocus.dispose();
    _cvcFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _crearPaymentIntent();
  }

  Future<void> _crearPaymentIntent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('💳 Creando Payment Intent para orden: ${widget.ordenTrabajoId}');

      final result = await _pagoService.iniciarPagoStripe(
        widget.ordenTrabajoId,
        token: widget.token,
      );

      if (result['success']) {
        final data = result['data'];
        setState(() {
          _clientSecret = data['client_secret'];
          _paymentIntentId = data['payment_intent_id'];
          _pagoId = data['pago_id'];
          _isLoading = false;
        });

        debugPrint('✅ Payment Intent creado: $_paymentIntentId');
      } else {
        throw Exception(result['message'] ?? 'Error al crear payment intent');
      }
    } catch (e) {
      debugPrint('❌ Error al crear Payment Intent: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Validar número de tarjeta usando algoritmo de Luhn
  bool _validarNumeroTarjeta(String numero) {
    final cleanNumber = numero.replaceAll(' ', '');
    if (cleanNumber.length < 13 || cleanNumber.length > 19) return false;
    
    int sum = 0;
    bool alternate = false;
    
    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return sum % 10 == 0;
  }

  // Validar fecha de expiración
  bool _validarFechaExpiracion(String fecha) {
    if (fecha.length < 5) return false;
    
    final parts = fecha.split('/').map((e) => e.trim()).toList();
    if (parts.length != 2) return false;
    
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    
    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;
    
    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;
    
    if (year < currentYear) return false;
    if (year == currentYear && month < currentMonth) return false;
    
    return true;
  }

  // Validar CVC
  bool _validarCVC(String cvc) {
    return cvc.length >= 3 && cvc.length <= 4 && int.tryParse(cvc) != null;
  }

  Future<void> _procesarPago() async {
    if (_clientSecret == null || _paymentIntentId == null) return;

    // Validar todos los campos
    final cardNumber = _cardNumberController.text.replaceAll(' ', '');
    final expiryDate = _expiryDateController.text;
    final cvc = _cvcController.text;

    if (!_validarNumeroTarjeta(cardNumber)) {
      setState(() {
        _error = 'Número de tarjeta inválido';
      });
      return;
    }

    if (!_validarFechaExpiracion(expiryDate)) {
      setState(() {
        _error = 'Fecha de expiración inválida';
      });
      return;
    }

    if (!_validarCVC(cvc)) {
      setState(() {
        _error = 'CVC inválido (debe ser 3 o 4 dígitos)';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      debugPrint('💳 Procesando pago con Stripe...');
      debugPrint('   Tarjeta: ${cardNumber.substring(0, 4)} **** **** ${cardNumber.substring(cardNumber.length - 4)}');

      // Extraer mes y año de la fecha
      final parts = expiryDate.split('/').map((e) => e.trim()).toList();
      final expMonth = parts[0];
      final expYear = parts[1];

      // Enviar datos de tarjeta al backend para procesarla con Stripe
      final confirmResult = await _pagoService.confirmarPagoStripeConTarjeta(
        _paymentIntentId!,
        cardNumber: cardNumber,
        expMonth: expMonth,
        expYear: expYear,
        cvc: cvc,
        token: widget.token,
      );

      if (confirmResult['success']) {
        debugPrint('✅ Pago confirmado por Stripe');
        
        // Verificar el pago en el backend
        await _verificarPago();
      } else {
        throw Exception(confirmResult['message'] ?? 'Error al confirmar el pago');
      }
    } catch (e) {
      debugPrint('❌ Error al procesar pago: $e');
      setState(() {
        _error = 'Error al procesar el pago: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  Future<void> _verificarPago() async {
    if (_paymentIntentId == null) return;

    setState(() {
      _verificando = true;
    });

    try {
      debugPrint('🔍 Verificando pago en el servidor: $_paymentIntentId');

      final result = await _pagoService.verificarPagoStripe(
        _paymentIntentId!,
        token: widget.token,
      );

      if (result['success'] && result['data']['status'] == 'succeeded') {
        setState(() {
          _pagoExitoso = true;
          _isProcessing = false;
          _verificando = false;
        });

        // Esperar 1.5 segundos y llamar al callback de éxito
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (widget.onSuccess != null) {
          widget.onSuccess!({
            'pago_id': result['data']['pago']['id'],
            'orden_trabajo_id': widget.ordenTrabajoId,
            'payment_intent_id': _paymentIntentId,
          });
        }
      } else {
        throw Exception('El pago no pudo ser verificado');
      }
    } catch (e) {
      debugPrint('❌ Error al verificar pago: $e');
      setState(() {
        _error = 'El pago fue procesado pero no se pudo confirmar: ${e.toString()}';
        _verificando = false;
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Estado de carga inicial
    if (_isLoading && _clientSecret == null) {
      return _buildLoadingState('Preparando sistema de pago...');
    }

    // Estado de error
    if (_error != null && _clientSecret == null) {
      return _buildErrorState();
    }

    // Estado de pago exitoso
    if (_pagoExitoso) {
      return _buildSuccessState();
    }

    // Estado verificando pago
    if (_verificando) {
      return _buildLoadingState('Verificando pago...');
    }

    // Formulario de pago
    return _buildPaymentForm();
  }

  Widget _buildLoadingState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Error al Inicializar Pago',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Error desconocido',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _crearPaymentIntent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reintentar'),
              ),
              if (widget.onCancel != null) ...[
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancelar'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          const Text(
            '¡Pago Exitoso!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tu pago ha sido procesado correctamente.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                Text(
                  'ID de Pago: $_pagoId',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Orden: ${widget.ordenNumero}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.credit_card, color: Colors.deepPurple, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Realizar Pago',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.lock, color: Colors.green, size: 18),
                const SizedBox(width: 4),
                const Text(
                  'Seguro',
                  style: TextStyle(color: Colors.green, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Resumen de pago
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Orden:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Flexible(
                        child: Text(
                          widget.ordenNumero,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total a pagar:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Flexible(
                        child: Text(
                          'Bs. ${widget.monto.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

          // Título del campo
          const Text(
            'Tarjeta de Crédito o Débito',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Campo de número de tarjeta completo
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _cardNumberValid ? Colors.green : Colors.grey.shade300,
                width: _cardNumberValid ? 2 : 1,
              ),
            ),
            child: TextField(
              controller: _cardNumberController,
              focusNode: _cardNumberFocus,
              decoration: InputDecoration(
                hintText: '4242 4242 4242 4242',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.credit_card, color: Colors.grey),
                suffixIcon: _cardNumberValid 
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                counterText: '',
              ),
              keyboardType: TextInputType.number,
              maxLength: 19, // 16 dígitos + 3 espacios
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
              onChanged: (value) {
                // Formatear automáticamente con espacios cada 4 dígitos
                String formatted = value.replaceAll(' ', '');
                if (formatted.length > 16) {
                  formatted = formatted.substring(0, 16);
                }
                
                String newValue = '';
                for (int i = 0; i < formatted.length; i++) {
                  if (i > 0 && i % 4 == 0) {
                    newValue += ' ';
                  }
                  newValue += formatted[i];
                }
                
                if (newValue != value) {
                  _cardNumberController.value = TextEditingValue(
                    text: newValue,
                    selection: TextSelection.collapsed(offset: newValue.length),
                  );
                }
                
                setState(() {
                  _cardNumberValid = _validarNumeroTarjeta(newValue);
                  
                  // Saltar al siguiente campo si el número está completo (16 dígitos)
                  if (formatted.length == 16) {
                    FocusScope.of(context).requestFocus(_expiryDateFocus);
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 12),

          // Fila para fecha de expiración y CVC
          Row(
            children: [
              // Campo de fecha de expiración (MM/AA)
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _expiryDateValid ? Colors.green : Colors.grey.shade300,
                      width: _expiryDateValid ? 2 : 1,
                    ),
                  ),
                  child: TextField(
                    controller: _expiryDateController,
                    focusNode: _expiryDateFocus,
                    decoration: InputDecoration(
                      hintText: '04 / 26',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      suffixIcon: _expiryDateValid 
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      counterText: '',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 7, // MM / AA
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                    onChanged: (value) {
                      // Formatear automáticamente MM / AA
                      String formatted = value.replaceAll('/', '').replaceAll(' ', '');
                      if (formatted.length > 4) {
                        formatted = formatted.substring(0, 4);
                      }
                      
                      String newValue = formatted;
                      if (formatted.length >= 2) {
                        newValue = '${formatted.substring(0, 2)} / ${formatted.substring(2)}';
                      }
                      
                      if (newValue != value) {
                        _expiryDateController.value = TextEditingValue(
                          text: newValue,
                          selection: TextSelection.collapsed(offset: newValue.length),
                        );
                      }
                      
                      setState(() {
                        _expiryDateValid = _validarFechaExpiracion(newValue);
                        
                        // Saltar al CVC cuando se completen los 4 dígitos (MM/AA)
                        if (formatted.length == 4) {
                          FocusScope.of(context).requestFocus(_cvcFocus);
                        }
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Campo CVC
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _cvcValid ? Colors.green : Colors.grey.shade300,
                      width: _cvcValid ? 2 : 1,
                    ),
                  ),
                  child: TextField(
                    controller: _cvcController,
                    focusNode: _cvcFocus,
                    decoration: InputDecoration(
                      hintText: '123',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      suffixIcon: _cvcValid 
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      counterText: '',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true, // Ocultar CVC por seguridad
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _cvcValid = _validarCVC(value);
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Botón de pago
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isProcessing || _clientSecret == null ? null : _procesarPago,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isProcessing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Procesando pago...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.credit_card),
                        const SizedBox(width: 8),
                        Text('Pagar Bs. ${widget.monto.toStringAsFixed(2)}'),
                      ],
                    ),
            ),
          ),

          // Botón cancelar
          if (widget.onCancel != null) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _isProcessing ? null : widget.onCancel,
                child: const Text('Cancelar y volver'),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}
