import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Converts 16-bit grayscale TIFF files to PNG format.
/// Inspired by pamgene_tiff_zip_test.dart decoder.
void main(List<String> args) async {
  final assetsDir = Directory('web/assets');

  if (!await assetsDir.exists()) {
    print('Error: web/assets directory not found');
    exit(1);
  }

  final tiffFiles = await assetsDir
      .list()
      .where((entity) => entity is File && entity.path.toLowerCase().endsWith('.tif'))
      .cast<File>()
      .toList();

  print('Found ${tiffFiles.length} TIFF files to convert\n');

  for (final tiffFile in tiffFiles) {
    final filename = tiffFile.path.split(Platform.pathSeparator).last;
    print('Converting: $filename');

    try {
      final bytes = await tiffFile.readAsBytes();
      final pngImage = decode16BitGrayscaleTiff(bytes);

      if (pngImage != null) {
        final pngBytes = img.encodePng(pngImage);
        final pngFilename = filename.replaceAll(RegExp(r'\.(tiff?|TIFF?)$'), '.png');
        final pngFile = File('${assetsDir.path}/$pngFilename');
        await pngFile.writeAsBytes(pngBytes);
        print('  -> Saved: $pngFilename (${pngBytes.length} bytes)');
      } else {
        print('  -> Failed to decode');
      }
    } catch (e) {
      print('  -> Error: $e');
    }
  }

  print('\nDone!');
}

/// Manual decoder for 16-bit grayscale uncompressed TIFF
/// Adapted from pamgene_tiff_zip_test.dart
img.Image? decode16BitGrayscaleTiff(Uint8List bytes) {
  try {
    // Check TIFF magic number
    var byteOrder = bytes[0] == 0x49 ? Endian.little : Endian.big;
    var data = ByteData.sublistView(bytes);

    // Read IFD offset (at byte 4)
    var ifdOffset = data.getUint32(4, byteOrder);

    // Read number of directory entries
    var numEntries = data.getUint16(ifdOffset, byteOrder);

    int? width, height, bitsPerSample, rowsPerStrip;
    int stripOffsetsValue = 0;
    int stripOffsetsCount = 0;
    int stripOffsetsType = 0;

    // Parse IFD entries
    for (var i = 0; i < numEntries; i++) {
      var entryOffset = ifdOffset + 2 + (i * 12);
      var tag = data.getUint16(entryOffset, byteOrder);
      var type = data.getUint16(entryOffset + 2, byteOrder);
      var count = data.getUint32(entryOffset + 4, byteOrder);

      int value;
      if (type == 3) {
        // SHORT
        value = data.getUint16(entryOffset + 8, byteOrder);
      } else {
        // LONG or offset
        value = data.getUint32(entryOffset + 8, byteOrder);
      }

      switch (tag) {
        case 256:
          width = value;
          break; // ImageWidth
        case 257:
          height = value;
          break; // ImageLength
        case 258:
          bitsPerSample = value;
          break; // BitsPerSample
        case 273: // StripOffsets
          stripOffsetsValue = value;
          stripOffsetsCount = count;
          stripOffsetsType = type;
          break;
        case 278:
          rowsPerStrip = value;
          break; // RowsPerStrip
      }
    }

    if (width == null || height == null) {
      print('  Missing required TIFF tags');
      return null;
    }

    rowsPerStrip ??= height;
    var numStrips = (height + rowsPerStrip - 1) ~/ rowsPerStrip;

    // Read strip offsets array
    List<int> stripOffsets = [];
    if (stripOffsetsCount == 1) {
      stripOffsets.add(stripOffsetsValue);
    } else {
      // Value is offset to array
      var arrayOffset = stripOffsetsValue;
      for (var i = 0; i < stripOffsetsCount; i++) {
        if (stripOffsetsType == 3) {
          // SHORT
          stripOffsets.add(data.getUint16(arrayOffset + i * 2, byteOrder));
        } else {
          // LONG
          stripOffsets.add(data.getUint32(arrayOffset + i * 4, byteOrder));
        }
      }
    }

    print('  Dimensions: ${width}x${height}, ${bitsPerSample ?? 8}-bit');
    print('  Strips: $numStrips, rows per strip: $rowsPerStrip');

    // Create 8-bit grayscale image
    var image = img.Image(width: width, height: height, numChannels: 1);

    // Read strips
    var y = 0;
    for (var stripIndex = 0;
        stripIndex < stripOffsets.length && y < height;
        stripIndex++) {
      var pixelOffset = stripOffsets[stripIndex];
      var rowsInStrip = (y + rowsPerStrip > height) ? height - y : rowsPerStrip;

      for (var row = 0; row < rowsInStrip && y < height; row++, y++) {
        for (var x = 0; x < width; x++) {
          if (pixelOffset + 1 >= bytes.length) break;

          // Read 16-bit value (12-bit data stored in high bits)
          var value16 = data.getUint16(pixelOffset, byteOrder);
          // Convert 12-bit (0-4095) to 8-bit (0-255)
          var value8 = (value16 >> 4) & 0xFF;

          image.setPixelRgb(x, y, value8, value8, value8);
          pixelOffset += 2;
        }
      }
    }

    return image;
  } catch (e) {
    print('  Decode error: $e');
    return null;
  }
}
