/*
 * Removable feature: API docs quick token/secret generator.
 * To remove this feature, delete this file and remove the docs panel/script include in /api/docs.html.
 */
(function () {
    var form = document.getElementById("docsQuickAuthForm");
    if (!form) {
        return;
    }

    var usernameInput = document.getElementById("docsQuickAuthUsername");
    var passwordInput = document.getElementById("docsQuickAuthPassword");
    var submitButton = document.getElementById("docsQuickAuthSubmit");
    var statusBox = document.getElementById("docsQuickAuthStatus");
    var resultWrap = document.getElementById("docsQuickAuthResults");
    var tokenInput = document.getElementById("docsQuickAuthToken");
    var secretInput = document.getElementById("docsQuickAuthSecret");

    function setStatus(kind, message) {
        statusBox.className = "alert mt-3";
        statusBox.classList.add(kind === "success" ? "alert-success" : "alert-danger");
        statusBox.textContent = message;
        statusBox.classList.remove("d-none");
    }

    function clearStatus() {
        statusBox.className = "alert mt-3 d-none";
        statusBox.textContent = "";
    }

    function setWorking(working) {
        submitButton.disabled = working;
        submitButton.innerHTML = working
            ? '<span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>Generating...'
            : '<i class="bi bi-key-fill me-1"></i>Authenticate and Generate';
    }

    async function submitQuickAuth(event) {
        event.preventDefault();
        clearStatus();
        resultWrap.classList.add("d-none");
        tokenInput.value = "";
        secretInput.value = "";

        var username = (usernameInput.value || "").trim().toLowerCase();
        var password = passwordInput.value || "";

        if (!username || !password) {
            setStatus("error", "Enter username and password.");
            return;
        }

        setWorking(true);

        try {
            var response = await fetch("/api/v1/docs-quick-auth.cfm", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "Accept": "application/json"
                },
                body: JSON.stringify({ username: username, password: password })
            });

            var payload = {};
            try {
                var raw = await response.json();
                // Normalize keys to lowercase — ColdFusion serializes struct keys as uppercase
                payload = {};
                Object.keys(raw).forEach(function (k) { payload[k.toLowerCase()] = raw[k]; });
            } catch (jsonError) {
                payload = {};
            }

            if (response.ok && payload.success) {
                tokenInput.value = payload.token || "";
                secretInput.value = payload.secret || "";
                resultWrap.classList.remove("d-none");
                passwordInput.value = "";
                setStatus("success", payload.message || "Token and secret generated.");
            } else {
                setStatus("error", payload.message || "Request failed.");
            }
        } catch (requestError) {
            setStatus("error", "Unable to reach quick auth endpoint.");
        } finally {
            setWorking(false);
        }
    }

    async function copyValue(button) {
        var targetID = button.getAttribute("data-copy-target");
        var target = targetID ? document.getElementById(targetID) : null;
        if (!target || !target.value) {
            return;
        }

        var original = button.textContent;

        function markCopied(ok) {
            button.textContent = ok ? "Copied" : "Copy failed";
            setTimeout(function () { button.textContent = original; }, 1200);
        }

        // Prefer Clipboard API (HTTPS); fall back to execCommand for HTTP dev environments
        if (navigator.clipboard && window.isSecureContext) {
            try {
                await navigator.clipboard.writeText(target.value);
                markCopied(true);
            } catch (e) {
                markCopied(false);
            }
        } else {
            try {
                target.select();
                target.setSelectionRange(0, target.value.length);
                var ok = document.execCommand("copy");
                markCopied(ok);
            } catch (e) {
                markCopied(false);
            }
        }
    }

    form.addEventListener("submit", submitQuickAuth);

    document.querySelectorAll("[data-copy-target]").forEach(function (button) {
        button.addEventListener("click", function () {
            copyValue(button);
        });
    });
})();