import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_web/features/devices/presentation/viewmodels/devices_viewmodel.dart';
import 'package:fusion_web/features/devices/data/repositories/devices_repository_impl.dart';
import 'package:fusion_web/features/devices/data/datasources/device_datasource.dart';
import 'package:fusion_web/features/devices/presentation/widgets/device_grid_view.dart';
import 'package:fusion_web/features/devices/presentation/widgets/device_overview.dart';
import 'package:fusion_web/features/devices/presentation/widgets/devices_header.dart';
import 'package:fusion_web/features/devices/presentation/widgets/device_filters.dart';
import 'package:fusion_web/features/devices/presentation/widgets/devices_list_view.dart';
import 'package:fusion_web/core/presentation/base_viewmodel.dart';
import 'package:fusion_web/features/devices/data/models/devices_model.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DevicesViewModel(DevicesRepositoryImpl(DeviceDatasource()))
            ..loadDevices(),
      child: _DevicesView(searchController: _searchController),
    );
  }
}

class _DevicesView extends StatelessWidget {
  final TextEditingController searchController;

  const _DevicesView({required this.searchController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),

      child: BlocBuilder<DevicesViewModel, BaseState<DevicesModel>>(
        builder: (context, state) {
          if (state is LoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LoadedState<DevicesModel>) {
            final stats = state.data;
            final viewModel = context.watch<DevicesViewModel>();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DevicesHeader(),

                  const SizedBox(height: 24),

                  DevicesOverview(
                    total: stats.total,
                    healthy: stats.healthy,
                    critical: stats.critical,
                    inactive: stats.inactive,
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "All Devices (${stats.devices.length})",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 16),

                        DeviceFilters(
                          searchController: searchController,
                          onSearchChanged: (v) => viewModel.updateSearch(v),
                          onClearFilters: () {
                            viewModel.clearFilters();
                            searchController.clear();
                          },
                          showClearFilters: viewModel.hasActiveFilters,
                          selectedStatus: viewModel.selectedStatus,
                          selectedProjects: viewModel.selectedProject,
                          selectedModels: viewModel.selectedModel,
                          selectedCategory: viewModel.selectedCategory,
                          selectedTypes: viewModel.selectedType,
                          isGridView: viewModel.isGridView,

                          statusItems: const [
                            "All Status",
                            "Healthy",
                            "Critical",
                            "Inactive",
                          ],

                          modelItems: const [
                            "All Models",
                            "EdgeMax EM90",
                            "PowerMatch PM8500N",
                            "ControlSpace EX-1280C",
                            "FreeSpace FS4SE",
                            "ControlSpace EX-440C",
                          ],

                          typeItems: const [
                            "All Types",
                            "Speaker",
                            "Amplifier",
                            "Controller",
                            "Processor",
                          ],

                          projectItems: const [
                            "All Projects",
                            "Metro University Campus Audio",
                            "Skyline Downtown Conference Center",
                            "Skyline Resort & Spa",
                            "Grand Plaza Convention Hall",
                            "TechHub Innovation Center",
                          ],

                          categoryItems: const [
                            "Name",
                            "Model",
                            "Status",
                            "Last Seen",
                          ],

                          onStatusChanged: (v) => viewModel.updateStatus(v!),
                          onProjectChanged: (v) => viewModel.updateProject(v!),
                          onModelChanged: (v) => viewModel.updateModel(v!),
                          onTypeChanged: (v) => viewModel.updateType(v!),
                          onCategoryChanged: (v) =>
                              viewModel.updateCategory(v!),
                          onGridTap: () => viewModel.toggleGrid(true),
                          onListTap: () => viewModel.toggleGrid(false),
                        ),

                        const SizedBox(height: 24),

                        viewModel.isGridView
                            ? DevicesGridView(devices: stats.devices)
                            : DevicesListView(devices: stats.devices),
                      ],
                    ),
                  ),

                  // const SizedBox(height: 24),
                ],
              ),
            );
          }

          if (state is ErrorState<DevicesModel>) {
            return Center(child: Text(state.message));
          }

          return const SizedBox();
        },
      ),
    );
  }
}
