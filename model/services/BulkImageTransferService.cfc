component output="false" singleton {

    variables.sourceWebDir        = "/_temp_source/";
    variables.publishedWebDir     = "/_published_images/";
    variables.allowedExtensions   = ["jpg", "jpeg", "png"];
    variables.targetSourceKey     = "alumni";
    variables.targetVariantCodes  = ["interactvie_roster", "interactive_roster", "KIOSK_ROSTER"];

    public any function init() {
        variables.UsersDAO     = createObject("component", "dao.users_DAO").init();
        variables.UsersService = createObject("component", "cfc.users_service").init();
        variables.ExternalIDsDAO = createObject("component", "dao.externalIDs_DAO").init();
        variables.PatternDAO   = createObject("component", "dao.FileNamePatternDAO").init();
        variables.SourceDAO    = createObject("component", "dao.UserImageSourceDAO").init();
        variables.VariantDAO   = createObject("component", "dao.UserImageVariantDAO").init();
        variables.ImagesDAO    = createObject("component", "dao.images_DAO").init();
        variables.MediaConfigService = createObject("component", "cfc.mediaConfig_service").init();

        var cfcDir = getDirectoryFromPath( getCurrentTemplatePath() );
        var jFile = createObject("java", "java.io.File");

        variables.sourceDirAbsolute = jFile.init( cfcDir & "..\..\_temp_source" ).getCanonicalPath() & "\";
        variables.publishedDirAbsolute = jFile.init( cfcDir & "..\..\_published_images" ).getCanonicalPath() & "\";

        return this;
    }

    public struct function searchFolder( required string folderName ) {
        var cleanFolder = trim( arguments.folderName );
        var tokenProfiles = [];
        var transferLookup = {};
        var results = [];

        if ( !len(cleanFolder) ) {
            return { success=false, message="Folder name is required.", data=[] };
        }

        if ( find("..", cleanFolder) OR find(":", cleanFolder) ) {
            return { success=false, message="Folder name contains invalid path characters.", data=[] };
        }

        if ( !directoryExists(variables.sourceDirAbsolute) ) {
            return { success=false, message="Source directory does not exist: #variables.sourceDirAbsolute#", data=[] };
        }

        tokenProfiles = _buildUserTokenProfiles();
    transferLookup = _buildTransferLookup();

        var entries = directoryList( variables.sourceDirAbsolute, true, "query" );
        for ( var row in entries ) {
            if ( lCase(row.type) NEQ "file" ) {
                continue;
            }

            var ext = lCase( listLast(row.name, ".") );
            if ( !arrayFindNoCase(variables.allowedExtensions, ext) ) {
                continue;
            }

            var relativeDiskPath = _buildRelativeDiskPath( row.directory, row.name );
            var relativeFolder = getDirectoryFromPath( replace(relativeDiskPath, "\\", "/", "all") );
            if ( right(relativeFolder, 1) EQ "/" ) {
                relativeFolder = left( relativeFolder, len(relativeFolder) - 1 );
            }

            if ( !_folderFilterMatches(relativeFolder, cleanFolder) ) {
                continue;
            }

            var sourcePath = variables.sourceWebDir & replace(relativeDiskPath, "\\", "/", "all");
            var matchInfo = _matchFileToUser( row.name, tokenProfiles );
            var transferInfo = _getTransferInfo(
                userID        = matchInfo.userID,
                sourcePath    = sourcePath,
                variantCode   = matchInfo.variantCode,
                transferLookup = transferLookup
            );

            arrayAppend(results, {
                filename        = row.name,
                sourcePath      = sourcePath,
                relativeFolder  = relativeFolder,
                matchStatus     = matchInfo.status,
                userID          = matchInfo.userID,
                userDisplayName = matchInfo.userDisplayName,
                userEmail       = matchInfo.userEmail,
                matchedBy       = matchInfo.matchedBy,
                candidateText   = matchInfo.candidateText,
                canTransfer     = matchInfo.canTransfer AND !transferInfo.isTransferred,
                variantCode     = matchInfo.variantCode,
                isTransferred   = transferInfo.isTransferred,
                sourceID        = transferInfo.sourceID,
                transferLabel   = transferInfo.isTransferred ? "Transfered" : ""
            });
        }

        arraySort(results, function(a, b) {
            if ( a.isTransferred AND !b.isTransferred ) {
                return 1;
            }
            if ( !a.isTransferred AND b.isTransferred ) {
                return -1;
            }

            var statusOrder = { matched = 1, ambiguous = 2, none = 3 };
            var aRank = structKeyExists(statusOrder, a.matchStatus) ? statusOrder[a.matchStatus] : 9;
            var bRank = structKeyExists(statusOrder, b.matchStatus) ? statusOrder[b.matchStatus] : 9;

            if ( aRank LT bRank ) {
                return -1;
            }
            if ( aRank GT bRank ) {
                return 1;
            }

            return compareNoCase( a.filename, b.filename );
        });

        return {
            success = true,
            message = arrayLen(results)
                ? "Found #arrayLen(results)# image(s) in matching folder path(s)."
                : "No images found for that folder name.",
            data = results
        };
    }

    public struct function transferImage(
        required numeric userID,
        required string sourcePath
    ) {
        var cleanSourcePath = trim( arguments.sourcePath );
        var sourceAbsolutePath = _resolveSourceAbsolutePath( cleanSourcePath );
        var userResult = variables.UsersService.getUser( arguments.userID );
        var variantType = _resolveTargetVariantType();
        var sourceResult = {};
        var variantRecord = {};
        var publishedFilename = "";
        var publishedAbsolute = "";
        var publishedUrl = "";
        var dimensions = "";
        var outputExtension = "";

        if ( !len(sourceAbsolutePath) OR !fileExists(sourceAbsolutePath) ) {
            return { success=false, message="Source file not found in _temp_source.", sourceID=0, userID=arguments.userID };
        }

        if ( !userResult.success ) {
            return { success=false, message="User not found.", sourceID=0, userID=arguments.userID };
        }

        if ( structIsEmpty(variantType) ) {
            return {
                success = false,
                message = "Target variant type not found. Checked: #arrayToList(variables.targetVariantCodes, ', ')#.",
                sourceID = 0,
                userID = arguments.userID
            };
        }

        sourceResult = _ensureSourceRecord(
            userID     = arguments.userID,
            sourceKey  = variables.targetSourceKey,
            sourcePath = cleanSourcePath
        );
        if ( !sourceResult.success ) {
            return sourceResult;
        }

        variables.VariantDAO.upsertVariantAssignment(
            userImageSourceID  = sourceResult.sourceID,
            imageVariantTypeID = val(variantType.IMAGEVARIANTTYPEID)
        );

        variantRecord = variables.VariantDAO.getVariantBySourceAndType(
            userImageSourceID  = sourceResult.sourceID,
            imageVariantTypeID = val(variantType.IMAGEVARIANTTYPEID)
        );
        if ( structIsEmpty(variantRecord) ) {
            return {
                success = false,
                message = "Could not create or load the variant assignment.",
                sourceID = sourceResult.sourceID,
                userID = arguments.userID
            };
        }

        if ( !directoryExists(variables.publishedDirAbsolute) ) {
            directoryCreate( variables.publishedDirAbsolute );
        }

        outputExtension = _resolveOutputExtension( variantType, cleanSourcePath );
        publishedFilename = _buildPublishedFilename(
            user              = userResult.data,
            variantCode       = variantType.CODE,
            outputExtension   = outputExtension,
            userImageSourceID = sourceResult.sourceID
        );
        publishedAbsolute = variables.publishedDirAbsolute & publishedFilename;
        publishedUrl      = variables.MediaConfigService.buildPublishedUrl( publishedFilename );

        _writePublishedImage(
            sourceAbsolutePath = sourceAbsolutePath,
            publishedAbsolute  = publishedAbsolute,
            outputExtension    = outputExtension
        );

        dimensions = _buildImageDimensions( publishedAbsolute );

        variables.ImagesDAO.upsertPublishedImage(
            userID             = arguments.userID,
            imageVariant       = variantType.CODE,
            imageURL           = publishedUrl,
            imageDescription   = _buildDescription( userResult.data, variantType.DESCRIPTION ?: variantType.CODE ),
            imageDimensions    = dimensions,
            sortOrder          = 0,
            userImageSourceID  = sourceResult.sourceID
        );

        variables.VariantDAO.updateVariantGenerated(
            userImageVariantID = val(variantRecord.USERIMAGEVARIANTID),
            localPath          = ""
        );

        return {
            success      = true,
            message      = "Transferred and published #listLast(cleanSourcePath, '/\\')# for #userResult.data.FIRSTNAME# #userResult.data.LASTNAME#.",
            sourceID     = sourceResult.sourceID,
            userID       = arguments.userID,
            variantCode  = variantType.CODE,
            publishedUrl = publishedUrl
        };
    }

    private array function _buildUserTokenProfiles() {
        var users = variables.UsersDAO.getAllUsers();
        var allExternalIDs = variables.ExternalIDsDAO.getAllExternalIDs();
        var patterns = variables.PatternDAO.getActivePatterns();
        var externalIDsByUser = {};
        var result = [];

        for ( var extRow in allExternalIDs ) {
            var userKey = toString( extRow.USERID );
            if ( !structKeyExists(externalIDsByUser, userKey) ) {
                externalIDsByUser[userKey] = [];
            }

            if ( len(trim(extRow.EXTERNALVALUE ?: "")) ) {
                arrayAppend( externalIDsByUser[userKey], extRow.EXTERNALVALUE );
            }
        }

        for ( var user in users ) {
            var isActive = isBoolean(user.ACTIVE ?: "") ? user.ACTIVE : (val(user.ACTIVE ?: 0) EQ 1);
            if ( !isActive ) {
                continue;
            }

            var key = toString( user.USERID );
            var tokens = _buildUserTokens(
                firstName   = user.FIRSTNAME ?: "",
                lastName    = user.LASTNAME ?: "",
                middleName  = user.MIDDLENAME ?: "",
                externalIDs = structKeyExists(externalIDsByUser, key) ? externalIDsByUser[key] : [],
                patterns    = patterns
            );

            arrayAppend(result, {
                userID        = user.USERID,
                userDisplayName = trim( (user.FIRSTNAME ?: "") & " " & (user.LASTNAME ?: "") ),
                userEmail     = user.EMAILPRIMARY ?: "",
                tokens        = tokens
            });
        }

        return result;
    }

    private struct function _buildTransferLookup() {
        var lookup = {};
        var variantType = _resolveTargetVariantType();
        var users = variables.UsersDAO.getAllUsers();

        if ( structIsEmpty(variantType) ) {
            return lookup;
        }

        for ( var user in users ) {
            var userID = val(user.USERID ?: 0);
            var sources = variables.SourceDAO.getSourcesForUser( userID );
            var images = variables.ImagesDAO.getImages( userID );

            for ( var sourceRow in sources ) {
                if ( compareNoCase(sourceRow.SOURCEKEY ?: "", variables.targetSourceKey) NEQ 0 ) {
                    continue;
                }

                var sourceID = val(sourceRow.USERIMAGESOURCEID ?: 0);
                var sourcePath = trim(sourceRow.DROPBOXPATH ?: "");
                var isTransferred = false;

                for ( var imageRow in images ) {
                    if ( compareNoCase(imageRow.IMAGEVARIANT ?: "", variantType.CODE ?: "") EQ 0
                        AND val(imageRow.USERIMAGESOURCEID ?: 0) EQ sourceID ) {
                        isTransferred = true;
                        break;
                    }
                }

                if ( len(sourcePath) ) {
                    lookup[ _buildTransferLookupKey(userID, sourcePath) ] = {
                        isTransferred = isTransferred,
                        sourceID = sourceID
                    };
                }
            }
        }

        return lookup;
    }

    private struct function _getTransferInfo(
        required numeric userID,
        required string sourcePath,
        required string variantCode,
        required struct transferLookup
    ) {
        var lookupKey = _buildTransferLookupKey(arguments.userID, arguments.sourcePath);

        if ( arguments.userID GT 0 AND len(arguments.variantCode) AND structKeyExists(arguments.transferLookup, lookupKey) ) {
            return arguments.transferLookup[ lookupKey ];
        }

        return {
            isTransferred = false,
            sourceID = 0
        };
    }

    private string function _buildTransferLookupKey(
        required numeric userID,
        required string sourcePath
    ) {
        return arguments.userID & "|" & lCase( trim(arguments.sourcePath) );
    }

    private struct function _matchFileToUser(
        required string filename,
        required array tokenProfiles
    ) {
        var stem = lCase( reReplace(arguments.filename, "\.[^.]+$", "", "one") );
        var candidates = [];
        var variantType = _resolveTargetVariantType();

        for ( var profile in arguments.tokenProfiles ) {
            var matchedTokens = [];
            var score = 0;
            var longestToken = 0;

            for ( var token in profile.tokens ) {
                if ( len(token) GTE 3 AND findNoCase(token, stem) ) {
                    arrayAppend(matchedTokens, token);
                    score += len(token);
                    if ( len(token) GT longestToken ) {
                        longestToken = len(token);
                    }
                }
            }

            if ( arrayLen(matchedTokens) ) {
                arrayAppend(candidates, {
                    userID          = profile.userID,
                    userDisplayName = profile.userDisplayName,
                    userEmail       = profile.userEmail,
                    matchedTokens   = matchedTokens,
                    score           = score,
                    longestToken    = longestToken
                });
            }
        }

        if ( !arrayLen(candidates) ) {
            return {
                status        = "none",
                userID        = 0,
                userDisplayName = "",
                userEmail     = "",
                matchedBy     = "",
                candidateText = "No user token matched this filename.",
                canTransfer   = false,
                variantCode   = structIsEmpty(variantType) ? "" : variantType.CODE
            };
        }

        arraySort(candidates, function(a, b) {
            if ( a.score GT b.score ) {
                return -1;
            }
            if ( a.score LT b.score ) {
                return 1;
            }
            if ( a.longestToken GT b.longestToken ) {
                return -1;
            }
            if ( a.longestToken LT b.longestToken ) {
                return 1;
            }
            return compareNoCase( a.userDisplayName, b.userDisplayName );
        });

        var topCandidate = candidates[1];
        var topCount = 0;
        for ( var candidate in candidates ) {
            if ( candidate.score EQ topCandidate.score AND candidate.longestToken EQ topCandidate.longestToken ) {
                topCount++;
            }
        }

        if ( topCount GT 1 ) {
            var ambiguousNames = [];
            for ( var i = 1; i LTE min(arrayLen(candidates), 3); i++ ) {
                arrayAppend(ambiguousNames, candidates[i].userDisplayName);
            }

            return {
                status          = "ambiguous",
                userID          = 0,
                userDisplayName = "",
                userEmail       = "",
                matchedBy       = arrayToList(topCandidate.matchedTokens, ", "),
                candidateText   = "Ambiguous match: #arrayToList(ambiguousNames, ', ')#",
                canTransfer     = false,
                variantCode     = structIsEmpty(variantType) ? "" : variantType.CODE
            };
        }

        return {
            status          = "matched",
            userID          = topCandidate.userID,
            userDisplayName = topCandidate.userDisplayName,
            userEmail       = topCandidate.userEmail,
            matchedBy       = arrayToList(topCandidate.matchedTokens, ", "),
            candidateText   = "",
            canTransfer     = !structIsEmpty(variantType),
            variantCode     = structIsEmpty(variantType) ? "" : variantType.CODE
        };
    }

    private array function _buildUserTokens(
        required string firstName,
        required string lastName,
        string middleName = "",
        required array externalIDs,
        required array patterns
    ) {
        var tokens = [];
        var first = lCase( trim(arguments.firstName) );
        var last = lCase( trim(arguments.lastName) );
        var middle = lCase( trim(arguments.middleName) );
        var fi = len(first) ? left(first, 1) : "";
        var mi = len(middle) ? left(middle, 1) : "";
        var tokenMap = {
            "{first}" = first,
            "{last}"  = last,
            "{middle}" = middle,
            "{fi}"    = fi,
            "{mi}"    = mi
        };

        for ( var patternRow in arguments.patterns ) {
            var resolved = lCase( trim(patternRow.PATTERN ?: "") );
            for ( var tokenKey in tokenMap ) {
                resolved = replaceNoCase( resolved, tokenKey, tokenMap[tokenKey], "all" );
            }

            if ( find("{", resolved) OR !len(resolved) OR len(resolved) LT 3 ) {
                continue;
            }

            if ( !arrayFindNoCase(tokens, resolved) ) {
                arrayAppend(tokens, resolved);
            }
        }

        for ( var externalValue in arguments.externalIDs ) {
            var cleanedValue = lCase( trim(externalValue ?: "") );
            if ( len(cleanedValue) GTE 3 AND !arrayFindNoCase(tokens, cleanedValue) ) {
                arrayAppend(tokens, cleanedValue);
            }
        }

        return tokens;
    }

    private struct function _resolveTargetVariantType() {
        var variantTypes = variables.VariantDAO.getVariantTypesAllAdmin();

        for ( var preferredCode in variables.targetVariantCodes ) {
            for ( var variantType in variantTypes ) {
                if ( compareNoCase(variantType.CODE ?: "", preferredCode) EQ 0 ) {
                    return variantType;
                }
            }
        }

        return {};
    }

    private struct function _ensureSourceRecord(
        required numeric userID,
        required string sourceKey,
        required string sourcePath
    ) {
        var sources = variables.SourceDAO.getSourcesForUser( arguments.userID );

        for ( var sourceRow in sources ) {
            if ( compareNoCase(trim(sourceRow.SOURCEKEY ?: ""), trim(arguments.sourceKey)) EQ 0
                AND trim(sourceRow.DROPBOXPATH ?: "") EQ trim(arguments.sourcePath) ) {
                var isActive = isBoolean(sourceRow.ISACTIVE ?: "") ? sourceRow.ISACTIVE : (val(sourceRow.ISACTIVE ?: 0) EQ 1);
                if ( !isActive ) {
                    variables.SourceDAO.setActiveStatus( val(sourceRow.USERIMAGESOURCEID), true );
                }

                return {
                    success = true,
                    message = "Source record ready.",
                    sourceID = val(sourceRow.USERIMAGESOURCEID),
                    userID = arguments.userID
                };
            }
        }

        return {
            success = true,
            message = "Source record created.",
            sourceID = variables.SourceDAO.insertSource({
                UserID     = arguments.userID,
                SourceKey  = arguments.sourceKey,
                SourcePath = arguments.sourcePath
            }),
            userID = arguments.userID
        };
    }

    private string function _resolveSourceAbsolutePath( required string sourcePath ) {
        var relativePath = trim( arguments.sourcePath );
        var normalizedRelative = "";

        if ( left(relativePath, len(variables.sourceWebDir)) NEQ variables.sourceWebDir ) {
            return "";
        }

        relativePath = mid( relativePath, len(variables.sourceWebDir) + 1, len(relativePath) );
        relativePath = replace( relativePath, "/", "\\", "all" );
        normalizedRelative = reReplace( relativePath, "^[\\/]+", "", "all" );

        if ( !len(normalizedRelative) OR find("..", normalizedRelative) ) {
            return "";
        }

        return variables.sourceDirAbsolute & normalizedRelative;
    }

    private string function _buildRelativeDiskPath(
        required string directoryPath,
        required string filename
    ) {
        var fullPath = arguments.directoryPath & "\\" & arguments.filename;
        var relativePath = replaceNoCase( fullPath, variables.sourceDirAbsolute, "", "one" );
        return reReplace( relativePath, "^[\\/]+", "", "all" );
    }

    private boolean function _folderFilterMatches(
        required string relativeDirectory,
        required string folderName
    ) {
        var normalizedPath = lCase( replace(arguments.relativeDirectory, "/", "\\", "all") );
        var searchTerm = lCase( trim(arguments.folderName) );

        if ( !len(searchTerm) ) {
            return false;
        }

        normalizedPath = "\\" & normalizedPath;
        if ( right(normalizedPath, 1) NEQ "\\" ) {
            normalizedPath &= "\\";
        }

        if ( findNoCase( "\\" & searchTerm & "\\", normalizedPath ) ) {
            return true;
        }

        return findNoCase( searchTerm, normalizedPath ) GT 0;
    }

    private string function _resolveOutputExtension(
        required struct variantType,
        required string sourcePath
    ) {
        var outputExtension = lCase( trim(arguments.variantType.OUTPUTFORMAT ?: "") );

        if ( outputExtension EQ "jpeg" ) {
            outputExtension = "jpg";
        }

        if ( !listFindNoCase("jpg,png", outputExtension) ) {
            outputExtension = lCase( listLast(arguments.sourcePath, ".") );
            if ( outputExtension EQ "jpeg" ) {
                outputExtension = "jpg";
            }
        }

        return outputExtension;
    }

    private void function _writePublishedImage(
        required string sourceAbsolutePath,
        required string publishedAbsolute,
        required string outputExtension
    ) {
        var sourceExtension = lCase( listLast(arguments.sourceAbsolutePath, ".") );

        if ( sourceExtension EQ "jpeg" ) {
            sourceExtension = "jpg";
        }

        if ( fileExists(arguments.publishedAbsolute) ) {
            fileDelete(arguments.publishedAbsolute);
        }

        if ( sourceExtension EQ arguments.outputExtension ) {
            fileCopy(arguments.sourceAbsolutePath, arguments.publishedAbsolute);
            return;
        }

        var sourceImage = imageRead(arguments.sourceAbsolutePath);
        if ( arguments.outputExtension EQ "jpg" ) {
            cfimage(
                action = "write",
                source = sourceImage,
                destination = arguments.publishedAbsolute,
                overwrite = true,
                quality = 0.75
            );
        } else {
            cfimage(
                action = "write",
                source = sourceImage,
                destination = arguments.publishedAbsolute,
                overwrite = true
            );
        }
    }

    private string function _buildImageDimensions( required string imagePath ) {
        var img = imageRead(arguments.imagePath);
        return imageGetWidth(img) & "x" & imageGetHeight(img);
    }

    private string function _buildPublishedFilename(
        required struct user,
        required string variantCode,
        required string outputExtension,
        required numeric userImageSourceID
    ) {
        return variables.MediaConfigService.buildPublishedFilename(
            user              = arguments.user,
            variantCode       = arguments.variantCode,
            extension         = arguments.outputExtension,
            userImageSourceID = arguments.userImageSourceID
        );
    }

    private string function _buildDescription(
        required struct user,
        required string variantDescription
    ) {
        var parts = [];
        var firstName = trim(arguments.user.FIRSTNAME ?: "");
        var middleName = trim(arguments.user.MIDDLENAME ?: "");
        var lastName = trim(arguments.user.LASTNAME ?: "");

        if ( len(firstName) ) {
            arrayAppend(parts, firstName);
        }
        if ( len(middleName) ) {
            arrayAppend(parts, left(middleName, 1) & ".");
        }
        if ( len(lastName) ) {
            arrayAppend(parts, lastName);
        }
        if ( len(trim(arguments.variantDescription)) ) {
            arrayAppend(parts, trim(arguments.variantDescription));
        }
        arrayAppend(parts, "Image");

        return arrayToList(parts, " ");
    }

}