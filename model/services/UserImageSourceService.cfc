/**
 * UserImageSourceService.cfc
 *
 * Responsible for: business rules, source validation, and the file-provider abstraction.
 *
 * ╔══════════════════════════════════════════════════════════════════
 *   DROPBOX SWAP POINT — overview                                   
 *                                                                   
 *   All filesystem logic is confined to three private methods:      
 *     _listProviderFiles()   — enumerate available source images    
 *     _resolveProviderPath() — turn a logical path into a real one  
 *     _isValidProviderPath() — validate a submitted SourcePath      
 *                                                                   
 *   To replace the local folder with Dropbox:                       
 *     1. Swap these three methods for Dropbox API equivalents.      
 *     2. Change variables.localSourceDir to a Dropbox folder ID.    
 *     3. No other files (DAO, page, UI) need to change.             
 * ══════════════════════════════════════════════════════════════════
 */
component output="false" singleton {

    // ── POC: local source directory ──────────────────────────────────────────
    // DROPBOX SWAP POINT: replace this path with a Dropbox folder reference.
    variables.localSourceDir    = "/_temp_source/";
    variables.allowedExtensions = ["jpg", "jpeg", "png"];

    // Recognised SourceKey values.  Add or load from DB as needed.
    variables.sourceKeys = ["profile", "alumni", "dean", "marketing"];


    public any function init() {
        variables.SourceDAO      = createObject("component", "dao.UserImageSourceDAO").init();
        variables.VariantDAO     = createObject("component", "dao.UserImageVariantDAO").init();
        variables.PatternDAO     = createObject("component", "dao.FileNamePatternDAO").init();
        variables.ImagesDAO      = createObject("component", "dao.images_DAO").init();

        // Compute the absolute disk path to the local source folder from the CFC's
        // own location.  expandPath("/...") resolves against the IIS site root, not
        // the application root, so it cannot be used here reliably.
        // getCurrentTemplatePath() always returns this CFC's absolute path on disk.
        // getCanonicalPath() resolves ".." so directoryExists/directoryList never
        // receive a dotted path, which some CF engines reject.
        var cfc_dir   = getDirectoryFromPath( getCurrentTemplatePath() );
        var rawPath   = cfc_dir & "..\_temp_source";
        var canonical = createObject("java", "java.io.File").init( rawPath ).getCanonicalPath();
        variables.localSourceDirAbsolute = canonical & "\";

        return this;
    }


    // ── Public: configuration helpers ────────────────────────────────────────

    /**
     * Returns a single source record by its primary key.
     * Returns an empty struct if not found.
     */
    public struct function getSourceByID( required numeric sourceID ) {
        return variables.SourceDAO.getSourceByID( arguments.sourceID );
    }

    /**
     * Returns the list of valid SourceKey values for UI dropdowns.
     */
    public array function getSourceKeys() {
        return variables.sourceKeys;
    }

    /**
     * Returns an array of structs representing available source images.
     *   { filename: string, path: string }
     *
     * Page receives this structured data — no filesystem access in the page.
     *
     * DROPBOX SWAP POINT: replace _listProviderFiles() to call Dropbox list API.
     */
    public array function getAvailableFiles() {
        return _listProviderFiles();
    }

    /**
     * Returns available source images filtered to files whose names match
     * the user's identity tokens: name combinations and external IDs.
     *
     * Patterns are loaded from the FileNamePatterns table and resolved
     * against user fields.  External ID values are always included as
     * literal tokens.
     *
     * Falls back to all files when no tokens can be built.
     *
     * @firstName   User's first name
     * @lastName    User's last name
     * @middleName  User's middle name (optional)
     * @externalIDs Array of structs from externalID_service.getExternalIDs()
     *              Each struct has at minimum: EXTERNALVALUE
     */
    public array function getAvailableFilesForUser(
        required string firstName,
        required string lastName,
        string  middleName = "",
        required array  externalIDs
    ) {
        var allFiles = _listProviderFiles();
        var tokens   = _buildUserTokens( arguments.firstName, arguments.lastName, arguments.middleName, arguments.externalIDs );

        // No usable tokens — show everything so the admin is never stuck
        if ( !arrayLen(tokens) ) {
            return allFiles;
        }

        var matched = [];
        for ( var f in allFiles ) {
            if ( _filenameMatchesTokens( f.filename, tokens ) ) {
                arrayAppend( matched, f );
            }
        }

        // If nothing matched, fall back to all files so the page is never empty
        return arrayLen(matched) ? matched : allFiles;
    }


    // ── Public: CRUD operations ───────────────────────────────────────────────

    /**
     * Return all source records for a user.
     */
    public struct function getSourcesForUser( required numeric userID ) {
        return {
            success = true,
            data    = variables.SourceDAO.getSourcesForUser( arguments.userID )
        };
    }

    /**
     * Add a new image source for a user.
     * Marks any existing variants for the same user+sourceKey as STALE.
     */
    public struct function addSource(
        required numeric userID,
        required string  sourceKey,
        required string  sourcePath
    ) {
        var cleanKey  = trim( arguments.sourceKey );
        var cleanPath = trim( arguments.sourcePath );

        if ( !len(cleanKey) || !arrayFindNoCase(variables.sourceKeys, cleanKey) ) {
            return { success=false, message="Invalid source key." };
        }

        // DROPBOX SWAP POINT: _isValidProviderPath() validates against the local folder.
        // Replace with Dropbox file-metadata validation when switching providers.
        if ( !_isValidProviderPath(cleanPath) ) {
            return { success=false, message="Selected file is not a valid source image." };
        }

        var newID = variables.SourceDAO.insertSource({
            UserID     = arguments.userID,
            SourceKey  = cleanKey,
            SourcePath = cleanPath
        });

        // Side-effect: flag related variants as stale (explicit regeneration required).
        _markVariantsStale( arguments.userID, cleanKey );

        return { success=true, message="Image source added.", sourceID=newID };
    }

    /**
     * Update the SourceKey and SourcePath of an existing source.
     * Enforces ownership.  Marks related variants STALE.
     */
    public struct function updateSource(
        required numeric sourceID,
        required numeric userID,
        required string  sourceKey,
        required string  sourcePath
    ) {
        var existing = variables.SourceDAO.getSourceByID( arguments.sourceID );

        if ( structIsEmpty(existing) ) {
            return { success=false, message="Source record not found." };
        }

        // Ownership check: prevents editing another user's source via form manipulation.
        if ( val(existing.USERID) NEQ arguments.userID ) {
            return { success=false, message="Source does not belong to this user." };
        }

        var cleanKey  = trim( arguments.sourceKey );
        var cleanPath = trim( arguments.sourcePath );

        if ( !len(cleanKey) || !arrayFindNoCase(variables.sourceKeys, cleanKey) ) {
            return { success=false, message="Invalid source key." };
        }

        // DROPBOX SWAP POINT: same as addSource above.
        if ( !_isValidProviderPath(cleanPath) ) {
            return { success=false, message="Selected file is not a valid source image." };
        }

        variables.SourceDAO.updateSource( arguments.sourceID, {
            SourceKey  = cleanKey,
            SourcePath = cleanPath
        });

        // Mark variants stale after any source change.
        _markVariantsStale( arguments.userID, cleanKey );

        return { success=true, message="Image source updated." };
    }

    /**
     * Deactivate (soft-delete) a source.
     * Enforces ownership.  Marks related variants STALE.
     * Deletion is intentionally not supported — deactivation only.
     */
    public struct function deactivateSource(
        required numeric sourceID,
        required numeric userID
    ) {
        var existing = variables.SourceDAO.getSourceByID( arguments.sourceID );

        if ( structIsEmpty(existing) ) {
            return { success=false, message="Source record not found." };
        }

        if ( val(existing.USERID) NEQ arguments.userID ) {
            return { success=false, message="Source does not belong to this user." };
        }

        variables.SourceDAO.setActiveStatus( arguments.sourceID, false );

        // Mark variants stale when their source is deactivated.
        _markVariantsStale( arguments.userID, existing.SOURCEKEY );

        return { success=true, message="Image source deactivated." };
    }

    /**
     * Hard-delete a source record from the database.
     * Enforces ownership.  Marks related variants STALE before deletion.
     * NOTE: no file deletion occurs — only the DB record is removed.
     * This may be extended later (e.g. to remove files or Dropbox entries).
     */
    public struct function deleteSource(
        required numeric sourceID,
        required numeric userID
    ) {
        var existing = variables.SourceDAO.getSourceByID( arguments.sourceID );

        if ( structIsEmpty(existing) ) {
            return { success=false, message="Source record not found." };
        }

        if ( val(existing.USERID) NEQ arguments.userID ) {
            return { success=false, message="Source does not belong to this user." };
        }

        // Remove all published images and variant records that reference this source
        // before deleting it.  This satisfies the FK constraints on UserImages and
        // UserImageVariants that reference UserImageSources.
        variables.ImagesDAO.deleteBySourceID( arguments.sourceID );
        variables.VariantDAO.deleteVariantsBySourceID( arguments.sourceID );

        // Mark variants stale before the record is gone so the key is still known.
        _markVariantsStale( arguments.userID, existing.SOURCEKEY );

        variables.SourceDAO.deleteSource( arguments.sourceID );

        return { success=true, message="Image source deleted." };
    }


    // ── Private: file provider (POC = local filesystem) ──────────────────────
    //
    // DROPBOX SWAP POINT:
    //   All three methods below are the only things that change when Dropbox
    //   replaces the local folder.  The public interface above stays identical.

    /**
     * Enumerate files in the local source directory.
     * Returns array of { filename, path } structs.
     *
     * DROPBOX REPLACEMENT: call cfhttp to the Dropbox list_folder API,
     * parse the JSON entries, and return the same struct shape.
     */
    private array function _listProviderFiles() {
        var result      = [];
        var expandedDir = variables.localSourceDirAbsolute;

        if ( !directoryExists(expandedDir) ) {
            return result;
        }

        var files = directoryList( expandedDir, false, "query" );

        for ( var row in files ) {
            // directoryList type values are lowercase ("file" / "dir")
            if ( lCase(row.type) EQ "file" ) {
                var ext = lCase( listLast(row.name, ".") );
                if ( arrayFindNoCase(variables.allowedExtensions, ext) ) {
                    arrayAppend( result, {
                        filename = row.name,
                        path     = variables.localSourceDir & row.name
                    });
                }
            }
        }

        return result;
    }

    /**
     * Validate a SourcePath submitted from the form.
     * Guards against path-traversal and unknown files.
     *
     * DROPBOX REPLACEMENT: look up the path in the Dropbox file-metadata API
     * and confirm it exists and belongs to the expected folder.
     */
    private boolean function _isValidProviderPath( required string path ) {
        var p = trim( arguments.path );

        // Must start with the known local source prefix (prevents path traversal).
        if ( !findNoCase(variables.localSourceDir, p) ) {
            return false;
        }

        var filename = listLast( p, "/\" );
        var ext      = lCase( listLast(filename, ".") );

        if ( !arrayFindNoCase(variables.allowedExtensions, ext) ) {
            return false;
        }

        // Confirm the file actually exists on disk using the absolute path.
        var filename = listLast( p, "/\" );
        return fileExists( variables.localSourceDirAbsolute & filename );
    }


    // ── Private: variant side-effect ─────────────────────────────────────────

    /**
     * Build the set of lowercase filename tokens to match against for a user.
     * Tokens are derived from name combinations and all external ID values.
     */
    private array function _buildUserTokens(
        required string firstName,
        required string lastName,
        string  middleName = "",
        required array  externalIDs
    ) {
        var tokens  = [];
        var first   = lCase( trim(arguments.firstName) );
        var last    = lCase( trim(arguments.lastName) );
        var middle  = lCase( trim(arguments.middleName) );
        var fi      = len(first)  ? left(first, 1)  : "";
        var mi      = len(middle) ? left(middle, 1) : "";

        // Build a replacement map for pattern tokens
        var tokenMap = {
            "{first}"  = first,
            "{last}"   = last,
            "{middle}" = middle,
            "{fi}"     = fi,
            "{mi}"     = mi
        };

        // Load patterns from DB
        var patterns = variables.PatternDAO.getActivePatterns();

        for ( var p in patterns ) {
            var resolved = lCase( trim(p.PATTERN) );

            // Replace all known tokens
            for ( var key in tokenMap ) {
                resolved = replaceNoCase( resolved, key, tokenMap[key], "all" );
            }

            // Skip if any unresolved token remains or required fields were empty
            if ( find("{", resolved) OR !len(resolved) ) {
                continue;
            }

            // Deduplicate
            if ( !arrayFindNoCase(tokens, resolved) ) {
                arrayAppend( tokens, resolved );
            }
        }

        // External ID values (CougarNet username, PeopleSoft ID, etc.)
        for ( var extID in arguments.externalIDs ) {
            var extVal = lCase( trim(extID.EXTERNALVALUE ?: "") );
            if ( len(extVal) GTE 3 AND !arrayFindNoCase(tokens, extVal) ) {
                arrayAppend( tokens, extVal );
            }
        }

        return tokens;
    }

    /**
     * Return true if the filename stem (no extension) contains any token.
     * Minimum token length of 3 prevents single-letter false positives.
     */
    private boolean function _filenameMatchesTokens(
        required string filename,
        required array  tokens
    ) {
        // Strip extension to get just the stem
        var dotPos = find( ".", reverse(arguments.filename) );
        var stem   = dotPos ? lCase( left(arguments.filename, len(arguments.filename) - dotPos) ) : lCase(arguments.filename);

        for ( var token in arguments.tokens ) {
            if ( len(token) GTE 3 AND findNoCase(token, stem) ) {
                return true;
            }
        }
        return false;
    }

    // ── Private: variant side-effect ─────────────────────────────────────────

    /**
     * Marks all variants for a user+sourceKey as STALE via the DAO.
     * Wrapped in try/catch so a missing UserImageVariants table does not
     * break the POC — remove the catch once that table exists.
     *
     * Variants are NEVER regenerated automatically.
     * Regeneration is always an explicit admin action.
     */
    private void function _markVariantsStale(
        required numeric userID,
        required string  sourceKey
    ) {
        try {
            variables.SourceDAO.markVariantsStale( arguments.userID, arguments.sourceKey );
        } catch (any e) {
            // POC: UserImageVariants table may not yet exist — silently ignore.
            // Remove this catch block once the variants table is in place.
        }
    }

}
