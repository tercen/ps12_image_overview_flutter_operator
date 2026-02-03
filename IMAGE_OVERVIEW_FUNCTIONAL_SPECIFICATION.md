# PS12 Image Overview - Functional Specification

**Version:** 1.0.0
**Status:** Active
**Last Updated:** 2026-01-28

---

## 1. Overview

### 1.1 Purpose

A **view-only quality control (QC) operator** for visual inspection of PS12 kinase assay fluorescence images. Operators use this tool to visually review images for quality issues before downstream analysis.

### 1.2 Migration Context

This Flutter operator replaces the existing `ps12image_overview_shiny_pg` R/Shiny implementation due to Tercen's deprecation of Shiny support. The Flutter version maintains 100% feature parity with the Shiny version.

**Source Implementation:** https://github.com/tercen/ps12image_overview_shiny_pg

### 1.3 Scope

**In Scope:**
- Display fluorescence images in a grid layout
- Filter images by Cycle and Exposure Time
- View full-size images with zoom/pan
- Display image metadata

**Out of Scope:**
- QC flagging, annotations, or pass/fail marking
- Data export or output to Tercen
- State persistence between sessions
- Image editing or modification

---

## 2. Domain Context

### 2.1 PamStation 12 (PS12) Instrument

The PS12 is a fully automated kinase activity profiling system manufactured by PamGene (www.pamgene.com).

**Key Characteristics:**
- Processes PamChip microarrays (3 chips simultaneously = 12 arrays)
- PamChip types: PTK (196 peptides) and STK (144 peptides)
- 3D porous aluminium oxide structure with ~200nm capillaries
- Fluorescent detection (FITC for PTK, antibody mixture for STK)

### 2.2 Data Output

- **Fluorescence images** captured at regular intervals (typically every 5 minutes)
- **Time-series data** showing kinase activity progression
- **Real-time kinetic profiles** (not just endpoint measurements)
- Images from up to 12 arrays simultaneously

### 2.3 QC Use Case

Operators visually inspect images to identify:
- Uneven fluorescence distribution
- Air bubbles or artifacts
- Failed wells or arrays
- Anomalies in time-series progression

**Action on Issues:** Operators take manual action outside this application if flaws are identified. No flagging or annotation features are required.

---

## 3. Functional Requirements

### 3.1 Image Display

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-01 | Display images in a grid organized by Row (vertical) and Barcode (horizontal) | Must |
| FR-02 | Show image metadata (well, field, cycle, exposure time) with each image | Must |
| FR-03 | Support click-to-enlarge for full-size image viewing | Must |
| FR-04 | Provide zoom and pan controls in detail view | Must |
| FR-05 | Display column headers showing Barcode values | Should |
| FR-06 | Display row headers showing Row/Well numbers | Should |

### 3.2 Filtering

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-10 | Filter images by Cycle (pump cycle number) | Must |
| FR-11 | Filter images by Exposure Time (milliseconds) | Must |
| FR-12 | Default Cycle filter to latest (highest) cycle number | Must |
| FR-13 | Default Exposure Time filter to longest (highest) value | Must |
| FR-14 | Display filter options in ascending sorted order | Should |
| FR-15 | Apply filters with AND logic (both must match) | Must |

### 3.3 Data Loading

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-20 | Load images from Tercen via documentId reference | Must |
| FR-21 | Support ZIP archives containing TIFF images | Must |
| FR-22 | Extract metadata from TIFF EXIF tags | Must |
| FR-23 | Convert 12-bit TIFF to 8-bit PNG for display | Must |
| FR-24 | Handle missing or corrupted TIFF files gracefully | Must |

### 3.4 View-Only Behaviour

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-30 | Application must NOT write any output to Tercen | Must |
| FR-31 | Application must NOT persist state between sessions | Must |
| FR-32 | No selection, flagging, or annotation features | Must |

---

## 4. User Interface Components

This section describes the required UI components and their behaviours. Visual design (layout, styling, spacing) is defined in the tercen-style guidelines.

### 4.1 Main Screen

**Required Components:**

- Filter controls for Cycle and Exposure Time
- Image grid displaying thumbnails
- Grid organized: columns = unique Barcodes, rows = unique Rows/Wells

**Grid Cell Behaviour:**

- Each cell displays one image thumbnail
- Cell shows basic metadata (Well, Field identifiers)
- Click on cell opens detail view

**Grid Sizing Behaviour:**

- Images must maintain original aspect ratio (no distortion)
- Images should be sized as large as possible within their cells
- All 4 rows of the grid must be visible on screen without vertical scrolling
- Skills and style guides determine optimal cell dimensions to meet these constraints

### 4.2 Detail View

**Required Features:**

- Full-size image display
- Zoom capability (zoom in, zoom out, reset)
- Pan/drag to navigate zoomed image
- Complete metadata display
- Navigation back to main view

### 4.3 Filter Behaviour

**Cycle Filter:**

- Lists all unique cycle values from loaded images
- Values sorted ascending
- Default selection: highest (latest) cycle

**Exposure Time Filter:**

- Lists all unique exposure time values from loaded images
- Values sorted ascending
- Default selection: highest (longest) exposure time

---

## 5. Non-Functional Requirements

### 5.1 Performance

| ID | Requirement |
|----|-------------|
| NFR-01 | Initial load should complete within acceptable time for typical datasets |
| NFR-02 | Filter changes should update grid without full reload |
| NFR-03 | Image thumbnails should load progressively if needed |

### 5.2 Compatibility

| ID | Requirement |
|----|-------------|
| NFR-10 | Must run as a Tercen web operator |
| NFR-11 | Must support modern web browsers (Chrome, Firefox, Safari, Edge) |
| NFR-12 | Must work with existing PS12 data structure (no changes to Tercen data) |

### 5.3 Usability

| ID | Requirement |
|----|-------------|
| NFR-20 | Must maintain feature parity with Shiny version |
| NFR-21 | Must preserve existing user workflows |
| NFR-22 | Loading states should be clearly indicated |
| NFR-23 | Errors should be displayed with actionable messages |

---

## 6. Feature Comparison (Shiny vs Flutter)

| Feature | Shiny (Original) | Flutter (This App) |
|---------|------------------|-------------------|
| Grid layout (Row × Barcode) | Yes | Yes |
| Cycle filter | Yes | Yes |
| Exposure Time filter | Yes | Yes |
| Click to enlarge | Yes | Yes |
| Zoom/Pan controls | No | Yes (enhancement) |
| 12-bit → 8-bit conversion | Yes | Yes |
| TIFF EXIF parsing | Yes | Yes |
| Auto-refresh (30s) | Yes | No (not needed) |
| View-only (no output) | Yes | Yes |

---

## 7. Assumptions

1. Input data follows the standard PS12 TIFF file format with EXIF metadata
2. ZIP archives are structured with `ImageResults/` directory containing TIFF files
3. Users have appropriate Tercen permissions to access the data
4. Images are 12-bit grayscale TIFF format (stored in 16-bit container)
5. Typical datasets contain manageable number of images for web display
6. Mock data for development uses images extracted from production PamGene ZIP files (not screenshots)

---

## 8. Glossary

| Term | Definition |
|------|------------|
| Array | A single PamChip microarray unit |
| Barcode | Unique identifier for a PamChip plate (9-digit number) |
| Cycle | Pump cycle number during the assay (indicates time progression) |
| Exposure Time | Camera exposure duration in milliseconds |
| Field | Microscopy field of view position |
| PTK | Protein Tyrosine Kinase chip type (196 peptides) |
| STK | Serine/Threonine Kinase chip type (144 peptides) |
| Well | Position on the PamChip (typically W1-W4) |
| documentId | Tercen column reference pointing to ZIP file containing images |
