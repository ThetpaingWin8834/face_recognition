class ExifTags {
  /// Main EXIF IFD Tags (0x0100 - 0x01FF)
  static const Map<int, String> exifIfdTags = {
    0x0100: 'ImageWidth',
    0x0101: 'ImageLength',
    0x0102: 'BitsPerSample',
    0x0103: 'Compression',
    0x0106: 'PhotometricInterpretation',
    0x010A: 'FillOrder',
    0x010D: 'DocumentName',
    0x010E: 'ImageDescription',
    0x010F: 'Make',
    0x0110: 'Model',
    0x0111: 'StripOffsets',
    0x0112: 'Orientation',
    0x0115: 'SamplesPerPixel',
    0x0116: 'RowsPerStrip',
    0x0117: 'StripByteCounts',
    0x011A: 'XResolution',
    0x011B: 'YResolution',
    0x011C: 'PlanarConfiguration',
    0x011D: 'PageName',
    0x0120: 'FreeOffsets',
    0x0121: 'FreeByteCounts',
    0x0122: 'GrayResponseUnit',
    0x0123: 'GrayResponseCurve',
    0x0124: 'T4Options',
    0x0125: 'T6Options',
    0x0128: 'ResolutionUnit',
    0x012D: 'TransferFunction',
    0x0131: 'Software',
    0x0132: 'DateTime',
    0x013B: 'Artist',
    0x013C: 'HostComputer',
    0x013D: 'Predictor',
    0x013E: 'WhitePoint',
    0x013F: 'PrimaryChromaticities',
    0x0140: 'ColorMap',
    0x0141: 'HalftoneHints',
    0x0142: 'TileWidth',
    0x0143: 'TileLength',
    0x0144: 'TileOffsets',
    0x0145: 'TileByteCounts',
    0x014A: 'SubIFDs',
    0x014C: 'InkSet',
    0x014D: 'InkNames',
    0x014E: 'NumberOfInks',
    0x0150: 'DotRange',
    0x0151: 'TargetPrinter',
    0x0152: 'ExtraSamples',
    0x0153: 'SampleFormat',
    0x0154: 'SMinSampleValue',
    0x0155: 'SMaxSampleValue',
    0x0156: 'TransferRange',
    0x0157: 'ClipPath',
    0x0158: 'XClipPathUnits',
    0x0159: 'YClipPathUnits',
    0x015A: 'Indexed',
    0x015B: 'JPEGTables',
    0x015F: 'OPIProxy',
    0x0200: 'JPEGProc',
    0x0201: 'JPEGInterchangeFormat',
    0x0202: 'JPEGInterchangeFormatLength',
    0x0203: 'JPEGRestartInterval',
    0x0205: 'JPEGLosslessPredictors',
    0x0206: 'JPEGPointTransforms',
    0x0207: 'JPEGQTables',
    0x0208: 'JPEGDCTables',
    0x0209: 'JPEGACTables',
    0x0211: 'YCbCrCoefficients',
    0x0212: 'YCbCrSubSampling',
    0x0213: 'YCbCrPositioning',
    0x0214: 'ReferenceBlackWhite',
    0x02BC: 'XMLPacket',
  };

  /// EXIF Private Tags (0x8769 - 0x8825)
  static const Map<int, String> exifPrivateTags = {
    0x8769: 'ExifIFDPointer',
    0x8773: 'ICCProfile',
    0x8822: 'ExposureTime',
    0x8824: 'FNumber',
    0x8825: 'ExposureProgram',
    0x8827: 'ISOSpeedRatings',
    0x8828: 'ExifVersion',
    0x8829: 'DateTimeOriginal',
    0x882A: 'DateTimeDigitized',
    0x882B: 'ComponentsConfiguration',
    0x882C: 'CompressedBitsPerPixel',
    0x8830: 'ShutterSpeedValue',
    0x8831: 'ApertureValue',
    0x8832: 'BrightnessValue',
    0x8833: 'ExposureBiasValue',
    0x8834: 'MaxApertureValue',
    0x8835: 'SubjectDistance',
    0x8836: 'MeteringMode',
    0x8837: 'LightSource',
    0x8838: 'Flash',
    0x8839: 'FocalLength',
    0x883A: 'MakerNote',
    0x883B: 'UserComment',
    0x883C: 'SubSecTime',
    0x883D: 'SubSecTimeOriginal',
    0x883E: 'SubSecTimeDigitized',
    0x8840: 'FlashpixVersion',
    0x8841: 'ColorSpace',
    0x8842: 'PixelXDimension',
    0x8843: 'PixelYDimension',
    0x8844: 'RelatedSoundFile',
    0x8845: 'InteroperabilityIFDPointer',
    0x8846: 'FlashEnergy',
    0x8847: 'SpatialFrequencyResponse',
    0x8848: 'FocalPlaneXResolution',
    0x8849: 'FocalPlaneYResolution',
    0x884A: 'FocalPlaneResolutionUnit',
    0x884B: 'SubjectLocation',
    0x884C: 'ExposureIndex',
    0x884D: 'SensingMethod',
    0x8850: 'FileSource',
    0x8851: 'SceneType',
    0x8852: 'CFAPattern',
    0x8853: 'CustomRendered',
    0x8854: 'ExposureMode',
    0x8855: 'WhiteBalance',
    0x8856: 'DigitalZoomRatio',
    0x8857: 'FocalLengthIn35mmFilm',
    0x8858: 'SceneCaptureType',
    0x8859: 'GainControl',
    0x885A: 'Contrast',
    0x885B: 'Saturation',
    0x885C: 'Sharpness',
    0x885D: 'DeviceSettingDescription',
    0x885E: 'SubjectDistanceRange',
    0x885F: 'ImageUniqueID',
    0x927C: 'MakerNote',
    0x9286: 'UserComment',
  };

  /// GPS Info Tags (0x0000 - 0x001F)
  static const Map<int, String> gpsTags = {
    0x0000: 'GPSVersionID',
    0x0001: 'GPSLatitudeRef',
    0x0002: 'GPSLatitude',
    0x0003: 'GPSLongitudeRef',
    0x0004: 'GPSLongitude',
    0x0005: 'GPSAltitudeRef',
    0x0006: 'GPSAltitude',
    0x0007: 'GPSTimeStamp',
    0x0008: 'GPSSatellites',
    0x0009: 'GPSStatus',
    0x000A: 'GPSMeasureMode',
    0x000B: 'GPSDOP',
    0x000C: 'GPSSpeedRef',
    0x000D: 'GPSSpeed',
    0x000E: 'GPSTrackRef',
    0x000F: 'GPSTrack',
    0x0010: 'GPSImgDirectionRef',
    0x0011: 'GPSImgDirection',
    0x0012: 'GPSMapDatum',
    0x0013: 'GPSDestLatitudeRef',
    0x0014: 'GPSDestLatitude',
    0x0015: 'GPSDestLongitudeRef',
    0x0016: 'GPSDestLongitude',
    0x0017: 'GPSDestBearingRef',
    0x0018: 'GPSDestBearing',
    0x0019: 'GPSDestDistanceRef',
    0x001A: 'GPSDestDistance',
    0x001B: 'GPSProcessingMethod',
    0x001C: 'GPSAreaInformation',
    0x001D: 'GPSDateStamp',
    0x001E: 'GPSDifferential',
  };

  /// Interoperability Tags
  static const Map<int, String> interoperabilityTags = {
    0x0001: 'InteroperabilityIndex',
    0x0002: 'InteroperabilityVersion',
    0x1000: 'RelatedImageFileFormat',
    0x1001: 'RelatedImageWidth',
    0x1002: 'RelatedImageLength',
  };

  /// Get tag name from ID
  static String? getTagName(int tagId) {
    return exifIfdTags[tagId] ??
        exifPrivateTags[tagId] ??
        gpsTags[tagId] ??
        interoperabilityTags[tagId];
  }

  /// Get all tags with their IDs and names
  static Map<int, String> getAllTags() {
    return {
      ...exifIfdTags,
      ...exifPrivateTags,
      ...gpsTags,
      ...interoperabilityTags,
    };
  }

  /// Get tag category
  static String getTagCategory(int tagId) {
    if (exifIfdTags.containsKey(tagId)) return 'EXIF_IFD';
    if (exifPrivateTags.containsKey(tagId)) return 'EXIF_Private';
    if (gpsTags.containsKey(tagId)) return 'GPS';
    if (interoperabilityTags.containsKey(tagId)) return 'Interoperability';
    return 'Unknown';
  }

  /// Common important tags with descriptions
  static const Map<int, Map<String, dynamic>> importantTags = {
    0x010F: {'name': 'Make', 'description': 'Camera manufacturer'},
    0x0110: {'name': 'Model', 'description': 'Camera model'},
    0x0112: {'name': 'Orientation', 'description': 'Image orientation'},
    0x0131: {'name': 'Software', 'description': 'Software used'},
    0x0132: {'name': 'DateTime', 'description': 'File modification date/time'},
    0x8769: {'name': 'ExifIFDPointer', 'description': 'Pointer to EXIF data'},
    0x8822: {'name': 'ExposureTime', 'description': 'Exposure time in seconds'},
    0x8824: {'name': 'FNumber', 'description': 'F-number'},
    0x8827: {'name': 'ISOSpeedRatings', 'description': 'ISO speed'},
    0x8829: {'name': 'DateTimeOriginal', 'description': 'Original date/time'},
    0x882A: {'name': 'DateTimeDigitized', 'description': 'Digitized date/time'},
    0x8830: {'name': 'ShutterSpeedValue', 'description': 'Shutter speed'},
    0x8831: {'name': 'ApertureValue', 'description': 'Aperture value'},
    0x8832: {'name': 'BrightnessValue', 'description': 'Brightness value'},
    0x8833: {'name': 'ExposureBiasValue', 'description': 'Exposure bias'},
    0x8834: {'name': 'MaxApertureValue', 'description': 'Maximum aperture'},
    0x8835: {'name': 'SubjectDistance', 'description': 'Subject distance'},
    0x8836: {'name': 'MeteringMode', 'description': 'Metering mode'},
    0x8837: {'name': 'LightSource', 'description': 'Light source'},
    0x8838: {'name': 'Flash', 'description': 'Flash settings'},
    0x8839: {'name': 'FocalLength', 'description': 'Focal length'},
    0x9201: {'name': 'ShutterSpeedValue', 'description': 'Shutter speed'},
    0x9202: {'name': 'ApertureValue', 'description': 'Aperture value'},
    0x9203: {'name': 'BrightnessValue', 'description': 'Brightness value'},
    0x9204: {'name': 'ExposureBiasValue', 'description': 'Exposure bias'},
    0x9205: {'name': 'MaxApertureValue', 'description': 'Maximum aperture'},
    0x9206: {'name': 'SubjectDistance', 'description': 'Subject distance'},
    0x9207: {'name': 'MeteringMode', 'description': 'Metering mode'},
    0x9208: {'name': 'LightSource', 'description': 'Light source'},
    0x9209: {'name': 'Flash', 'description': 'Flash settings'},
  };
}

class ExifTagProcessor {
  /// Convert raw EXIF data to readable format
  static Map<String, dynamic> processExifData(Map<int, dynamic> rawExif) {
    final processed = <String, dynamic>{};
    
    rawExif.forEach((tagId, value) {
      final tagName = ExifTags.getTagName(tagId);
      if (tagName != null) {
        processed[tagName] = _processTagValue(tagId, value);
      } else {
        processed['Unknown_0x${tagId.toRadixString(16).toUpperCase().padLeft(4, '0')}'] = value;
      }
    });
    
    return processed;
  }

  /// Process specific tag values to human-readable format
  static dynamic _processTagValue(int tagId, dynamic value) {
    switch (tagId) {
      case 0x0112: // Orientation
        return _parseOrientation(value);
      case 0x8825: // ExposureProgram
        return _parseExposureProgram(value);
      case 0x8836: // MeteringMode
        return _parseMeteringMode(value);
      case 0x8837: // LightSource
        return _parseLightSource(value);
      case 0x8838: // Flash
        return _parseFlash(value);
      case 0x9208: // LightSource (alternative)
        return _parseLightSource(value);
      case 0x9209: // Flash (alternative)
        return _parseFlash(value);
      case 0x0001: // GPSLatitudeRef, GPSLongitudeRef
      case 0x0003:
        return value is String ? value : value.toString();
      case 0x0002: // GPSLatitude
      case 0x0004: // GPSLongitude
        return _parseGpsCoordinates(value);
      default:
        return value;
    }
  }

  static String _parseOrientation(dynamic value) {
    final orientations = {
      1: 'Horizontal (normal)',
      2: 'Mirror horizontal',
      3: 'Rotate 180°',
      4: 'Mirror vertical',
      5: 'Mirror horizontal and rotate 270° CW',
      6: 'Rotate 90° CW',
      7: 'Mirror horizontal and rotate 90° CW',
      8: 'Rotate 270° CW',
    };
    return orientations[value] ?? 'Unknown ($value)';
  }

  static String _parseExposureProgram(dynamic value) {
    final programs = {
      0: 'Not defined',
      1: 'Manual',
      2: 'Normal program',
      3: 'Aperture priority',
      4: 'Shutter priority',
      5: 'Creative program',
      6: 'Action program',
      7: 'Portrait mode',
      8: 'Landscape mode',
    };
    return programs[value] ?? 'Unknown ($value)';
  }

  static String _parseMeteringMode(dynamic value) {
    final modes = {
      0: 'Unknown',
      1: 'Average',
      2: 'CenterWeightedAverage',
      3: 'Spot',
      4: 'MultiSpot',
      5: 'Pattern',
      6: 'Partial',
      255: 'Other',
    };
    return modes[value] ?? 'Unknown ($value)';
  }

  static String _parseLightSource(dynamic value) {
    final sources = {
      0: 'Unknown',
      1: 'Daylight',
      2: 'Fluorescent',
      3: 'Tungsten (incandescent light)',
      4: 'Flash',
      9: 'Fine weather',
      10: 'Cloudy weather',
      11: 'Shade',
      12: 'Daylight fluorescent (D 5700 - 7100K)',
      13: 'Day white fluorescent (N 4600 - 5400K)',
      14: 'Cool white fluorescent (W 3900 - 4500K)',
      15: 'White fluorescent (WW 3200 - 3700K)',
      17: 'Standard light A',
      18: 'Standard light B',
      19: 'Standard light C',
      20: 'D55',
      21: 'D65',
      22: 'D75',
      23: 'D50',
      24: 'ISO studio tungsten',
      255: 'Other',
    };
    return sources[value] ?? 'Unknown ($value)';
  }

  static String _parseFlash(dynamic value) {
    final flashValues = {
      0x0000: 'Flash did not fire',
      0x0001: 'Flash fired',
      0x0005: 'Strobe return light not detected',
      0x0007: 'Strobe return light detected',
      0x0009: 'Flash fired, compulsory flash mode',
      0x000D: 'Flash fired, compulsory flash mode, return light not detected',
      0x000F: 'Flash fired, compulsory flash mode, return light detected',
      0x0010: 'Flash did not fire, compulsory flash mode',
      0x0018: 'Flash did not fire, auto mode',
      0x0019: 'Flash fired, auto mode',
      0x001D: 'Flash fired, auto mode, return light not detected',
      0x001F: 'Flash fired, auto mode, return light detected',
      0x0020: 'No flash function',
      0x0041: 'Flash fired, red-eye reduction mode',
      0x0045: 'Flash fired, red-eye reduction mode, return light not detected',
      0x0047: 'Flash fired, red-eye reduction mode, return light detected',
      0x0049: 'Flash fired, compulsory flash mode, red-eye reduction mode',
      0x004D: 'Flash fired, compulsory flash mode, red-eye reduction mode, return light not detected',
      0x004F: 'Flash fired, compulsory flash mode, red-eye reduction mode, return light detected',
      0x0059: 'Flash fired, auto mode, red-eye reduction mode',
      0x005D: 'Flash fired, auto mode, return light not detected, red-eye reduction mode',
      0x005F: 'Flash fired, auto mode, return light detected, red-eye reduction mode',
    };
    return flashValues[value] ?? 'Unknown ($value)';
  }

  static String _parseGpsCoordinates(dynamic value) {
    if (value is List && value.length == 3) {
      final deg = value[0]?.toDouble() ?? 0;
      final min = value[1]?.toDouble() ?? 0;
      final sec = value[2]?.toDouble() ?? 0;
      return '$deg° $min\' ${sec.toStringAsFixed(2)}"';
    }
    return value.toString();
  }
}