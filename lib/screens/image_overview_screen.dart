import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ps12_image_overview/providers/image_overview_provider.dart';
import 'package:ps12_image_overview/widgets/image_grid_cell.dart';

/// Main screen displaying the image overview with filters and grid.
class ImageOverviewScreen extends StatefulWidget {
  const ImageOverviewScreen({super.key});

  @override
  State<ImageOverviewScreen> createState() => _ImageOverviewScreenState();
}

class _ImageOverviewScreenState extends State<ImageOverviewScreen> {
  @override
  void initState() {
    super.initState();
    // Load images when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ImageOverviewProvider>().loadImages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PS12 Image Overview'),
        backgroundColor: const Color(0xFF005f75),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<ImageOverviewProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.images.count == 0) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Text(
                'Error: ${provider.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return Column(
            children: [
              // Filter controls
              _buildFilterControls(context, provider),
              const SizedBox(height: 16),
              // Image grid
              Expanded(
                child: _buildImageGrid(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds the filter controls section.
  Widget _buildFilterControls(
      BuildContext context, ImageOverviewProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          // Cycle filter
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cycle',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                _buildDropdown(
                  value: provider.filters.cycle,
                  items: provider.availableCycles,
                  hint: 'Select cycle',
                  onChanged: (value) {
                    provider.setCycleFilter(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          // Exposure Time filter
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter_Exposure Time',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                _buildDropdown(
                  value: provider.filters.exposureTime,
                  items: provider.availableExposureTimes,
                  hint: 'Select exposure time',
                  onChanged: (value) {
                    provider.setExposureTimeFilter(value);
                  },
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  /// Builds a dropdown widget for filters.
  Widget _buildDropdown({
    required int? value,
    required List<int> items,
    required String hint,
    required void Function(int?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade600)),
          isExpanded: true,
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text('All', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ...items.map((item) => DropdownMenuItem<int?>(
                  value: item,
                  child: Text(item.toString()),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// Builds the image grid.
  Widget _buildImageGrid(ImageOverviewProvider provider) {
    if (provider.images.count == 0) {
      return const Center(
        child: Text('No images to display'),
      );
    }

    // Group images by row
    final imagesByRow = provider.images.groupByRow();
    final rows = imagesByRow.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows.map((rowNumber) {
          final rowImages = imagesByRow[rowNumber]!;
          // Sort by column
          rowImages.sort((a, b) => a.column.compareTo(b.column));

          return Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Row number label
                SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(
                      rowNumber.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                // Images in this row
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: rowImages.map((image) {
                      return Expanded(
                        child: ImageGridCell(
                          image: image,
                          showLabel: rowNumber == 1,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
