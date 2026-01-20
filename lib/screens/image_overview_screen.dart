import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ps12_image_overview/models/image_metadata.dart';
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
        leading: Consumer<ThemeProvider>(
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
              const SizedBox(height: 8),  // Reduced from 16 to 8 (50% reduction)
              // Image grid
              Expanded(
                child: Container(
                  color: const Color(0xFFf8f9ff),  // Match filter bar background
                  child: _buildImageGrid(provider),
                ),
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
  /// Maintains full grid structure even when no images match the filter,
  /// showing "no image" placeholders in empty cells.
  Widget _buildImageGrid(ImageOverviewProvider provider) {
    // Get the full grid structure from all images (not just filtered)
    final allRows = provider.allRows;
    final allColumns = provider.allColumns;
    final allBarcodes = provider.allBarcodes;

    // If no images loaded at all, show empty state
    if (allRows.isEmpty || allColumns.isEmpty) {
      return const Center(
        child: Text('No images to display'),
      );
    }

    // Create a lookup map for quick access to filtered images
    final imagesByPosition = <String, ImageMetadata>{};
    for (final image in provider.images.images) {
      final key = '${image.row}_${image.column}';
      imagesByPosition[key] = image;
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: allRows.map((rowNumber) {
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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
                      children: allColumns.map((columnNumber) {
                        final key = '${rowNumber}_$columnNumber';
                        final image = imagesByPosition[key];
                        final barcode = columnNumber < allBarcodes.length
                            ? allBarcodes[columnNumber]
                            : '';

                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: 250,
                            height: 250,
                            child: image != null
                                ? ImageGridCell(
                                    image: image,
                                    showLabel: rowNumber == allRows.first,  // Show barcode labels for first row
                                  )
                                : _buildEmptyCell(
                                    barcode: barcode,
                                    showLabel: rowNumber == allRows.first,
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

  /// Builds an empty cell placeholder when no image exists for that grid position.
  Widget _buildEmptyCell({required String barcode, required bool showLabel}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border.all(
          color: Colors.grey.shade800,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Barcode label (shown only on first row)
          if (showLabel)
            Container(
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Text(
                barcode,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          // Empty space with "No image" message
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey.shade700,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No image',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
