# PS12 Image Overview - Technical Specification

**Version:** 1.0.0
**Status:** Active
**Last Updated:** 2026-01-28

---

## 1. Overview

This document defines the data structures, schemas, and technical requirements for the PS12 Image Overview operator. Implementation patterns and design guidelines are maintained separately in Claude Skills and tercen-style documentation.

**Related Documentation:**
- Functional Specification: `IMAGE_OVERVIEW_FUNCTIONAL_SPECIFICATION.md`
- Implementation Patterns: `.claude/skills/`
- Design Standards: `_local/tercen-style/`

---

## 2. Input Data Schema

### 2.1 Tercen Input

The operator receives input via Tercen's standard operator interface.

**Required Column:**
| Column | Type | Description |
|--------|------|-------------|
| `.documentId` | String | Reference to ZIP archive in Tercen file storage |

**Note:** The documentId points to a ZIP file, not directly to images. The ZIP must be downloaded and extracted to access image files.

### 2.2 ZIP Archive Structure

```
{archive}.zip
└── ImageResults/
    ├── {barcode}_W{well}_F{field}_T{temp}_P{cycle}_I{exposure}_A{array}.tif
    ├── {barcode}_W{well}_F{field}_T{temp}_P{cycle}_I{exposure}_A{array}.tif
    └── ...
```

**Directory:** Images are located in `ImageResults/` subdirectory within the ZIP.

**File Format:** TIFF files with metadata embedded in EXIF tags.

### 2.3 Filename Convention

```
{barcode}_W{well}_F{field}_T{temperature}_P{pumpCycle}_I{intensity}_A{array}.tif
```

**Example:** `641070616_W1_F1_T100_P94_I493_A30.tif`

| Component | Format | Description | Example |
|-----------|--------|-------------|---------|
| barcode | 9 digits | Unique plate identifier | 641070616 |
| well | W{n} | Well position (1-4) | W1 |
| field | F{n} | Microscopy field of view | F1 |
| temperature | T{n} | Temperature in °C | T100 |
| pumpCycle | P{n} | Pump cycle number | P94 |
| intensity | I{n} | Exposure time in ms | I493 |
| array | A{n} | Array type identifier | A30 |

**Regex Pattern:**
```
(\d+)_W(\d+)_F(\d+)_T(\d+)_P(\d+)_I(\d+)_A(\d+)
```

---

## 3. TIFF EXIF Metadata

### 3.1 Tag Mapping

Metadata is extracted from TIFF EXIF tags. The following tags are defined:

| EXIF Tag | Internal Name | Type | Description |
|----------|---------------|------|-------------|
| DateTime | date_time | String | Capture timestamp |
| Barcode | barcode | String | Plate barcode |
| Col | col | Integer | Column position |
| Cycle | cycle | Integer | Pump cycle number |
| Exposure Time | exposure_time | Integer | Exposure in milliseconds |
| Filter | filter | String | Optical filter used |
| PS12 | ps12 | String | Instrument identifier |
| Row | row | Integer | Row position |
| Temperature | temperature | Float | Temperature in °C |
| Timestamp | timestamp | String | Unix timestamp |
| Instrument Unit | instrument_unit | String | Instrument serial number |
| Run ID | run_id | String | Unique run identifier |

### 3.2 Fallback Behaviour

If EXIF tags are missing or corrupted:
1. Attempt to parse metadata from filename
2. Use filename-parsed values as fallback
3. Log warning for missing EXIF data
4. Continue processing (do not fail on missing metadata)

---

## 4. Image Data Specifications

### 4.1 Source Format (TIFF)

| Property | Value |
|----------|-------|
| Format | TIFF (Tagged Image File Format) |
| Colour Space | Grayscale |
| Container Bit Depth | 16-bit |
| Actual Data Depth | 12-bit (values 0-4095) |
| Compression | Typically uncompressed |

### 4.2 Display Format (PNG)

| Property | Value |
|----------|-------|
| Format | PNG |
| Colour Space | Grayscale or RGB |
| Bit Depth | 8-bit (values 0-255) |

### 4.3 Bit Depth Conversion

**Requirement:** Convert 12-bit data to 8-bit for web display.

**Conversion Formula:**
```
value_8bit = value_12bit >> 4
```
Or equivalently:
```
value_8bit = floor(value_12bit / 16)
```

**Rationale:**
- Source: 12-bit data stored in 16-bit container (0-4095 range)
- Target: 8-bit display (0-255 range)
- Method: Right-shift 4 bits (divide by 16) to map full 12-bit range to 8-bit

**Reference (Shiny implementation):**
```r
png::writePNG(tiff::readTIFF(tiff_file) * 16, png_file)
```
Note: The Shiny code multiplies by 16 because `readTIFF` normalizes to 0-1 range, then PNG expects 0-1. The net effect is the same bit-shift operation.

---

## 5. Grid Data Organization

### 5.1 Grid Structure

| Property | Value |
|----------|-------|
| Columns | One per unique Barcode |
| Rows | One per unique Row/Well value |
| Column Headers | Barcode values |
| Row Headers | Row numbers (1, 2, 3, 4) |

### 5.2 Grid Organization

**Column Order:** Barcodes sorted alphanumerically (ascending)

**Row Order:** Row numbers sorted numerically (ascending)

**Cell Position:**

```text
grid[row_index][barcode_index] = image
```

### 5.3 Grid Sizing Constraints

| Constraint | Description |
|------------|-------------|
| Aspect Ratio | Images must maintain original aspect ratio (no distortion) |
| Maximise Size | Images should be as large as possible within cells |
| Visible Rows | All 4 rows must be visible without vertical scrolling |

**Note:** Visual design (cell dimensions, spacing, styling) is determined by skills and tercen-style guidelines to meet these constraints.

---

## 6. Filter Specifications

### 6.1 Cycle Filter

| Property | Value |
|----------|-------|
| Data Source | `cycle` field from image metadata |
| Display Format | "Cycle {n}" |
| Sort Order | Ascending |
| Default Selection | Highest (latest) value |

### 6.2 Exposure Time Filter

| Property | Value |
|----------|-------|
| Data Source | `exposureTime` field from image metadata |
| Display Format | "{n}ms" or "{n} ms" |
| Sort Order | Ascending |
| Default Selection | Highest (longest) value |

### 6.3 Filter Logic

**Combined Filter (AND):**
```
display_image = (image.cycle == selected_cycle)
            AND (image.exposureTime == selected_exposure)
```

Both filters must match for an image to be displayed.

---

## 7. Data Models

### 7.1 ImageMetadata

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | String | Yes | Unique identifier |
| filename | String | Yes | Original TIFF filename |
| barcode | String | Yes | Plate barcode |
| well | Integer | Yes | Well number (1-4) |
| field | Integer | Yes | Field of view number |
| cycle | Integer | Yes | Pump cycle number |
| exposureTime | Integer | Yes | Exposure in milliseconds |
| row | Integer | No | Row position |
| col | Integer | No | Column position |
| temperature | Float | No | Temperature in °C |
| dateTime | String | No | Capture timestamp |
| runId | String | No | Run identifier |

### 7.2 ImageCollection

| Field | Type | Description |
|-------|------|-------------|
| images | List<ImageMetadata> | All loaded images |
| barcodes | List<String> | Unique barcode values (sorted) |
| wells | List<Integer> | Unique well values (sorted) |
| cycles | List<Integer> | Unique cycle values (sorted) |
| exposureTimes | List<Integer> | Unique exposure time values (sorted) |

### 7.3 FilterCriteria

| Field | Type | Description |
|-------|------|-------------|
| cycle | Integer? | Selected cycle (null = no filter) |
| exposureTime | Integer? | Selected exposure time (null = no filter) |

---

## 8. Error Conditions

### 8.1 Data Loading Errors

| Error | Handling |
|-------|----------|
| Invalid documentId | Display error message, prevent grid load |
| ZIP download failure | Display error with retry option |
| ZIP extraction failure | Display error message |
| No images in ZIP | Display "No images found" message |

### 8.2 Image Processing Errors

| Error | Handling |
|-------|----------|
| Invalid TIFF format | Skip image, log warning, continue |
| TIFF conversion failure | Skip image, log warning, continue |
| Missing EXIF data | Use filename parsing as fallback |
| Filename parse failure | Skip image, log warning, continue |

### 8.3 Display Errors

| Error | Handling |
|-------|----------|
| Image render failure | Display placeholder with error indicator |
| No images match filter | Display "No images match filters" message |

---

## 9. Output Specification

**This operator produces NO output.**

| Property | Value |
|----------|-------|
| Tercen Output | None |
| File Output | None |
| State Persistence | None |

The application is strictly view-only for quality control inspection purposes.

---

## 10. Mock Data Specification

### 10.1 Mock Data Source

Mock data for development and testing **must be extracted from a production PamGene ZIP file**, not from screenshots or synthetic images.

**Rationale:**

- Ensures mock images have authentic PamGene characteristics
- Tests real TIFF-to-PNG conversion pipeline
- Validates filename parsing with production filenames
- Provides realistic metadata from EXIF tags
- Guarantees mock behaviour matches production behaviour

### 10.2 Mock Data Preparation

**Input:** Production PamGene ZIP archive (provided separately)

**Process:**

1. Extract TIFF files from `ImageResults/` directory in ZIP
2. Convert 12-bit TIFF to 8-bit PNG using standard conversion
3. Place converted PNG files in `assets/` directory
4. Preserve original filenames (change extension from `.tif` to `.png`)

**Output:** PNG files in assets following the naming convention:

```text
assets/
├── {barcode}_W{well}_F{field}_T{temp}_P{cycle}_I{exposure}_A{array}.png
├── ...
```

### 10.3 Mock Data Requirements

| Requirement  | Description                                      |
|--------------|--------------------------------------------------|
| Source       | Production PamGene ZIP file (not screenshots)    |
| Format       | PNG (converted from TIFF)                        |
| Naming       | Original PamGene filename convention preserved   |
| Coverage     | Multiple barcodes, wells, cycles, exposure times |
| Authenticity | Real fluorescence images, not placeholders       |

### 10.4 Mock Data Selection Criteria

Select a representative subset from the production ZIP that includes:

- At least 2-3 unique barcodes
- All 4 wells (W1-W4)
- Multiple cycle values (for filter testing)
- Multiple exposure times (for filter testing)
- Sufficient images to demonstrate grid layout

---

## 11. Constraints

### 11.1 Data Constraints

- Images must be in TIFF format
- TIFF files must be 16-bit grayscale (12-bit data)
- Filenames should follow the PamGene naming convention
- ZIP archives must contain `ImageResults/` directory

### 11.2 Browser Constraints

- Modern browsers with JavaScript enabled
- Sufficient memory for image processing
- WebAssembly support (for Flutter web)

### 11.3 Tercen Integration Constraints

- Valid Tercen session required
- documentId must reference accessible file
- Appropriate permissions for file access
