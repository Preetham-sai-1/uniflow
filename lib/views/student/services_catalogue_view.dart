import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../models/service_item.dart';
import '../../widgets/responsive_container.dart';
import 'request_form_view.dart';

class ServicesCatalogueView extends StatefulWidget {
  final AppState appState;

  const ServicesCatalogueView({
    super.key,
    required this.appState,
  });

  @override
  State<ServicesCatalogueView> createState() => _ServicesCatalogueViewState();
}

class _ServicesCatalogueViewState extends State<ServicesCatalogueView> {
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_onStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.appState.loadServices();
    });
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onStateChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getCategories(List<CampusServiceItem> services) {
    final set = <String>{'All'};
    for (final s in services) {
      if (s.category.isNotEmpty) set.add(s.category);
    }
    return set.toList();
  }

  @override
  Widget build(BuildContext context) {
    // Prefer backend services if loaded, otherwise fallback to availableServices if not errored
    final List<CampusServiceItem> rawServices =
        widget.appState.services.isNotEmpty
            ? widget.appState.services
            : (widget.appState.servicesError != null ||
                    widget.appState.hasLoadedServices
                ? <CampusServiceItem>[]
                : CampusServiceItem.availableServices);

    final categories = _getCategories(rawServices);
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = 'All';
    }

    final filteredServices = rawServices.where((s) {
      final matchesCategory = _selectedCategory == 'All' ||
          s.category.toLowerCase() == _selectedCategory.toLowerCase();
      final query = _searchController.text.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          s.title.toLowerCase().contains(query) ||
          s.description.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    final isLoading =
        widget.appState.isLoadingServices && widget.appState.services.isEmpty;
    final hasError = widget.appState.servicesError != null &&
        widget.appState.services.isEmpty;

    return ResponsiveContainer(
      title: 'Campus Services',
      subtitle: 'Browse and initiate verified campus service requests.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    hintText: 'Search services by name or description...',
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
                if (categories.length > 1) ...[
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _selectedCategory = cat),
                            selectedColor: const Color(0xFFEFF6FF),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : AppColors.borderSubtle,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Loading, Error, Empty, or Service Grid
          if (isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading campus services...',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryNavy,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else if (hasError)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      size: 48, color: AppColors.statusRejected),
                  const SizedBox(height: 14),
                  const Text(
                    'Unable to load services from server',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.appState.servicesError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry Connection'),
                    onPressed: () =>
                        widget.appState.loadServices(forceRefresh: true),
                  ),
                ],
              ),
            )
          else if (rawServices.isEmpty && widget.appState.hasLoadedServices)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Column(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 48, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text('No campus services available',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy)),
                  SizedBox(height: 4),
                  Text('Check back later for active institutional services.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            )
          else if (filteredServices.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Column(
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 48, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text('No campus services match your search',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy)),
                  SizedBox(height: 4),
                  Text('Try adjusting your category filter or keyword.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 2 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 250,
                  ),
                  itemCount: filteredServices.length,
                  itemBuilder: (context, index) {
                    final service = filteredServices[index];
                    return _ServiceCard(
                      service: service,
                      onStart: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RequestFormView(
                              serviceType: service.type,
                              service: service,
                              appState: widget.appState,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final CampusServiceItem service;
  final VoidCallback onStart;

  const _ServiceCard({
    required this.service,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(service.icon, color: AppColors.primaryBlue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.category,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              service.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      service.sla,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Start Request'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
