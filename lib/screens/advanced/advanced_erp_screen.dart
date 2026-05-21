import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/advanced_erp_models.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/advanced_erp_service.dart';
import '../../widgets/widgets.dart';

class AdvancedErpScreen extends StatefulWidget {
  const AdvancedErpScreen({super.key});

  @override
  State<AdvancedErpScreen> createState() => _AdvancedErpScreenState();
}

class _AdvancedErpScreenState extends State<AdvancedErpScreen> {
  final AdvancedErpService _service = AdvancedErpService();
  final TextEditingController _barcodeController = TextEditingController();

  Future<ProductModel?>? _barcodeLookup;
  bool _isWorking = false;

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  void _lookupBarcode(String businessId) {
    setState(() {
      _barcodeLookup = _service.findProductByBarcode(
        businessId: businessId,
        barcode: _barcodeController.text,
      );
    });
  }

  Future<void> _printThermalReceipt(String businessId) async {
    await _runAction(
      successMessage: 'Thermal print preview opened.',
      action: () => _service.printThermalTestReceipt(
        businessName: 'VyapaarX',
        businessId: businessId,
      ),
    );
  }

  Future<void> _buildGstExport(String businessId) async {
    await _runAction(
      successMessage: 'GST export generated.',
      action: () async {
        final csv = await _service.buildGstExportCsv(businessId);
        if (!mounted) return;
        _showTextSheet(title: 'GST export CSV', content: csv);
      },
    );
  }

  Future<void> _buildBackup(String businessId) async {
    await _runAction(
      successMessage: 'Backup JSON generated.',
      action: () async {
        final backup = await _service.buildBackupJson(businessId);
        if (!mounted) return;
        _showTextSheet(title: 'Backup JSON', content: backup);
      },
    );
  }

  Future<void> _runAction({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    setState(() => _isWorking = true);
    try {
      await action();
      if (!mounted) return;
      SnackBarHelper.show(
        context,
        message: successMessage,
        type: AppSnackBarType.success,
      );
    } on Object catch (_) {
      if (!mounted) return;
      SnackBarHelper.show(
        context,
        message: 'Unable to complete this action.',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    SnackBarHelper.show(
      context,
      message: 'Copied to clipboard.',
      type: AppSnackBarType.success,
    );
  }

  void _showTextSheet({required String title, required String content}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              AppSectionTitle(title: title),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    content,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppPrimaryButton(
                label: 'Copy',
                icon: Icons.copy_rounded,
                onPressed: () => _copyText(content),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addWarehouse(String businessId, String actorId) async {
    final result = await _showFieldsDialog(
      title: 'Add warehouse',
      fields: const [
        _DialogField('name', 'Warehouse name', Icons.warehouse_outlined),
        _DialogField('address', 'Address', Icons.location_on_outlined),
        _DialogField('manager', 'Manager name', Icons.person_outline_rounded),
      ],
    );
    if (result == null) return;

    await _runAction(
      successMessage: 'Warehouse added.',
      action: () => _service.createWarehouse(
        businessId: businessId,
        actorId: actorId,
        name: result['name'] ?? '',
        address: result['address'] ?? '',
        managerName: result['manager'] ?? '',
      ),
    );
  }

  Future<void> _addLead(String businessId, String actorId) async {
    final result = await _showFieldsDialog(
      title: 'Add CRM lead',
      fields: const [
        _DialogField('name', 'Lead name', Icons.person_outline_rounded),
        _DialogField('phone', 'Phone', Icons.phone_outlined),
        _DialogField('notes', 'Notes', Icons.note_alt_outlined, optional: true),
      ],
    );
    if (result == null) return;

    await _runAction(
      successMessage: 'Lead added.',
      action: () => _service.createLead(
        businessId: businessId,
        actorId: actorId,
        name: result['name'] ?? '',
        phone: result['phone'] ?? '',
        stage: 'New',
        notes: result['notes'] ?? '',
      ),
    );
  }

  Future<void> _addTask(String businessId, String actorId) async {
    final result = await _showFieldsDialog(
      title: 'Add task',
      fields: const [
        _DialogField('title', 'Task title', Icons.task_alt_outlined),
        _DialogField('assignedTo', 'Assigned to', Icons.person_outline_rounded),
      ],
    );
    if (result == null) return;

    await _runAction(
      successMessage: 'Task added.',
      action: () => _service.createTask(
        businessId: businessId,
        actorId: actorId,
        title: result['title'] ?? '',
        assignedTo: result['assignedTo'] ?? '',
        dueDate: DateTime.now().add(const Duration(days: 1)),
      ),
    );
  }

  Future<void> _addNotification(String businessId, String actorId) async {
    final result = await _showFieldsDialog(
      title: 'Add notification',
      fields: const [
        _DialogField('title', 'Title', Icons.notifications_outlined),
        _DialogField('message', 'Message', Icons.message_outlined),
      ],
    );
    if (result == null) return;

    await _runAction(
      successMessage: 'Notification added.',
      action: () => _service.createNotification(
        businessId: businessId,
        actorId: actorId,
        title: result['title'] ?? '',
        message: result['message'] ?? '',
      ),
    );
  }

  Future<Map<String, String>?> _showFieldsDialog({
    required String title,
    required List<_DialogField> fields,
  }) async {
    final formKey = GlobalKey<FormState>();
    final controllers = {
      for (final field in fields) field.key: TextEditingController(),
    };

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final field in fields) ...[
                    AppTextField(
                      label: field.label,
                      controller: controllers[field.key],
                      prefixIcon: field.icon,
                      textCapitalization: TextCapitalization.sentences,
                      validator: field.optional
                          ? null
                          : (value) => Validators.requiredText(
                              value,
                              fieldName: field.label,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(context).pop({
                  for (final entry in controllers.entries)
                    entry.key: entry.value.text.trim(),
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    for (final controller in controllers.values) {
      controller.dispose();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final businessId = auth.businessId;
    final actorId = auth.session?.uid ?? 'unknown';

    return AppResponsiveShell(
      title: 'Advanced ERP',
      currentRoute: AppRoutes.advancedErp,
      currentRole: auth.role,
      child: businessId == null || businessId.isEmpty
          ? const AppEmptyState(
              title: 'Business profile needed',
              message: 'Complete business setup before using ERP features.',
              icon: Icons.hub_outlined,
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
              children: [
                const AppSectionHeader(
                  title: 'Advanced ERP',
                  subtitle:
                      'Operations, CRM, tasks, exports, backups, devices, and audit controls.',
                ),
                const SizedBox(height: AppSpacing.lg),
                _DeviceCard(
                  barcodeController: _barcodeController,
                  barcodeLookup: _barcodeLookup,
                  onLookup: () => _lookupBarcode(businessId),
                  onThermalPrint: _isWorking
                      ? null
                      : () => _printThermalReceipt(businessId),
                ),
                const SizedBox(height: AppSpacing.md),
                _WarehousesCard(
                  stream: _service.watchWarehouses(businessId),
                  onAdd: () => _addWarehouse(businessId, actorId),
                ),
                const SizedBox(height: AppSpacing.md),
                _CrmCard(
                  stream: _service.watchLeads(businessId),
                  onAdd: () => _addLead(businessId, actorId),
                ),
                const SizedBox(height: AppSpacing.md),
                _TasksCard(
                  stream: _service.watchTasks(businessId),
                  onAdd: () => _addTask(businessId, actorId),
                  onChanged: (task, done) => _service.setTaskDone(
                    businessId: businessId,
                    actorId: actorId,
                    task: task,
                    isDone: done,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _NotificationsCard(
                  stream: _service.watchNotifications(businessId),
                  onAdd: () => _addNotification(businessId, actorId),
                  onRead: (notification) => _service.markNotificationRead(
                    businessId: businessId,
                    notification: notification,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _ExportsCard(
                  isWorking: _isWorking,
                  onGstExport: () => _buildGstExport(businessId),
                  onBackup: () => _buildBackup(businessId),
                ),
                const SizedBox(height: AppSpacing.md),
                _OfflineSyncCard(),
                const SizedBox(height: AppSpacing.md),
                _AuditLogsCard(stream: _service.watchAuditLogs(businessId)),
              ],
            ),
    );
  }
}

class _DialogField {
  const _DialogField(this.key, this.label, this.icon, {this.optional = false});

  final String key;
  final String label;
  final IconData icon;
  final bool optional;
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.barcodeController,
    required this.barcodeLookup,
    required this.onLookup,
    required this.onThermalPrint,
  });

  final TextEditingController barcodeController;
  final Future<ProductModel?>? barcodeLookup;
  final VoidCallback onLookup;
  final VoidCallback? onThermalPrint;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Barcode and devices',
            subtitle: 'Lookup products by barcode and test thermal printing.',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Barcode',
            controller: barcodeController,
            prefixIcon: Icons.qr_code_scanner_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 520;
              return Flex(
                direction: stacked ? Axis.vertical : Axis.horizontal,
                children: [
                  if (stacked)
                    AppPrimaryButton(
                      label: 'Lookup',
                      icon: Icons.search_rounded,
                      onPressed: onLookup,
                    )
                  else
                    Expanded(
                      child: AppPrimaryButton(
                        label: 'Lookup',
                        icon: Icons.search_rounded,
                        onPressed: onLookup,
                      ),
                    ),
                  SizedBox(
                    width: stacked ? 0 : AppSpacing.sm,
                    height: stacked ? AppSpacing.sm : 0,
                  ),
                  if (stacked)
                    AppPrimaryButton(
                      label: 'Thermal test',
                      icon: Icons.print_outlined,
                      onPressed: onThermalPrint,
                    )
                  else
                    Expanded(
                      child: AppPrimaryButton(
                        label: 'Thermal test',
                        icon: Icons.print_outlined,
                        onPressed: onThermalPrint,
                      ),
                    ),
                ],
              );
            },
          ),
          if (barcodeLookup != null) ...[
            const SizedBox(height: AppSpacing.md),
            FutureBuilder<ProductModel?>(
              future: barcodeLookup,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingSkeleton(height: 48);
                }
                final product = snapshot.data;
                if (product == null) {
                  return const AppStatusChip(
                    label: 'No product found',
                    type: AppStatusType.warning,
                  );
                }
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.inventory_2_outlined),
                  ),
                  title: Text(product.name),
                  subtitle: Text(
                    'Stock ${product.stockQuantity} ${product.unit}',
                  ),
                  trailing: Text(AppFormatters.currency(product.salePrice)),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _WarehousesCard extends StatelessWidget {
  const _WarehousesCard({required this.stream, required this.onAdd});

  final Stream<List<WarehouseModel>> stream;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return _StreamCard<WarehouseModel>(
      title: 'Multi warehouse',
      subtitle: 'Track business stock locations.',
      icon: Icons.warehouse_outlined,
      stream: stream,
      onAdd: onAdd,
      emptyText: 'No warehouses yet.',
      itemBuilder: (warehouse) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(warehouse.name),
        subtitle: Text(warehouse.address),
        trailing: AppStatusChip(
          label: warehouse.isActive ? 'Active' : 'Inactive',
          type: warehouse.isActive
              ? AppStatusType.success
              : AppStatusType.neutral,
        ),
      ),
    );
  }
}

class _CrmCard extends StatelessWidget {
  const _CrmCard({required this.stream, required this.onAdd});

  final Stream<List<CrmLeadModel>> stream;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return _StreamCard<CrmLeadModel>(
      title: 'CRM',
      subtitle: 'Capture leads and follow-ups.',
      icon: Icons.handshake_outlined,
      stream: stream,
      onAdd: onAdd,
      emptyText: 'No CRM leads yet.',
      itemBuilder: (lead) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(lead.name),
        subtitle: Text(lead.phone),
        trailing: AppStatusChip(label: lead.stage, type: AppStatusType.info),
      ),
    );
  }
}

class _TasksCard extends StatelessWidget {
  const _TasksCard({
    required this.stream,
    required this.onAdd,
    required this.onChanged,
  });

  final Stream<List<ErpTaskModel>> stream;
  final VoidCallback onAdd;
  final void Function(ErpTaskModel task, bool done) onChanged;

  @override
  Widget build(BuildContext context) {
    return _StreamCard<ErpTaskModel>(
      title: 'Task management',
      subtitle: 'Assign and track operational work.',
      icon: Icons.task_alt_outlined,
      stream: stream,
      onAdd: onAdd,
      emptyText: 'No tasks yet.',
      itemBuilder: (task) => CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: task.isDone,
        onChanged: (value) => onChanged(task, value ?? false),
        title: Text(task.title),
        subtitle: Text('Assigned to ${task.assignedTo}'),
      ),
    );
  }
}

class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard({
    required this.stream,
    required this.onAdd,
    required this.onRead,
  });

  final Stream<List<AppNotificationModel>> stream;
  final VoidCallback onAdd;
  final ValueChanged<AppNotificationModel> onRead;

  @override
  Widget build(BuildContext context) {
    return _StreamCard<AppNotificationModel>(
      title: 'Notifications',
      subtitle: 'Internal alerts for business users.',
      icon: Icons.notifications_outlined,
      stream: stream,
      onAdd: onAdd,
      emptyText: 'No notifications yet.',
      itemBuilder: (notification) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(notification.title),
        subtitle: Text(notification.message),
        trailing: notification.isRead
            ? const AppStatusChip(label: 'Read', type: AppStatusType.neutral)
            : IconButton(
                tooltip: 'Mark read',
                onPressed: () => onRead(notification),
                icon: const Icon(Icons.mark_email_read_outlined),
              ),
      ),
    );
  }
}

class _StreamCard<T> extends StatelessWidget {
  const _StreamCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.stream,
    required this.onAdd,
    required this.emptyText,
    required this.itemBuilder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Stream<List<T>> stream;
  final VoidCallback onAdd;
  final String emptyText;
  final Widget Function(T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: AppSpacing.cardPadding,
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppSectionHeader(title: title, subtitle: subtitle),
              ),
              IconButton(
                tooltip: 'Add',
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          StreamBuilder<List<T>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const LoadingSkeleton(height: 46);
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(emptyText),
                );
              }
              return Column(children: items.take(4).map(itemBuilder).toList());
            },
          ),
        ],
      ),
    );
  }
}

class _ExportsCard extends StatelessWidget {
  const _ExportsCard({
    required this.isWorking,
    required this.onGstExport,
    required this.onBackup,
  });

  final bool isWorking;
  final VoidCallback onGstExport;
  final VoidCallback onBackup;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Exports and backup',
            subtitle: 'Generate GST CSV and business backup JSON.',
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 520;
              return Flex(
                direction: stacked ? Axis.vertical : Axis.horizontal,
                children: [
                  if (stacked)
                    AppPrimaryButton(
                      label: 'GST export',
                      icon: Icons.file_download_outlined,
                      isLoading: isWorking,
                      onPressed: isWorking ? null : onGstExport,
                    )
                  else
                    Expanded(
                      child: AppPrimaryButton(
                        label: 'GST export',
                        icon: Icons.file_download_outlined,
                        isLoading: isWorking,
                        onPressed: isWorking ? null : onGstExport,
                      ),
                    ),
                  SizedBox(
                    width: stacked ? 0 : AppSpacing.sm,
                    height: stacked ? AppSpacing.sm : 0,
                  ),
                  if (stacked)
                    AppPrimaryButton(
                      label: 'Backup',
                      icon: Icons.backup_outlined,
                      isLoading: isWorking,
                      onPressed: isWorking ? null : onBackup,
                    )
                  else
                    Expanded(
                      child: AppPrimaryButton(
                        label: 'Backup',
                        icon: Icons.backup_outlined,
                        isLoading: isWorking,
                        onPressed: isWorking ? null : onBackup,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Restore is intentionally review-first: use exported JSON for safe manual restore or a future admin import flow.',
          ),
        ],
      ),
    );
  }
}

class _OfflineSyncCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AppActionCard(
      title: 'Offline sync',
      subtitle:
          'Firestore offline persistence is enabled. Queued writes sync when the device reconnects.',
      icon: Icons.sync_outlined,
      onTap: _noop,
      color: AppColors.info,
    );
  }
}

class _AuditLogsCard extends StatelessWidget {
  const _AuditLogsCard({required this.stream});

  final Stream<List<AuditLogModel>> stream;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Audit logs',
            subtitle: 'Recent advanced ERP activity.',
          ),
          const SizedBox(height: AppSpacing.md),
          StreamBuilder<List<AuditLogModel>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const LoadingSkeleton(height: 46);
              }
              final logs = snapshot.data ?? [];
              if (logs.isEmpty) return const Text('No audit logs yet.');

              return Column(
                children: logs.take(6).map((log) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${log.module} ${log.action}'),
                    subtitle: Text(log.description),
                    trailing: const Icon(Icons.history_rounded),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

void _noop() {}
