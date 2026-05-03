<!---
    Removable feature: API docs quick token/secret generator.
    To remove this feature, delete this file and remove the docs panel/script include in /api/docs.html.
--->
<cfheader name="Content-Type" value="application/json; charset=utf-8">

<cfscript>
function sendJSON(required numeric statusCode, required struct payload) {
    cfheader(statusCode = arguments.statusCode);
    writeOutput(serializeJSON(arguments.payload));
    abort;
}

function queryToStruct(required any qry) {
    var rows = [];
    for (var i = 1; i <= arguments.qry.recordCount; i++) {
        var row = {};
        for (var col in listToArray(arguments.qry.columnList)) {
            row[col] = arguments.qry[col][i];
        }
        arrayAppend(rows, row);
    }
    return rows;
}

function normalizeUsername(required string rawUsername) {
    var normalized = lCase(trim(arguments.rawUsername ?: ""));

    if (find("\\", normalized)) {
        normalized = listLast(normalized, "\\");
    }

    if (find("@", normalized)) {
        normalized = listFirst(normalized, "@");
    }

    return normalized;
}

function mapLdapErrorMessage(required any err) {
    var messageText = toString(arguments.err.message ?: "");

    if (messageText CONTAINS "error code 49") {
        if (messageText CONTAINS "52e") return "Invalid credentials.";
        if (messageText CONTAINS "525") return "User not found.";
        if (messageText CONTAINS "530") return "Account not permitted to log on.";
        if (messageText CONTAINS "532") return "Password expired.";
        if (messageText CONTAINS "533") return "Account disabled.";
        if (messageText CONTAINS "701") return "Account expired.";
        if (messageText CONTAINS "773") return "Password reset required before login.";
        if (messageText CONTAINS "775") return "Account locked.";
        return "Authentication failed.";
    }

    if (messageText CONTAINS "Unable to connect" OR messageText CONTAINS "SocketTimeoutException") {
        return "Authentication service unavailable. Try again later.";
    }

    return "Authentication failed.";
}

if (uCase(CGI.REQUEST_METHOD ?: "") NEQ "POST") {
    sendJSON(405, {
        success: false,
        message: "Method not allowed. Use POST."
    });
}

requestData = getHttpRequestData();
rawBody = trim(requestData.content ?: "");
body = {};
username = "";
password = "";

if (len(rawBody)) {
    try {
        body = deserializeJSON(rawBody);
    } catch (any ignoreJSONError) {
        body = {};
    }
}

if (isStruct(body)) {
    username = trim(toString(body.username ?: ""));
    password = toString(body.password ?: "");
}

if (!len(username) && structKeyExists(form, "username")) {
    username = trim(form.username ?: "");
}
if (!len(password) && structKeyExists(form, "password")) {
    password = toString(form.password ?: "");
}

username = normalizeUsername(username);

if (!len(username) || !reFind("^[a-z0-9._-]{2,64}$", username)) {
    sendJSON(400, {
        success: false,
        message: "Invalid username format."
    });
}

if (!len(password)) {
    sendJSON(400, {
        success: false,
        message: "Password is required."
    });
}

ldapUser = queryNew("");
ldapAuthOK = false;

try {
    cfldap(
        action = "QUERY",
        name = "ldapUser",
        attributes = "sAMAccountName,userAccountControl,accountExpires",
        start = "DC=cougarnet,DC=uh,DC=edu",
        scope = "SUBTREE",
        filter = "(&(objectClass=User)(objectCategory=Person)(sAMAccountName=#username#))",
        maxrows = 1,
        server = "cougarnet.uh.edu",
        username = "COUGARNET\#username#",
        password = password
    );

    if (ldapUser.recordCount EQ 0) {
        sendJSON(401, {
            success: false,
            message: "Authentication failed."
        });
    }

    if (bitAnd(ldapUser.userAccountControl, 2)) {
        sendJSON(401, {
            success: false,
            message: "Account disabled."
        });
    }

    if (
        val(ldapUser.accountExpires) NEQ 0
        AND val(ldapUser.accountExpires) LT dateDiff("s", createDate(1601, 1, 1), now())
    ) {
        sendJSON(401, {
            success: false,
            message: "Account expired."
        });
    }

    ldapAuthOK = true;
} catch (any authError) {
    authMessage = mapLdapErrorMessage(authError);

    sendJSON(401, {
        success: false,
        message: authMessage
    });
}

if (!ldapAuthOK) {
    sendJSON(401, {
        success: false,
        message: "Authentication failed."
    });
}

if (!listFindNoCase("wcgreen,rjthomp", username)) {
    sendJSON(403, {
        success: false,
        message: "No privileges to create token/secret."
    });
}

// Use the admin datasource directly — the API app scope only has a read-only datasource.
WRITE_DSN = "UHCO_Identity_Admin";

appName   = "API Docs Quick Auth - " & username;
tokenName = "Docs Quick Token - " & username;
secretName = "Docs Quick Secret - " & username;

// One-active-pair check: query directly with write datasource.
activeCheck = queryExecute(
    "SELECT COUNT(*) AS cnt
     FROM (
         SELECT AppName FROM APITokens  WHERE IsActive = 1 AND AppName = :app
         UNION ALL
         SELECT AppName FROM APISecrets WHERE IsActive = 1 AND AppName = :app
     ) combined",
    { app: { value=appName, cfsqltype="cf_sql_nvarchar" } },
    { datasource=WRITE_DSN, timeout=10 }
);

if (val(activeCheck.cnt) GT 0) {
    sendJSON(409, {
        success: false,
        message: "Quick generation already used for this account. Ask an admin to revoke or delete the existing token/secret before generating again."
    });
}

// Generate token — same algorithm as token_service.cfc
rawToken   = "uhcs_" & lCase(createUUID()) & lCase(left(hash(now() & createUUID(), "SHA-256"), 8));
tokenHash  = lCase(hash(rawToken, "SHA-256"));

// Generate secret — same algorithm as secret_service.cfc
rawSecret  = "uhcs_sec_" & lCase(createUUID()) & lCase(left(hash(now() & createUUID(), "SHA-256"), 8));
secretHash = lCase(hash(rawSecret, "SHA-256"));

newTokenID  = 0;
newSecretID = 0;

try {
    tokenInsert = queryExecute(
        "INSERT INTO APITokens (TokenName, AppName, TokenHash, Scopes, AllowedIPs, ExpiresAt)
         OUTPUT INSERTED.TokenID
         VALUES (:name, :app, :hash, :scopes, NULL, NULL)",
        {
            name:   { value=tokenName, cfsqltype="cf_sql_nvarchar" },
            app:    { value=appName,   cfsqltype="cf_sql_nvarchar" },
            hash:   { value=tokenHash, cfsqltype="cf_sql_char"     },
            scopes: { value="read",    cfsqltype="cf_sql_nvarchar" }
        },
        { datasource=WRITE_DSN, timeout=30 }
    );
    newTokenID = val(tokenInsert.TokenID);

    try {
        secretInsert = queryExecute(
            "INSERT INTO APISecrets (SecretName, AppName, SecretHash, ProtectedFlags, AllowedIPs, ExpiresAt)
             OUTPUT INSERTED.SecretID
             VALUES (:name, :app, :hash, :flags, NULL, NULL)",
            {
                name:  { value=secretName,            cfsqltype="cf_sql_nvarchar" },
                app:   { value=appName,               cfsqltype="cf_sql_nvarchar" },
                hash:  { value=secretHash,            cfsqltype="cf_sql_char"     },
                flags: { value="Current-Student,Alumni", cfsqltype="cf_sql_nvarchar" }
            },
            { datasource=WRITE_DSN, timeout=30 }
        );
        newSecretID = val(secretInsert.SecretID);
    } catch (any secretCreateError) {
        // Roll back token so no orphan active record is left
        if (newTokenID GT 0) {
            try {
                queryExecute(
                    "UPDATE APITokens SET IsActive = 0 WHERE TokenID = :id",
                    { id: { value=newTokenID, cfsqltype="cf_sql_integer" } },
                    { datasource=WRITE_DSN, timeout=10 }
                );
            } catch (any ignoreRollback) {}
        }
        sendJSON(500, {
            success: false,
            message: "Unable to generate secret. No credentials were kept active."
        });
    }
} catch (any createError) {
    sendJSON(500, {
        success: false,
        message: "Unable to generate token/secret at this time."
    });
}

sendJSON(200, {
    success: true,
    message: "Token and secret generated.",
    user: username,
    appName: appName,
    token: rawToken,
    secret: rawSecret,
    protectedFlags: ["Current-Student", "Alumni"]
});
</cfscript>