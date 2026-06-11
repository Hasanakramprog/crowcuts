import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_colors_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/providers/barber_provider.dart';
import '../../../data/models/models.dart';

/// Admin — Service Catalog CRUD with real add/edit/toggle
class ServiceCatalogScreen extends ConsumerStatefulWidget {
  const ServiceCatalogScreen({super.key});

  @override
  ConsumerState<ServiceCatalogScreen> createState() =>
      _ServiceCatalogScreenState();
}

class _ServiceCatalogScreenState extends ConsumerState<ServiceCatalogScreen> {
  final _nameController = TextEditingController();
  final _editController = TextEditingController();
  bool _isAdding = false;
  String? _editingId;

  @override
  void dispose() {
    _nameController.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _addService() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    ref.read(serviceCatalogProvider.notifier).addService(name);
    _nameController.clear();
    setState(() => _isAdding = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Service "$name" added'),
        backgroundColor: AppColors.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _startEdit(ServiceModel service) {
    _editController.text = service.name;
    setState(() => _editingId = service.id);
  }

  void _saveEdit(String id) {
    final name = _editController.text.trim();
    if (name.isEmpty) return;

    ref.read(serviceCatalogProvider.notifier).updateService(id, name);
    setState(() => _editingId = null);
    _editController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Service updated'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  void _toggleService(ServiceModel service) {
    ref.read(serviceCatalogProvider.notifier).toggleService(service.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          service.isActive
              ? '"${service.name}" deactivated'
              : '"${service.name}" reactivated',
        ),
        backgroundColor: service.isActive
            ? context.colors.textMuted
            : AppColors.successGreen,
      ),
    );
  }

  IconData _iconForService(String iconName) {
    switch (iconName) {
      case 'content_cut':
        return Icons.content_cut;
      case 'face':
        return Icons.face;
      case 'water_drop':
        return Icons.water_drop;
      case 'spa':
        return Icons.spa;
      case 'star':
        return Icons.star;
      case 'child_care':
        return Icons.child_care;
      case 'auto_fix_high':
        return Icons.auto_fix_high;
      case 'masks':
        return Icons.masks;
      default:
        return Icons.content_cut;
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(serviceCatalogProvider);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Service Catalog'),
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isAdding
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() => _isAdding = false);
                      _nameController.clear();
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() => _isAdding = true),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Add new service form
          if (_isAdding)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.borderGold, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add_circle_outline,
                          color: AppColors.goldPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text('Add New Service', style: AppTypography.heading2),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Service name (e.g. "Haircut")',
                      prefixIcon: Icon(Icons.content_cut_outlined, size: 20),
                    ),
                    autofocus: true,
                    onSubmitted: (_) => _addService(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Cancel',
                          isOutlined: true,
                          onPressed: () {
                            setState(() => _isAdding = false);
                            _nameController.clear();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'Add Service',
                          onPressed: _addService,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),

          const SizedBox(height: 8),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '${services.length} services',
                  style: AppTypography.caption.copyWith(color: context.colors.textMuted),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: context.colors.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${services.where((s) => s.isActive).length} active',
                  style: AppTypography.caption.copyWith(color: AppColors.successGreen),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Service list
          Expanded(
            child: services.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.content_cut_rounded,
                            size: 48, color: context.colors.textMuted.withAlpha(60)),
                        const SizedBox(height: 12),
                        Text('No services yet',
                            style: AppTypography.body.copyWith(
                                color: context.colors.textMuted)),
                        const SizedBox(height: 4),
                        Text('Tap + to add your first service',
                            style: AppTypography.caption.copyWith(
                                color: context.colors.textMuted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      final isEditing = _editingId == service.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          child: isEditing
                              ? _buildEditMode(service)
                              : _buildDisplayMode(service),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayMode(ServiceModel service) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: service.isActive
                ? AppColors.goldDim
                : context.colors.textMuted.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _iconForService(service.iconName ?? ''),
            size: 22,
            color: service.isActive
                ? AppColors.goldPrimary
                : context.colors.textMuted,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.name,
                style: AppTypography.bodyBold.copyWith(
                  color: service.isActive
                      ? AppColors.textPrimary
                      : context.colors.textMuted,
                ),
              ),
              Text(
                'ID: ${service.id}',
                style: AppTypography.caption.copyWith(
                  color: context.colors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (!service.isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.colors.textMuted.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'INACTIVE',
              style: AppTypography.caption.copyWith(
                color: context.colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        IconButton(
          icon: Icon(Icons.edit_outlined, size: 18,
              color: context.colors.textMuted),
          onPressed: () => _startEdit(service),
          tooltip: 'Edit',
        ),
        IconButton(
          icon: Icon(
            service.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18,
            color: service.isActive
                ? AppColors.warningAmber
                : AppColors.successGreen,
          ),
          onPressed: () => _toggleService(service),
          tooltip: service.isActive ? 'Deactivate' : 'Activate',
        ),
      ],
    );
  }

  Widget _buildEditMode(ServiceModel service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.edit_outlined, size: 18, color: AppColors.goldPrimary),
            const SizedBox(width: 8),
            Text('Editing: ${service.name}', style: AppTypography.heading2),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _editController,
          decoration: const InputDecoration(
            hintText: 'Service name',
            prefixIcon: Icon(Icons.edit_outlined, size: 20),
          ),
          autofocus: true,
          onSubmitted: (_) => _saveEdit(service.id),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Cancel',
                isOutlined: true,
                onPressed: () {
                  setState(() => _editingId = null);
                  _editController.clear();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Save',
                onPressed: () => _saveEdit(service.id),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
