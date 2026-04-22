<cfif NOT request.hasPermission("settings.app_config.manage")>
    <cflocation url="#request.webRoot#/admin/unauthorized.cfm" addtoken="false">
</cfif>

<cfset appConfigService = createObject("component", "cfc.appConfig_service").init()>
<cfset mediaConfigService = createObject("component", "cfc.mediaConfig_service").init()>

<cfset actionMessage = "">
<cfset actionMessageClass = "alert-success">

<cfif cgi.request_method EQ "POST">
    <cftry>
        <cfset postAction = trim(form.formAction ?: "savePublishedSettings")>

        <cfif postAction EQ "savePublishedSettings">
            <cfset mediaConfigService.setPublishedSiteBaseUrl( trim(form.publishedSiteBaseUrl ?: "") )>
            <cfset actionMessage = "Application settings saved.">
        <cfelseif postAction EQ "updateConfigValue">
            <cfset configKey = trim(form.configKey ?: "")>
            <cfset configValue = trim(form.configValue ?: "")>

            <cfif !len(configKey)>
                <cfthrow message="Config key is required.">
            </cfif>

            <cfset appConfigService.setValue(configKey, configValue)>
            <cfset actionMessage = "Config value updated for " & configKey & ".">
        <cfelse>
            <cfthrow message="Unknown settings action.">
        </cfif>
    <cfcatch type="any">
        <cfset actionMessage = cfcatch.message>
        <cfset actionMessageClass = "alert-danger">
    </cfcatch>
    </cftry>
</cfif>

<cfset publishedSiteBaseUrl = mediaConfigService.getPublishedSiteBaseUrl()>
<cfset publishedImageBaseUrl = mediaConfigService.getPublishedImageBaseUrl()>
<cfset allConfig = appConfigService.getAll()>

<cfset content = "">
<cfsavecontent variable="content">
<cfoutput>

<div class="settings-page settings-app-config-page">
<nav aria-label="breadcrumb" class="mb-3">
    <ol class="breadcrumb">
        <li class="breadcrumb-item"><a href="/admin/settings/">Settings</a></li>
        <li class="breadcrumb-item active" aria-current="page">Application Settings</li>
    </ol>
</nav>

<div class="d-flex justify-content-between align-items-center mb-4">
    <div>
        <h1 class="mb-1"><i class="bi bi-sliders me-2"></i>Application Settings</h1>
        <p class="text-muted mb-0">Generic application configuration stored in AppConfig. Start here for environment-specific values that will expand over time.</p>
    </div>
</div>

<cfif len(actionMessage)>
    <div class="alert #actionMessageClass# alert-dismissible fade show" role="alert">
        #encodeForHTML(actionMessage)#
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
</cfif>

<div class="card shadow-sm mb-4 settings-shell settings-summary-card">
    <div class="card-header">
        <h5 class="mb-0"><i class="bi bi-image me-2"></i>Published Image URL Settings</h5>
    </div>
    <div class="card-body">
        <form method="post" class="row g-3 align-items-end">
            <input type="hidden" name="formAction" value="savePublishedSettings">
            <div class="col-lg-8">
                <label for="publishedSiteBaseUrl" class="form-label fw-bold">Published Site Base URL</label>
                <input
                    type="url"
                    class="form-control"
                    id="publishedSiteBaseUrl"
                    name="publishedSiteBaseUrl"
                    value="#encodeForHTMLAttribute(publishedSiteBaseUrl)#"
                    placeholder="https://portal.opt.uh.edu/"
                    required
                >
                <div class="form-text">Publishing appends <code>_published_images/filename.ext</code> to this base URL.</div>
            </div>
            <div class="col-lg-4">
                <button type="submit" class="btn btn-primary">
                    <i class="bi bi-save me-1"></i>Save Settings
                </button>
            </div>
        </form>

        <div class="mt-3 small text-muted">
            Effective published image base URL:
            <span class="font-monospace">#encodeForHTML(publishedImageBaseUrl)#</span>
        </div>
    </div>
</div>

<div class="card shadow-sm settings-shell">
    <div class="card-header d-flex justify-content-between align-items-center">
        <h5 class="mb-0"><i class="bi bi-table me-2"></i>Current AppConfig Values</h5>
        <span class="badge settings-badge-count">#arrayLen(allConfig)#</span>
    </div>
    <div class="card-body p-0">
        <cfif arrayLen(allConfig)>
            <div class="table-responsive">
                <table class="table table-sm table-hover mb-0 align-middle settings-table">
                    <thead>
                        <tr>
                            <th>Config Key</th>
                            <th>Config Value</th>
                            <th>Updated</th>
                            <th class="text-end">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <cfloop from="1" to="#arrayLen(allConfig)#" index="i">
                            <cfset row = allConfig[i]>
                            <tr>
                                <td class="font-monospace">#encodeForHTML(row.CONFIGKEY)#</td>
                                <td class="font-monospace small">#encodeForHTML(row.CONFIGVALUE)#</td>
                                <td class="small text-muted">#len(row.UPDATEDAT ?: "") ? dateTimeFormat(row.UPDATEDAT, "mmm d, yyyy h:nn tt") : ""#</td>
                                <td class="text-end">
                                    <button
                                        type="button"
                                        class="btn btn-sm btn-outline-primary js-edit-config"
                                        data-bs-toggle="modal"
                                        data-bs-target="##editConfigModal"
                                        data-config-key="#encodeForHTMLAttribute(row.CONFIGKEY)#"
                                        data-config-value="#encodeForHTMLAttribute(row.CONFIGVALUE)#"
                                    >
                                        <i class="bi bi-pencil-square me-1"></i>
                                    </button>
                                </td>
                            </tr>
                        </cfloop>
                    </tbody>
                </table>
            </div>
        <cfelse>
            <div class="p-3 text-muted">No app settings found.</div>
        </cfif>
    </div>
</div>

</div>

<div class="modal fade settings-modal" id="editConfigModal" tabindex="-1" aria-labelledby="editConfigModalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="editConfigModalLabel"><i class="bi bi-gear me-2"></i>Edit AppConfig Value</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <form id="editConfigForm" method="post">
                <input type="hidden" name="formAction" value="updateConfigValue">
                <div class="modal-body">
                    <div class="mb-3">
                        <label for="editConfigKey" class="form-label fw-bold">Config Key</label>
                        <input type="text" class="form-control font-monospace" id="editConfigKey" name="configKey" readonly>
                    </div>
                    <div class="mb-2">
                        <label for="editConfigValue" class="form-label fw-bold">Config Value</label>
                        <textarea class="form-control font-monospace" id="editConfigValue" name="configValue" rows="4"></textarea>
                    </div>
                    <div class="small text-muted text-center">
                        <strong class="text-danger">This change is immediate and affects all environments.</strong><br/><br/>Changing certain config values may have unintended consequences. Please review the value carefully before applying.
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="button" id="reviewConfigChangeBtn" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="##confirmConfigModal">
                        <i class="bi bi-check2-square me-1"></i>Review Change
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<div class="modal fade settings-modal" id="confirmConfigModal" tabindex="-1" aria-labelledby="confirmConfigModalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="confirmConfigModalLabel"><i class="bi bi-exclamation-triangle me-2"></i>Confirm AppConfig Update</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <p class="mb-2">You are about to update this config key:</p>
                <div class="p-2 rounded border bg-light small mb-3">
                    <div><strong>Key:</strong> <span id="confirmConfigKey" class="font-monospace"></span></div>
                    <div class="mt-1"><strong>New Value:</strong></div>
                    <div id="confirmConfigValue" class="font-monospace small text-break"></div>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="checkbox" value="1" id="confirmConfigCheckbox">
                    <label class="form-check-label" for="confirmConfigCheckbox">
                        I understand this updates live AppConfig values.
                    </label>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                <button type="button" id="applyConfigChangeBtn" class="btn btn-danger" disabled>
                    <i class="bi bi-check-circle me-1"></i>Apply Change
                </button>
            </div>
        </div>
    </div>
</div>

<script>
(function () {
    document.addEventListener('DOMContentLoaded', function () {
        var editConfigModal = document.getElementById('editConfigModal');
        var confirmConfigModal = document.getElementById('confirmConfigModal');
        var editForm = document.getElementById('editConfigForm');
        var keyInput = document.getElementById('editConfigKey');
        var valueInput = document.getElementById('editConfigValue');
        var confirmKey = document.getElementById('confirmConfigKey');
        var confirmValue = document.getElementById('confirmConfigValue');
        var confirmCheckbox = document.getElementById('confirmConfigCheckbox');
        var applyBtn = document.getElementById('applyConfigChangeBtn');

        if (!editConfigModal || !confirmConfigModal || !editForm) { return; }

        editConfigModal.addEventListener('show.bs.modal', function (event) {
            var trigger = event.relatedTarget;
            keyInput.value = trigger.getAttribute('data-config-key') || '';
            valueInput.value = trigger.getAttribute('data-config-value') || '';
            confirmCheckbox.checked = false;
            applyBtn.disabled = true;
        });

        confirmConfigModal.addEventListener('show.bs.modal', function () {
            confirmKey.textContent = keyInput.value || '';
            confirmValue.textContent = valueInput.value || '(empty)';
            confirmCheckbox.checked = false;
            applyBtn.disabled = true;
        });

        confirmCheckbox.addEventListener('change', function () {
            applyBtn.disabled = !confirmCheckbox.checked;
        });

        applyBtn.addEventListener('click', function () {
            editForm.submit();
        });
    });
}());
</script>

</cfoutput>
</cfsavecontent>

<cfinclude template="/admin/layout.cfm">