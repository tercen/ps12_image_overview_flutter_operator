import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ps12_image_overview/providers/image_overview_provider.dart';
import 'package:ps12_image_overview/providers/theme_provider.dart';
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
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                tooltip: themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
        ],
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
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          // Pump Cycle filter
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pump Cycle',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                _buildDropdown(
                  value: provider.filters.cycle,
                  items: provider.availableCycles.reversed.toList(),
                  hint: 'Select pump cycle',
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
                  'Exposure Time',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                _buildDropdown(
                  value: provider.filters.exposureTime,
                  items: provider.availableExposureTimes.reversed.toList(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(4),
        color: isDark ? Colors.grey.shade800 : Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          isExpanded: true,
          dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
          items: items.map((item) => DropdownMenuItem<int?>(
                value: item,
                child: Text(
                  item.toString(),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              )).toList(),
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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows.map((rowNumber) {
            final rowImages = imagesByRow[rowNumber]!;
            // Sort by column
            rowImages.sort((a, b) => a.column.compareTo(b.column));

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row label (Well number: W1, W2, etc.)
                SizedBox(
                  width: 40,
                  height: 274, // 250px cell + 12px top margin + 12px bottom margin
                  child: Center(
                    child: Text(
                      'W${rowNumber + 1}',  // row 0 = W1, row 1 = W2, etc.
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                // Images in this row - wrapped in Expanded to allow horizontal scrolling
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: rowImages.map((image) {
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: 250,
                            height: 250,
                            child: ImageGridCell(
                              image: image,
                              showLabel: rowNumber == 0,  // Show barcode labels for first row (W1)
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
