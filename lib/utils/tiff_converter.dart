import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Utility class for converting 16-bit grayscale TIFF images to PNG format.
///
/// This converter is designed for PamGene microscopy TIFF files which use
/// 16-bit grayscale format (12-bit actual data stored in 16-bit container).
///
/// Usage in a real ImageService implementation:
/// ```dart
/// final tiffBytes = await fetchTiffFromApi(imageId);
/// final pngBytes = TiffConverter.convertToPng(tiffBytes);
/// // Use pngBytes to display the image
/// ```
class TiffConverter {
  TiffConverter._(); // Private constructor - use static methods only

  /// Converts 16-bit grayscale TIFF bytes to PNG bytes.
  ///
  /// Returns null if conversion fails.
  static Uint8List? convertToPng(Uint8List tiffBytes) {
    final image = decode16BitGrayscaleTiff(tiffBytes);
    if (image == null) return null;

    return Uint8List.fromList(img.encodePng(image));
  }

  /// Decodes a 16-bit grayscale TIFF image to an 8-bit image object.
  ///
  /// This manually parses the TIFF format because standard libraries
  /// may not properly handle 16-bit grayscale scientific imaging TIFFs.
  ///
  /// Returns null if decoding fails.
  static img.Image? decode16BitGrayscaleTiff(Uint8List bytes) {
    try {
      // Check TIFF magic number and determine byte order
      // 0x49 0x49 = little endian ("II")
      // 0x4D 0x4D = big endian ("MM")
      if (bytes.length < 8) return null;

      final byteOrder = bytes[0] == 0x49 ? Endian.little : Endian.big;
      final data = ByteData.sublistView(bytes);

      // Verify TIFF magic number (42)
      final magic = data.getUint16(2, byteOrder);
      if (magic != 42) return null;

      // Read IFD (Image File Directory) offset (at byte 4)
      final ifdOffset = data.getUint32(4, byteOrder);
      if (ifdOffset >= bytes.length) return null;

      // Read number of directory entries
      final numEntries = data.getUint16(ifdOffset, byteOrder);

      // TIFF tag values we need to extract
      int? width, height, bitsPerSample, rowsPerStrip;
      int stripOffsetsValue = 0;
      int stripOffsetsCount = 0;
      int stripOffsetsType = 0;

      // Parse IFD entries (each entry is 12 bytes)
      for (var i = 0; i < numEntries; i++) {
        final entryOffset = ifdOffset + 2 + (i * 12);
        if (entryOffset + 12 > bytes.length) break;

        final tag = data.getUint16(entryOffset, byteOrder);
        final type = data.getUint16(entryOffset + 2, byteOrder);
        final count = data.getUint32(entryOffset + 4, byteOrder);

        // Read value based on type
        int value;
        if (type == 3) {
          // SHORT (2 bytes)
          value = data.getUint16(entryOffset + 8, byteOrder);
        } else {
          // LONG (4 bytes) or offset
          value = data.getUint32(entryOffset + 8, byteOrder);
        }

        // Extract relevant tags
        switch (tag) {
          case 256: // ImageWidth
            width = value;
            break;
          case 257: // ImageLength (height)
            height = value;
            break;
          case 258: // BitsPerSample
            bitsPerSample = value;
            break;
          case 273: // StripOffsets
            stripOffsetsValue = value;
            stripOffsetsCount = count;
            stripOffsetsType = type;
            break;
          case 278: // RowsPerStrip
            rowsPerStrip = value;
            break;
        }
      }

      // Validate required fields
      if (width == null || height == null) {
        return null;
      }

      // Default rows per strip to full image height if not specified
      rowsPerStrip ??= height;

      // Read strip offsets array
      final List<int> stripOffsets = [];
      if (stripOffsetsCount == 1) {
        stripOffsets.add(stripOffsetsValue);
      } else {
        // Value is offset to array of offsets
        final arrayOffset = stripOffsetsValue;
        for (var i = 0; i < stripOffsetsCount; i++) {
          if (stripOffsetsType == 3) {
            // SHORT array
            stripOffsets.add(data.getUint16(arrayOffset + i * 2, byteOrder));
          } else {
            // LONG array
            stripOffsets.add(data.getUint32(arrayOffset + i * 4, byteOrder));
          }
        }
      }

      if (stripOffsets.isEmpty) {
        return null;
      }

      // Create 8-bit grayscale output image
      final image = img.Image(width: width, height: height, numChannels: 1);

      // Read pixel data from strips
      var y = 0;
      for (var stripIndex = 0;
          stripIndex < stripOffsets.length && y < height;
          stripIndex++) {
        var pixelOffset = stripOffsets[stripIndex];
        final rowsInStrip =
            (y + rowsPerStrip > height) ? height - y : rowsPerStrip;

        for (var row = 0; row < rowsInStrip && y < height; row++, y++) {
          for (var x = 0; x < width; x++) {
            if (pixelOffset + 1 >= bytes.length) break;

            // Read 16-bit value
            final value16 = data.getUint16(pixelOffset, byteOrder);

            // Convert to 8-bit:
            // - For 16-bit data: shift right by 8 bits
            // - For 12-bit data stored in 16-bit: shift right by 4 bits
            // We use 4-bit shift assuming 12-bit data (common for PamGene)
            final value8 = (bitsPerSample == 16)
                ? (value16 >> 8) & 0xFF
                : (value16 >> 4) & 0xFF;

            image.setPixelRgb(x, y, value8, value8, value8);
            pixelOffset += 2;
          }
        }
      }

      return image;
    } catch (e) {
      return null;
    }
  }

  /// Extracts metadata from a PamGene TIFF filename.
  ///
  /// Filename format: {id}_W{well}_F{field}_T{temp}_P{pump}_I{intensity}_A{array}.tif
  ///
  /// Returns a map with extracted values, or empty map if parsing fails.
  static Map<String, dynamic> parseFilename(String filename) {
    final result = <String, dynamic>{};

    try {
      // Remove path and extension
      final name = filename.split('/').last.split('\\').last;
      final baseName = name.replaceAll(RegExp(r'\.(tiff?|png)$', caseSensitive: false), '');

      final parts = baseName.split('_');
      if (parts.isEmpty) return result;

      // First part is the image ID
      result['id'] = parts[0];

      // Parse remaining parts
      for (var i = 1; i < parts.length; i++) {
        final part = parts[i];
        if (part.length < 2) continue;

        final prefix = part[0];
        final value = int.tryParse(part.substring(1));

        switch (prefix) {
          case 'W':
            result['well'] = value;
            break;
          case 'F':
            result['field'] = value;
            break;
          case 'T':
            result['temperature'] = value;
            break;
          case 'P':
            result['pumpCycle'] = value;
            break;
          case 'I':
            result['intensity'] = value;
            break;
          case 'A':
            result['array'] = value;
            break;
        }
      }
    } catch (e) {
      // Return whatever we managed to parse
    }

    return result;
  }
}
