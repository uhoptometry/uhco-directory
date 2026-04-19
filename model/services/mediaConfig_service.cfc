component output="false" singleton {

    variables.publishedSiteBaseUrlKey = "media_published_site_base_url";
    variables.defaultPublishedSiteBaseUrl = "http://127.0.0.1/";
    variables.publishedImagesSegment = "_published_images/";

    public any function init() {
        variables.AppConfigService = createObject("component", "cfc.appConfig_service").init();
        return this;
    }

    public string function getPublishedSiteBaseUrl() {
        return _normalizeBaseUrl(
            variables.AppConfigService.getValue(
                configKey    = variables.publishedSiteBaseUrlKey,
                defaultValue = variables.defaultPublishedSiteBaseUrl
            )
        );
    }

    public void function setPublishedSiteBaseUrl( required string baseUrl ) {
        var normalized = _normalizeBaseUrl( arguments.baseUrl );

        if ( !reFindNoCase("^https?://", normalized) ) {
            throw(
                type = "MediaConfig.Validation",
                message = "Published site base URL must start with http:// or https://"
            );
        }

        variables.AppConfigService.setValue(
            configKey   = variables.publishedSiteBaseUrlKey,
            configValue = normalized
        );
    }

    public string function getPublishedImageBaseUrl() {
        return getPublishedSiteBaseUrl() & variables.publishedImagesSegment;
    }

    public string function buildPublishedUrl( required string filename ) {
        return getPublishedImageBaseUrl() & trim(arguments.filename);
    }

    public string function buildPublishedFilename(
        required struct user,
        required string variantCode,
        required string extension,
        numeric userImageSourceID = 0
    ) {
        var firstInitial = _sanitizeInitial( arguments.user.FIRSTNAME ?: "" );
        var middleInitial = _sanitizeInitial( arguments.user.MIDDLENAME ?: "" );
        var lastName = _sanitizeSegment( arguments.user.LASTNAME ?: "" );
        var safeVariant = lCase( reReplace(trim(arguments.variantCode), "[^a-zA-Z0-9_\-]", "_", "all") );
        var safeExtension = lCase( trim(arguments.extension) );
        var parts = [];

        if ( safeExtension EQ "jpeg" ) {
            safeExtension = "jpg";
        }

        if ( len(firstInitial) ) {
            arrayAppend(parts, firstInitial);
        }
        if ( len(middleInitial) ) {
            arrayAppend(parts, middleInitial);
        }
        if ( len(lastName) ) {
            arrayAppend(parts, lastName);
        }

        arrayAppend(parts, "u" & val(arguments.user.USERID ?: 0));

        if ( val(arguments.userImageSourceID) GT 0 ) {
            arrayAppend(parts, "src" & val(arguments.userImageSourceID));
        }

        arrayAppend(parts, safeVariant);

        return arrayToList(parts, "_") & "." & safeExtension;
    }

    private string function _normalizeBaseUrl( required string baseUrl ) {
        var normalized = trim(arguments.baseUrl);
        var scheme = "";
        var remainder = "";
        var schemePos = 0;

        if ( !len(normalized) ) {
            normalized = variables.defaultPublishedSiteBaseUrl;
        }

        normalized = replace(normalized, "\\", "/", "all");
        schemePos = find(":", normalized);

        if ( schemePos GT 0 ) {
            scheme = lCase( left(normalized, schemePos - 1) );

            if ( listFindNoCase("http,https", scheme) ) {
                remainder = mid(normalized, schemePos + 1, len(normalized));
                remainder = reReplace(remainder, "^/+", "", "one");
                remainder = reReplace(remainder, "/+", "/", "all");
                normalized = scheme & "://" & remainder;
            }
        }

        if ( reFindNoCase("^https?://", normalized) ) {
            scheme = lCase( listFirst(normalized, ":") );
            remainder = mid(normalized, len(scheme) + 4, len(normalized));
            remainder = reReplace(remainder, "/+", "/", "all");
            normalized = scheme & "://" & remainder;
        }

        if ( right(normalized, 1) NEQ "/" ) {
            normalized &= "/";
        }

        return normalized;
    }

    private string function _sanitizeInitial( required string rawValue ) {
        var sanitized = _sanitizeSegment( arguments.rawValue );
        return len(sanitized) ? left(sanitized, 1) : "";
    }

    private string function _sanitizeSegment( required string rawValue ) {
        return lCase( reReplace(trim(arguments.rawValue), "[^a-zA-Z0-9]", "", "all") );
    }

}