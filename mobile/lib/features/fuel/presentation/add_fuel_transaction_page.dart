import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/presentation/widgets/login_background.dart';
import '../../my_vehicles/presentation/widgets/vehicle_form_card.dart';
import '../../my_vehicles/presentation/widgets/vehicle_form_section_title.dart';
import '../../../shared/widgets/form/app_form_theme.dart';
import '../../../shared/widgets/form/app_text_field.dart';
import '../../../shared/widgets/form/gradient_button.dart';
import '../../my_vehicles/presentation/my_vehicles_providers.dart';
import '../data/fuel_api.dart';
import '../data/models/fuel_api_dtos.dart';
import '../data/models/fuel_tracking_models.dart';
import '../../pricing/data/models/latest_fuel_prices_response.dart';
import 'fuel_providers.dart';

/// Form thêm / sửa lần đổ xăng / dầu — `POST` hoặc `PUT /api/fuel/transactions/{id}`.
///
/// Số tiền + công tơ mét: nhóm 3 chữ số (dấu `.`). Số lít ước tính theo giá tham chiếu từ `GET /api/prices/latest`.
class AddFuelTransactionPage extends ConsumerStatefulWidget {
  const AddFuelTransactionPage({
    super.key,
    required this.vehicleId,
    this.editTransactionId,
    this.editPrefill,
  });

  final int vehicleId;
  final int? editTransactionId;
  final FuelTransactionEditPrefill? editPrefill;

  bool get isEditMode => editTransactionId != null && editTransactionId! > 0;

  @override
  ConsumerState<AddFuelTransactionPage> createState() => _AddFuelTransactionPageState();
}

/// Định dạng số nguyên kiểu VN: 1.500.000
String _formatGroupedInt(int n) {
  final neg = n < 0;
  final s = (neg ? -n : n).toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) {
      buf.write('.');
    }
    buf.write(s[i]);
  }
  return neg ? '-$buf' : buf.toString();
}

int? _parseDigitsToInt(String text) {
  final d = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.isEmpty) {
    return null;
  }
  return int.tryParse(d);
}

double _referencePricePerLiter(LatestFuelPricesResponse? data) {
  const fallback = 24240.0;
  if (data == null || data.items.isEmpty) {
    return fallback;
  }
  final vals = data.items.map((e) => e.so01).whereType<double>().where((x) => x > 1000 && x < 200000).toList();
  if (vals.isEmpty) {
    return fallback;
  }
  return vals.reduce((a, b) => a + b) / vals.length;
}

class _ThousandsIntInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final d = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }
    final n = int.tryParse(d);
    if (n == null) {
      return oldValue;
    }
    final f = _formatGroupedInt(n);
    return TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}

class _AddFuelTransactionPageState extends ConsumerState<AddFuelTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _odometer = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  bool _submitting = false;

  static const _quickAmounts = <int>[500000, 1000000, 1500000];

  @override
  void initState() {
    super.initState();
    final p = widget.editPrefill;
    if (p != null) {
      _amount.text = _formatGroupedInt(p.amountDong);
      final o = p.odometerKm;
      if (o != null) {
        _odometer.text = _formatGroupedInt(o.round());
      }
      final n = p.note;
      if (n != null && n.isNotEmpty) {
        _note.text = n;
      }
      _date = p.transactionDate;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _odometer.dispose();
    _note.dispose();
    super.dispose();
  }

  void _applyAmount(int dong) {
    _amount.text = _formatGroupedInt(dong);
    _amount.selection = TextSelection.collapsed(offset: _amount.text.length);
    setState(() {});
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  double? _computedLiters(int amountDong, double pricePerLiter) {
    if (amountDong <= 0 || pricePerLiter <= 0) {
      return null;
    }
    final raw = amountDong / pricePerLiter;
    return double.parse(raw.toStringAsFixed(3));
  }

  Future<void> _submit(double refPrice) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final amountDong = _parseDigitsToInt(_amount.text) ?? 0;
    if (amountDong <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập số tiền hợp lệ.')));
      return;
    }
    final liters = _computedLiters(amountDong, refPrice);
    if (liters == null || liters <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tính được số lít. Kiểm tra giá tham chiếu.')));
      return;
    }
    final odometerInt = _parseDigitsToInt(_odometer.text);
    final odometer = odometerInt?.toDouble();

    setState(() => _submitting = true);
    try {
      final api = ref.read(fuelApiProvider);
      final noteTrim = _note.text.trim();
      final body = <String, dynamic>{
        'vehicleId': widget.vehicleId,
        'amount': amountDong.toDouble(),
        'liters': liters,
        'transactionDate': _date.toIso8601String(),
      };
      if (odometer != null) {
        body['odometer'] = odometer;
      }
      if (noteTrim.isNotEmpty) {
        body['note'] = noteTrim;
      }

      final CreateFuelTransactionResultDto res;
      if (widget.isEditMode) {
        res = await api.updateFuelTransaction(widget.editTransactionId!, body);
      } else {
        res = await api.createFuelTransaction(body);
      }

      if (!mounted) {
        return;
      }
      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message.isEmpty ? 'Đã lưu.' : res.message)));
        context.pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.message.isEmpty ? 'Không thể lưu.' : res.message)));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  PreferredSizeWidget _appBar(BuildContext context) {
    return AppBar(
      title: Text(widget.isEditMode ? 'Sửa đổ nhiên liệu' : 'Đổ nhiên liệu'),
      backgroundColor: Colors.white.withValues(alpha: 0.96),
      foregroundColor: AppFormTheme.labelColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    );
  }

  Widget _errorBody(String message) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _appBar(context),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LoginBackground(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: VehicleFormCard(
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppFormTheme.hintColor,
                        height: 1.4,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.vehicleId < 1) {
      return _errorBody('Thiếu thông tin xe. Vui lòng quay lại.');
    }

    if (widget.isEditMode) {
      final p = widget.editPrefill;
      if (p == null || p.transactionId != widget.editTransactionId) {
        return _errorBody('Thiếu dữ liệu giao dịch. Hãy chọn Sửa từ màn Lịch sử đổ xăng.');
      }
    }

    final pricesAsync = ref.watch(latestFuelPricesProvider);
    final refPrice = pricesAsync.when(
      data: (d) => _referencePricePerLiter(d),
      loading: () => 24240.0,
      error: (_, _) => 24240.0,
    );

    final amountDong = _parseDigitsToInt(_amount.text) ?? 0;
    final liters = _computedLiters(amountDong, refPrice);
    final litersLabel = liters != null ? NumberFormat.decimalPattern('vi_VN').format(liters) : '—';

    final vehiclesAsync = ref.watch(myVehiclesListProvider);
    final vehicleLabel = vehiclesAsync.maybeWhen(
      data: (data) {
        for (final v in data.items) {
          if (v.id == widget.vehicleId) {
            final name = v.vehicleName?.trim();
            if (name != null && name.isNotEmpty) {
              return name;
            }
            final plate = v.licensePlate.trim();
            if (plate.isNotEmpty) {
              return plate;
            }
            break;
          }
        }
        return 'Xe #${widget.vehicleId}';
      },
      orElse: () => 'Xe #${widget.vehicleId}',
    );

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _appBar(context),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LoginBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 10, 16, 20 + bottomInset),
              child: VehicleFormCard(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                     
                      Row(
                        children: [
                          Icon(Icons.directions_car_rounded, size: 22, color: AppFormTheme.focusBorder),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              vehicleLabel,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppFormTheme.labelColor,
                                  ),
                            ),
                          ),
                        ],
                      ),
                     
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Số tiền (đ) *',
                        hint: 'Ví dụ: 500.000',
                        prefixIcon: Icons.payments_outlined,
                        controller: _amount,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [_ThousandsIntInputFormatter()],
                        enabled: !_submitting,
                        onChanged: (_) {
                          setState(() {});
                        },
                        validator: (s) {
                          if (s == null || s.trim().isEmpty) {
                            return 'Nhập số tiền';
                          }
                          if ((_parseDigitsToInt(s) ?? 0) <= 0) {
                            return 'Số tiền phải lớn hơn 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Gợi ý nhanh',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppFormTheme.hintColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final a in _quickAmounts)
                            ActionChip(
                              label: Text(_formatGroupedInt(a)),
                              onPressed: _submitting ? null : () => _applyAmount(a),
                              side: const BorderSide(color: AppFormTheme.border),
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const VehicleFormSectionTitle(title: 'Ước tính'),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppFormTheme.fieldRadius),
                          border: Border.all(color: AppFormTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.local_gas_station_outlined, size: 20, color: AppFormTheme.focusBorder),
                                const SizedBox(width: 8),
                                Text(
                                  'Số lít (ước tính)',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppFormTheme.labelColor,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$litersLabel lít',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppFormTheme.focusBorder,
                                  ),
                            ),
                           
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const VehicleFormSectionTitle(title: 'Thông tin bổ sung'),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Số công tơ mét (km)',
                        hint: 'Ví dụ: 35.000',
                        prefixIcon: Icons.speed_rounded,
                        controller: _odometer,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [_ThousandsIntInputFormatter()],
                        enabled: !_submitting,
                      ),
                      const SizedBox(height: 18),
                      AppTextField(
                        label: 'Ghi chú',
                        hint: 'Tuỳ chọn',
                        prefixIcon: Icons.notes_outlined,
                        controller: _note,
                        maxLines: 2,
                        maxLength: 500,
                        textInputAction: TextInputAction.newline,
                        enabled: !_submitting,
                      ),
                      const SizedBox(height: 18),
                      _FuelDateField(
                        date: _date,
                        enabled: !_submitting,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 28),
                      GradientButton(
                        label: widget.isEditMode ? 'Cập nhật' : 'Lưu',
                        loading: _submitting,
                        loadingLabel: 'Đang lưu…',
                        onPressed: _submitting ? null : () => _submit(refPrice),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FuelDateField extends StatelessWidget {
  const _FuelDateField({
    required this.date,
    required this.enabled,
    required this.onTap,
  });

  final DateTime date;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 20, color: AppFormTheme.focusBorder),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ngày giao dịch',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppFormTheme.labelColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppFormTheme.fieldRadius),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppFormTheme.fieldRadius),
                border: Border.all(color: AppFormTheme.border),
              ),
              child: Padding(
                padding: AppFormTheme.fieldPadding,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(date),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppFormTheme.labelColor,
                            ),
                      ),
                    ),
                    Text(
                      'Chọn',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: enabled ? AppFormTheme.focusBorder : AppFormTheme.hintColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
