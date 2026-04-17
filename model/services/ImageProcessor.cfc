component output="false" singleton {

    /**
     * ImageProcessor.cfc
     *
     * Deterministic image derivation using native CFIMAGE APIs only.
     *
     * WEBP FUTURE SUPPORT NOTE
     * -------------------------------------------------------------------------
     * WebP is intentionally NOT supported in this component because this
     * application runs on Adobe ColdFusion 2021 and output support is limited
     * to JPG/PNG for now.
     *
     * This component is intentionally isolated so WebP can be added later when
     * running on CF 2025+; that support should be implemented here only.
     * -------------------------------------------------------------------------
     */

    public void function generateVariant(
        required string sourcePath,
        required string destinationPath,
        required struct variantDefinition,
        struct offsets   = {},
        struct cropRect  = {}
    ) {
        var normalizedOffsets = { x = 0, y = 0 };
        var sourceExt = "";
        var outputFormat = "";
        var destinationExt = "";
        var sourceImage = "";
        var sourceWidth = 0;
        var sourceHeight = 0;
        var targetWidth = 0;
        var targetHeight = 0;
        var scale = 1;
        var resizedWidth = 0;
        var resizedHeight = 0;
        var maxShiftX = 0;
        var maxShiftY = 0;
        var centerX = 0;
        var centerY = 0;
        var cropX = 0;
        var cropY = 0;
        var tempPath = "";
        var outputWidth = 0;
        var outputHeight = 0;
        var hasFixedWidth = false;
        var hasFixedHeight = false;

        try {
            _validateInputs(
                sourcePath = arguments.sourcePath,
                destinationPath = arguments.destinationPath,
                variantDefinition = arguments.variantDefinition
            );

            sourceExt = _normalizeExtension(arguments.sourcePath);
            if ( !listFindNoCase("jpg,jpeg,png", sourceExt) ) {
                throw(
                    type = "ImageProcessor.UnsupportedInputFormat",
                    message = "Unsupported source image format. Only JPG and PNG are allowed.",
                    detail = "Source extension: #sourceExt#"
                );
            }

            outputFormat = _normalizeExtension(arguments.variantDefinition.outputFormat);
            destinationExt = _normalizeExtension(arguments.destinationPath);

            if ( outputFormat EQ "jpeg" ) {
                outputFormat = "jpg";
            }
            if ( destinationExt EQ "jpeg" ) {
                destinationExt = "jpg";
            }

            if ( outputFormat NEQ destinationExt ) {
                throw(
                    type = "ImageProcessor.OutputFormatMismatch",
                    message = "Variant outputFormat must match destination file extension.",
                    detail = "outputFormat=#outputFormat#, destinationExt=#destinationExt#"
                );
            }

            // Enforce deterministic format rules from variant definition.
            if ( arguments.variantDefinition.allowTransparency ) {
                if ( outputFormat NEQ "png" ) {
                    throw(
                        type = "ImageProcessor.InvalidTransparencyFormat",
                        message = "Transparent variants must use PNG output.",
                        detail = "allowTransparency=true requires outputFormat=png"
                    );
                }
            } else {
                if ( outputFormat NEQ "jpg" ) {
                    throw(
                        type = "ImageProcessor.InvalidTransparencyFormat",
                        message = "Non-transparent variants must use JPG output.",
                        detail = "allowTransparency=false requires outputFormat=jpg"
                    );
                }
            }

            // Processing order (mandatory): read -> resize -> crop -> write.
            // CFIMAGE read step normalizes orientation metadata handling.
            sourceImage = imageRead(arguments.sourcePath);
            sourceWidth = imageGetWidth(sourceImage);
            sourceHeight = imageGetHeight(sourceImage);

            if ( sourceWidth LTE 0 OR sourceHeight LTE 0 ) {
                throw(
                    type = "ImageProcessor.InvalidSourceDimensions",
                    message = "Source image has invalid dimensions.",
                    detail = "width=#sourceWidth#, height=#sourceHeight#"
                );
            }

            // ── Pre-crop ──────────────────────────────────────────────────────
            // When the caller supplies a crop rectangle (in source-image pixels),
            // crop the source to that region before any resize.  The downstream
            // resize logic then operates on the cropped area as though it were
            // the original source, producing a clean crop → resize → write pipeline.
            if ( _isValidCropRect(arguments.cropRect, sourceWidth, sourceHeight) ) {
                var preCropX = int(max(val(arguments.cropRect.x), 0));
                var preCropY = int(max(val(arguments.cropRect.y), 0));
                var preCropW = int(min(val(arguments.cropRect.width),  sourceWidth  - preCropX));
                var preCropH = int(min(val(arguments.cropRect.height), sourceHeight - preCropY));

                if ( preCropW GT 0 AND preCropH GT 0 ) {
                    imageCrop(sourceImage, preCropX, preCropY, preCropW, preCropH);
                    sourceWidth  = imageGetWidth(sourceImage);
                    sourceHeight = imageGetHeight(sourceImage);
                }
            }

            hasFixedWidth = structKeyExists(arguments.variantDefinition, "width")
                AND isNumeric(arguments.variantDefinition.width)
                AND int(arguments.variantDefinition.width) GT 0;
            hasFixedHeight = structKeyExists(arguments.variantDefinition, "height")
                AND isNumeric(arguments.variantDefinition.height)
                AND int(arguments.variantDefinition.height) GT 0;

            // Dimension handling:
            //   - fixed box: outputWidth and outputHeight come directly from the type
            //   - width-only: resize to width; outputHeight is derived from source aspect ratio
            //   - height-only: resize to height; outputWidth is derived from source aspect ratio
            if ( hasFixedWidth AND hasFixedHeight ) {
                outputWidth = int(arguments.variantDefinition.width);
                outputHeight = int(arguments.variantDefinition.height);
                scale = max(outputWidth / sourceWidth, outputHeight / sourceHeight);
            } else if ( hasFixedWidth ) {
                outputWidth = int(arguments.variantDefinition.width);
                scale = outputWidth / sourceWidth;
                outputHeight = ceiling(sourceHeight * scale);
            } else {
                outputHeight = int(arguments.variantDefinition.height);
                scale = outputHeight / sourceHeight;
                outputWidth = ceiling(sourceWidth * scale);
            }

            resizedWidth = ceiling(sourceWidth * scale);
            resizedHeight = ceiling(sourceHeight * scale);

            imageResize(sourceImage, resizedWidth, resizedHeight, "highestQuality");

            // Framing math:
            // The output box is fixed by the variant definition.  Admins do not choose
            // a crop size; they only bias where that fixed box is centered within the
            // resized image.  Resize always happens before crop.
            normalizedOffsets = _normalizeOffsets(arguments.offsets);
            maxShiftX = (resizedWidth - outputWidth) / 2;
            maxShiftY = (resizedHeight - outputHeight) / 2;

            centerX = (resizedWidth / 2) + (maxShiftX * (normalizedOffsets.x / 100));
            centerY = (resizedHeight / 2) + (maxShiftY * (normalizedOffsets.y / 100));

            cropX = int(round(centerX - (outputWidth / 2)));
            cropY = int(round(centerY - (outputHeight / 2)));

            cropX = int(_clamp(cropX, 0, resizedWidth - outputWidth));
            cropY = int(_clamp(cropY, 0, resizedHeight - outputHeight));

            _validateOutputBounds(
                cropX         = cropX,
                cropY         = cropY,
                outputWidth   = outputWidth,
                outputHeight  = outputHeight,
                resizedWidth  = resizedWidth,
                resizedHeight = resizedHeight
            );

            imageCrop(sourceImage, cropX, cropY, outputWidth, outputHeight);

            tempPath = _buildTempPath(arguments.destinationPath, outputFormat);

            // Write exactly one final output by staging to temp then moving.
            // This avoids leaving a partially written destination on failure.
            if ( outputFormat EQ "jpg" ) {
                cfimage(
                    action = "write",
                    source = sourceImage,
                    destination = tempPath,
                    overwrite = true,
                    quality = 0.75
                );
            } else {
                // PNG path keeps alpha channel; no transparency flattening.
                cfimage(
                    action = "write",
                    source = sourceImage,
                    destination = tempPath,
                    overwrite = true
                );
            }

            if ( !fileExists(tempPath) ) {
                throw(
                    type = "ImageProcessor.WriteFailed",
                    message = "Image write failed before final move.",
                    detail = "Temporary output was not created."
                );
            }

            if ( fileExists(arguments.destinationPath) ) {
                fileDelete(arguments.destinationPath);
            }

            fileMove(tempPath, arguments.destinationPath);

        } catch (any e) {
            if ( len(tempPath) AND fileExists(tempPath) ) {
                try {
                    fileDelete(tempPath);
                } catch (any cleanupError) {
                    // Cleanup failure should not hide the original processing error.
                }
            }

            throw(
                type = structKeyExists(e, "type") ? e.type : "ImageProcessor.GenerateVariantFailed",
                message = "Image variant generation failed: #e.message#",
                detail = structKeyExists(e, "detail") ? e.detail : ""
            );
        }
    }

    private void function _validateInputs(
        required string sourcePath,
        required string destinationPath,
        required struct variantDefinition
    ) {
        var destinationDirectory = getDirectoryFromPath(arguments.destinationPath);

        if ( !len(trim(arguments.sourcePath)) ) {
            throw(type = "ImageProcessor.Validation", message = "sourcePath is required.");
        }
        if ( !len(trim(arguments.destinationPath)) ) {
            throw(type = "ImageProcessor.Validation", message = "destinationPath is required.");
        }
        if ( !fileExists(arguments.sourcePath) ) {
            throw(type = "ImageProcessor.Validation", message = "Source file does not exist: #arguments.sourcePath#");
        }
        if ( !directoryExists(destinationDirectory) ) {
            throw(type = "ImageProcessor.Validation", message = "Destination directory does not exist: #destinationDirectory#");
        }

        var hasWidth = structKeyExists(arguments.variantDefinition, "width")
            AND isNumeric(arguments.variantDefinition.width)
            AND int(arguments.variantDefinition.width) GT 0;
        var hasHeight = structKeyExists(arguments.variantDefinition, "height")
            AND isNumeric(arguments.variantDefinition.height)
            AND int(arguments.variantDefinition.height) GT 0;

        if ( structKeyExists(arguments.variantDefinition, "width")
             AND len(trim(arguments.variantDefinition.width & ""))
             AND (NOT isNumeric(arguments.variantDefinition.width) OR int(arguments.variantDefinition.width) LTE 0) ) {
            throw(type = "ImageProcessor.Validation", message = "variantDefinition.width must be a positive number when supplied.");
        }
        if ( structKeyExists(arguments.variantDefinition, "height")
             AND len(trim(arguments.variantDefinition.height & ""))
             AND (NOT isNumeric(arguments.variantDefinition.height) OR int(arguments.variantDefinition.height) LTE 0) ) {
            throw(type = "ImageProcessor.Validation", message = "variantDefinition.height must be a positive number when supplied.");
        }
        if ( NOT hasWidth AND NOT hasHeight ) {
            throw(type = "ImageProcessor.Validation", message = "variantDefinition must include at least one positive dimension (width or height).");
        }
        if ( !structKeyExists(arguments.variantDefinition, "outputFormat") OR !len(trim(arguments.variantDefinition.outputFormat)) ) {
            throw(type = "ImageProcessor.Validation", message = "variantDefinition.outputFormat is required (jpg or png).");
        }
        if ( !structKeyExists(arguments.variantDefinition, "allowTransparency") OR !isBoolean(arguments.variantDefinition.allowTransparency) ) {
            throw(type = "ImageProcessor.Validation", message = "variantDefinition.allowTransparency must be boolean.");
        }

        if ( !listFindNoCase("jpg,jpeg,png", arguments.variantDefinition.outputFormat) ) {
            throw(type = "ImageProcessor.Validation", message = "variantDefinition.outputFormat must be jpg or png.");
        }
    }

    private struct function _normalizeOffsets( struct offsets = {} ) {
        var x = 0;
        var y = 0;

        if ( structKeyExists(arguments.offsets, "x") ) {
            if ( !isNumeric(arguments.offsets.x) ) {
                throw(type = "ImageProcessor.InvalidFrameData", message = "Frame offset x must be numeric.");
            }
            x = val(arguments.offsets.x);
        }
        if ( structKeyExists(arguments.offsets, "y") ) {
            if ( !isNumeric(arguments.offsets.y) ) {
                throw(type = "ImageProcessor.InvalidFrameData", message = "Frame offset y must be numeric.");
            }
            y = val(arguments.offsets.y);
        }

        return {
            x = _clamp(x, -100, 100),
            y = _clamp(y, -100, 100)
        };
    }

    /**
     * Return true when cropRect contains four valid positive-dimension
     * coordinates.  Does NOT require the rect to be fully inside the source;
     * the caller clamps before use.
     */
    private boolean function _isValidCropRect(
        struct  cropRect     = {},
        numeric sourceWidth  = 0,
        numeric sourceHeight = 0
    ) {
        if ( !structKeyExists(arguments.cropRect, "x")
             OR !structKeyExists(arguments.cropRect, "y")
             OR !structKeyExists(arguments.cropRect, "width")
             OR !structKeyExists(arguments.cropRect, "height") ) {
            return false;
        }
        if ( !isNumeric(arguments.cropRect.x)
             OR !isNumeric(arguments.cropRect.y)
             OR !isNumeric(arguments.cropRect.width)
             OR !isNumeric(arguments.cropRect.height) ) {
            return false;
        }
        return val(arguments.cropRect.width) GT 0 AND val(arguments.cropRect.height) GT 0;
    }

    private numeric function _clamp(
        required numeric value,
        required numeric minValue,
        required numeric maxValue
    ) {
        if ( arguments.value LT arguments.minValue ) {
            return arguments.minValue;
        }
        if ( arguments.value GT arguments.maxValue ) {
            return arguments.maxValue;
        }
        return arguments.value;
    }

    private string function _normalizeExtension( required string pathOrExtension ) {
        var raw = lCase(trim(arguments.pathOrExtension));
        if ( find(".", raw) ) {
            raw = listLast(raw, ".");
        }
        return raw;
    }

    private string function _buildTempPath(
        required string destinationPath,
        required string outputFormat
    ) {
        var directoryPath = getDirectoryFromPath(arguments.destinationPath);
        return directoryPath & "__imgproc_tmp_" & createUUID() & "." & arguments.outputFormat;
    }

    /**
     * Validates that the fixed output frame fits entirely within the resized image.
     *
     * Framing never changes the output box size.  It only biases where that box is
     * placed, then clamps the origin to stay inside the resized image.
     */
    private void function _validateOutputBounds(
        required numeric cropX,
        required numeric cropY,
        required numeric outputWidth,
        required numeric outputHeight,
        required numeric resizedWidth,
        required numeric resizedHeight
    ) {
        if ( arguments.outputWidth LTE 0 OR arguments.outputHeight LTE 0 ) {
            throw(
                type    = "ImageProcessor.InvalidVariantDimensions",
                message = "Final output dimensions must both be positive.",
                detail  = "outputWidth=#arguments.outputWidth#, outputHeight=#arguments.outputHeight#"
            );
        }
        if ( arguments.cropX LT 0 OR arguments.cropY LT 0 ) {
            throw(
                type    = "ImageProcessor.CropOutOfBounds",
                message = "Computed frame origin is outside the resized image.",
                detail  = "cropX=#arguments.cropX#, cropY=#arguments.cropY#"
            );
        }
        if ( (arguments.cropX + arguments.outputWidth) GT arguments.resizedWidth ) {
            throw(
                type    = "ImageProcessor.CropOutOfBounds",
                message = "Framed output exceeds the right edge of the resized image.",
                detail  = "cropX=#arguments.cropX# + outputWidth=#arguments.outputWidth# exceeds resizedWidth=#arguments.resizedWidth#"
            );
        }
        if ( (arguments.cropY + arguments.outputHeight) GT arguments.resizedHeight ) {
            throw(
                type    = "ImageProcessor.CropOutOfBounds",
                message = "Framed output exceeds the bottom edge of the resized image.",
                detail  = "cropY=#arguments.cropY# + outputHeight=#arguments.outputHeight# exceeds resizedHeight=#arguments.resizedHeight#"
            );
        }
    }

}
