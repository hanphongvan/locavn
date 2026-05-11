import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/form/app_dropdown.dart';
import '../../../shared/widgets/form/app_form_theme.dart';
import '../../../shared/widgets/form/app_switch.dart';
import '../../../shared/widgets/form/app_text_field.dart';
import '../../../shared/widgets/form/gradient_button.dart';
import '../../auth/presentation/widgets/login_background.dart';
import '../../fuel/presentation/fuel_tracking_providers.dart';
import '../../store_sale_prices/data/models/store_admin_fuel_product_list_item.dart';
import '../data/models/vehicle_dto.dart';
import '../data/my_vehicles_api.dart';
import 'my_vehicles_fuel_products_provider.dart';
import 'my_vehicles_providers.dart';
import 'widgets/vehicle_form_card.dart';
import 'widgets/vehicle_form_section_title.dart';

/// Bottom sheet: thêm / sửa xe (`POST` / `PUT /api/my-vehicles/{id}`).
Future<bool?> showAddEditVehicleSheet(
  BuildContext context, {
  VehicleDto? existing,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => AddEditVehicleSheet(existing: existing),
  );
}

/// Citizen **Add / Edit vehicle** flow — UI shell matches login/dashboard; logic unchanged.
class AddEditVehicleSheet extends ConsumerStatefulWidget {
  const AddEditVehicleSheet({super.key, this.existing});

  final VehicleDto? existing;

  @override
  ConsumerState<AddEditVehicleSheet> createState() => _AddEditVehicleSheetState();
}

class _AddEditVehicleSheetState extends ConsumerState<AddEditVehicleSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _plate;
  late final TextEditingController _name;
  late final TextEditingController _fuelTypeFallback;
  late final TextEditingController _totalKm;
  late final TextEditingController _year;
  bool _isDefault = false;
  bool _saving = false;
  String? _fuelProductCode;
  bool _fuelDropdownTouched = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _plate = TextEditingController(text: e?.licensePlate ?? '');
    _name = TextEditingController(text: e?.vehicleName ?? '');
    _fuelTypeFallback = TextEditingController(text: e?.fuelType ?? '');
    _totalKm = TextEditingController(text: e?.totalKm?.toString() ?? '');
    _year = TextEditingController(text: e?.year?.toString() ?? '');
    _isDefault = e?.isDefault ?? false;
  }

  @override
  void dispose() {
    _plate.dispose();
    _name.dispose();
    _fuelTypeFallback.dispose();
    _totalKm.dispose();
    _year.dispose();
    super.dispose();
  }

  String? _nullable(String s) {
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  int? _nullableInt(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final fuelAsync = ref.read(myVehiclesFuelProductsProvider);
    if (fuelAsync.isLoading) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang tải danh mục nhiên liệu, vui lòng đợi')),
        );
      }
      return;
    }
    setState(() => _saving = true);
    final String? fuelType;
    if (fuelAsync.hasValue) {
      final products = fuelAsync.requireValue;
      final raw = _fuelDropdownTouched
          ? _fuelProductCode
          : _resolveInitialFuelValue(widget.existing?.fuelType, products);
      fuelType = _nullable(raw ?? '');
    } else {
      fuelType = _nullable(_fuelTypeFallback.text);
    }
    final body = <String, dynamic>{
      'licensePlate': _plate.text.trim(),
      'vehicleName': _nullable(_name.text),
      'fuelType': fuelType,
      // Không còn ô nhập mức xăng — thêm mới: null; sửa: giữ giá trị máy chủ.
      'fuelLevel': widget.existing?.fuelLevel,
      'totalKm': _nullableInt(_totalKm.text),
      'year': _nullableInt(_year.text),
      'isDefault': _isDefault,
    };
    if (widget.existing != null) {
      body['imageUrl'] = widget.existing!.imageUrl;
    }
    try {
      final api = ref.read(myVehiclesApiProvider);
      if (widget.existing == null) {
        await api.createVehicle(body);
      } else {
        await api.updateVehicle(widget.existing!.id, body);
      }
      // Invalidate ngay tại source — parent page refresh `myVehiclesListProvider` qua callback,
      // nhưng trang "Nhiên liệu" (`fuelDashboardProvider`) là consumer độc lập trong shell tab
      // alive cùng lúc nên không tự pickup invalidate qua dependency chain. Force cả hai để
      // mọi tab đang watch đều fetch lại sau khi user add/edit xe.
      ref.invalidate(myVehiclesListProvider);
      ref.invalidate(fuelDashboardProvider);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      final msg = e is ApiException ? e.message : e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final isEdit = widget.existing != null;
    final fuelAsync = ref.watch(myVehiclesFuelProductsProvider);
    final fuelReady = fuelAsync.hasValue || fuelAsync.hasError;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.92,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const LoginBackground(),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
                        child: VehicleFormCard(
                          child: Form(
                            key: _formKey,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Center(
                                  child: Container(
                                    width: 40,
                                    height: 4,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: AppFormTheme.border,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isEdit ? 'Chỉnh sửa xe' : 'Thêm xe mới',
                                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: AppFormTheme.focusBorder,
                                                  height: 1.15,
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Cập nhật thông tin phương tiện của bạn',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: AppFormTheme.hintColor,
                                                  fontWeight: FontWeight.w500,
                                                  height: 1.35,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Đóng',
                                      onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                                      icon: Icon(Icons.close_rounded, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const VehicleFormSectionTitle(title: 'Thông tin cơ bản'),
                                const SizedBox(height: 12),
                                AppTextField(
                                  label: 'Biển số *',
                                  hint: 'Ví dụ: 51H-123.45',
                                  prefixIcon: Icons.directions_car_rounded,
                                  controller: _plate,
                                  textCapitalization: TextCapitalization.characters,
                                  textInputAction: TextInputAction.next,
                                  enabled: !_saving,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập biển số';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                                AppTextField(
                                  label: 'Tên xe',
                                  hint: 'Ví dụ: Toyota Vios',
                                  prefixIcon: Icons.label_outline_rounded,
                                  controller: _name,
                                  textInputAction: TextInputAction.next,
                                  enabled: !_saving,
                                ),
                                const SizedBox(height: 18),
                                fuelAsync.when(
                                  loading: () => _FuelFieldLoading(
                                    label: 'Loại nhiên liệu',
                                    prefixIcon: Icons.local_gas_station_outlined,
                                  ),
                                  error: (e, _) => Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      AppTextField(
                                        label: 'Loại nhiên liệu (nhập tay)',
                                        hint: 'Mã hoặc tên nhiên liệu',
                                        prefixIcon: Icons.local_gas_station_outlined,
                                        controller: _fuelTypeFallback,
                                        enabled: !_saving,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Không tải được danh mục từ máy chủ',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.error,
                                            ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => ref.invalidate(myVehiclesFuelProductsProvider),
                                        icon: const Icon(Icons.refresh_rounded),
                                        label: const Text('Thử tải lại danh mục'),
                                      ),
                                    ],
                                  ),
                                  data: (products) {
                                    final items = _fuelDropdownItems(products, widget.existing?.fuelType);
                                    final resolved = _fuelDropdownTouched
                                        ? _fuelProductCode
                                        : _resolveInitialFuelValue(widget.existing?.fuelType, products);
                                    final safeValue = items.any((it) => it.value == resolved) ? resolved : null;
                                    return AppDropdown<String?>(
                                      label: 'Loại nhiên liệu',
                                      prefixIcon: Icons.local_gas_station_outlined,
                                      value: safeValue,
                                      items: items,
                                      enabled: !_saving,
                                      hint: 'Chọn loại nhiên liệu',
                                      onChanged: (v) => setState(() {
                                        _fuelDropdownTouched = true;
                                        _fuelProductCode = v;
                                      }),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                                const VehicleFormSectionTitle(title: 'Thông tin kỹ thuật'),
                                const SizedBox(height: 12),
                                AppTextField(
                                  label: 'Tổng km',
                                  hint: 'Số km đã chạy',
                                  prefixIcon: Icons.speed_rounded,
                                  controller: _totalKm,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  enabled: !_saving,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return null;
                                    final n = int.tryParse(v.trim());
                                    if (n == null) return 'Nhập số hợp lệ';
                                    if (n < 0) return 'Không được âm';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                                AppTextField(
                                  label: 'Năm sản xuất',
                                  hint: 'Ví dụ: 2020',
                                  prefixIcon: Icons.calendar_today_outlined,
                                  controller: _year,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  enabled: !_saving,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return null;
                                    final n = int.tryParse(v.trim());
                                    if (n == null) return 'Nhập số hợp lệ';
                                    final y = DateTime.now().year;
                                    if (n < 1900 || n > y + 1) return 'Năm không hợp lệ';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                AppSwitch(
                                  label: 'Đặt làm xe mặc định',
                                  switchValue: _isDefault,
                                  enabled: !_saving,
                                  onChanged: (v) => setState(() => _isDefault = v),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(0, 50),
                                          foregroundColor: AppFormTheme.labelColor,
                                          side: const BorderSide(color: AppFormTheme.border, width: 1.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(24),
                                          ),
                                        ),
                                        child: Text(
                                          'Hủy',
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GradientButton(
                                        label: 'Lưu',
                                        loading: _saving,
                                        loadingLabel: 'Đang lưu…',
                                        onPressed: (_saving || !fuelReady) ? null : _save,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FuelFieldLoading extends StatelessWidget {
  const _FuelFieldLoading({required this.label, this.prefixIcon});

  final String label;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (prefixIcon != null) ...[
              Icon(prefixIcon, size: 20, color: AppFormTheme.focusBorder),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppFormTheme.labelColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: AppFormTheme.fieldPadding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppFormTheme.fieldRadius),
            border: Border.all(color: AppFormTheme.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppFormTheme.focusBorder,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Đang tải danh mục…',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppFormTheme.hintColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String? _resolveInitialFuelValue(
  String? stored,
  List<StoreAdminFuelProductListItem> products,
) {
  if (stored == null) return null;
  final raw = stored.trim();
  if (raw.isEmpty) return null;
  for (final p in products) {
    if (!p.isActive) continue;
    final code = p.code.isNotEmpty ? p.code : p.name;
    if (code.isEmpty) continue;
    if (code == raw || p.name == raw) return code;
    if (code.toLowerCase() == raw.toLowerCase() || p.name.toLowerCase() == raw.toLowerCase()) {
      return code;
    }
  }
  return raw;
}

List<DropdownMenuItem<String?>> _fuelDropdownItems(
  List<StoreAdminFuelProductListItem> products,
  String? storedRaw,
) {
  final seen = <String>{};
  final items = <DropdownMenuItem<String?>>[
    const DropdownMenuItem<String?>(
      value: null,
      child: Text('— Chọn loại nhiên liệu —'),
    ),
  ];
  final sorted = [...products]..sort((a, b) {
    final sa = a.sortOrder ?? 999999;
    final sb = b.sortOrder ?? 999999;
    if (sa != sb) return sa.compareTo(sb);
    return a.name.compareTo(b.name);
  });
  for (final p in sorted) {
    if (!p.isActive) continue;
    final v = p.code.isNotEmpty ? p.code : p.name;
    if (v.isEmpty) continue;
    if (!seen.add(v)) continue;
    final label = p.name.isNotEmpty ? p.name : v;
    items.add(DropdownMenuItem<String?>(value: v, child: Text(label)));
  }
  final raw = storedRaw?.trim();
  if (raw != null && raw.isNotEmpty && !seen.contains(raw)) {
    items.add(
      DropdownMenuItem<String?>(
        value: raw,
        child: Text('$raw (không còn trong danh mục)'),
      ),
    );
  }
  return items;
}
