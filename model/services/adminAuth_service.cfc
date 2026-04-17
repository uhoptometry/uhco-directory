component output="false" {

    /**
     * adminAuth_service — Business logic for managing admin users and roles.
     * Wraps adminAuth_DAO with validation, LDAP lookup, and safety guards.
     */

    public any function init() {
        variables.dao = createObject("component", "dao.adminAuth_DAO").init();
        return this;
    }

    /* ─────────────────── Roles ─────────────────── */

    public array function getAllRoles() {
        return variables.dao.getAllRoles();
    }

    public struct function getRoleByID(required numeric roleID) {
        return variables.dao.getRoleByID(arguments.roleID);
    }

    public struct function createRole(required string roleName) {
        var result = { success = false, message = "", roleID = 0 };
        var name = uCase(trim(arguments.roleName));

        if (len(name) == 0) {
            result.message = "Role name is required.";
            return result;
        }

        // Check for duplicate
        var existing = variables.dao.getRoleByName(name);
        if (structCount(existing)) {
            result.message = "A role named '#name#' already exists.";
            return result;
        }

        result.roleID  = variables.dao.createRole(name);
        result.success  = true;
        result.message  = "Role '#name#' created.";
        return result;
    }

    public struct function updateRole(required numeric roleID, required string roleName) {
        var result = { success = false, message = "" };
        var name = uCase(trim(arguments.roleName));

        if (len(name) == 0) {
            result.message = "Role name is required.";
            return result;
        }

        var existing = variables.dao.getRoleByName(name);
        if (structCount(existing) AND existing.ROLE_ID != arguments.roleID) {
            result.message = "A role named '#name#' already exists.";
            return result;
        }

        variables.dao.updateRole(arguments.roleID, name);
        result.success = true;
        result.message = "Role updated.";
        return result;
    }

    public struct function deleteRole(required numeric roleID) {
        var result = { success = false, message = "" };

        var role = variables.dao.getRoleByID(arguments.roleID);
        if (!structCount(role)) {
            result.message = "Role not found.";
            return result;
        }

        // Prevent deleting SUPER_ADMIN
        if (role.ROLE_NAME == "SUPER_ADMIN") {
            result.message = "The SUPER_ADMIN role cannot be deleted.";
            return result;
        }

        variables.dao.deleteRole(arguments.roleID);
        result.success = true;
        result.message = "Role '#role.ROLE_NAME#' deleted.";
        return result;
    }

    /* ─────────────────── Users ─────────────────── */

    public array function getAllUsers() {
        return variables.dao.getAllUsers();
    }

    public struct function getUserByID(required numeric userID) {
        return variables.dao.getUserByID(arguments.userID);
    }

    public struct function addUser(required string cougarnet) {
        var result = { success = false, message = "", userID = 0 };
        var cn = lCase(trim(arguments.cougarnet));

        if (len(cn) == 0) {
            result.message = "CougarNet username is required.";
            return result;
        }

        // Check for existing (including inactive)
        var existing = variables.dao.getUserByCougarnet(cn);
        if (structCount(existing)) {
            if (existing.IS_ACTIVE) {
                result.message = "User '#cn#' already exists and is active.";
            } else {
                // Reactivate
                variables.dao.setUserActive(existing.USER_ID, true);
                result.userID  = existing.USER_ID;
                result.success = true;
                result.message = "User '#cn#' reactivated.";
            }
            return result;
        }

        // Validate via LDAP that user exists in CougarNet
        var ldapValid = validateCougarnet(cn);
        if (!ldapValid.found) {
            result.message = "CougarNet user '#cn#' not found in directory. #ldapValid.detail#";
            return result;
        }

        result.userID  = variables.dao.createUser(cn);
        result.success = true;
        result.message = "User '#cn#' (#ldapValid.displayName#) added.";
        return result;
    }

    public struct function toggleUserActive(required numeric userID) {
        var result = { success = false, message = "" };
        var user = variables.dao.getUserByID(arguments.userID);

        if (!structCount(user)) {
            result.message = "User not found.";
            return result;
        }

        var newActive = !user.IS_ACTIVE;

        // Prevent deactivating the last active SUPER_ADMIN
        if (!newActive) {
            var roles = variables.dao.getRolesForUser(arguments.userID);
            var isSA = false;
            for (var r in roles) {
                if (r.ROLE_NAME == "SUPER_ADMIN") { isSA = true; break; }
            }
            if (isSA) {
                var saCount = variables.dao.countUsersWithRole("SUPER_ADMIN");
                if (saCount <= 1) {
                    result.message = "Cannot deactivate the last active SUPER_ADMIN.";
                    return result;
                }
            }
        }

        variables.dao.setUserActive(arguments.userID, newActive);
        result.success = true;
        result.message = "User '#user.COUGARNET#' " & (newActive ? "activated" : "deactivated") & ".";
        return result;
    }

    /* ─────────────────── Role Assignments ─────────────────── */

    public array function getRolesForUser(required numeric userID) {
        return variables.dao.getRolesForUser(arguments.userID);
    }

    public struct function assignRole(required numeric userID, required numeric roleID) {
        var result = { success = false, message = "" };
        variables.dao.assignRole(arguments.userID, arguments.roleID);
        result.success = true;
        result.message = "Role assigned.";
        return result;
    }

    public struct function revokeRole(required numeric userID, required numeric roleID) {
        var result = { success = false, message = "" };

        // Prevent revoking SUPER_ADMIN if it leaves zero active super admins
        var role = variables.dao.getRoleByID(arguments.roleID);
        if (structCount(role) AND role.ROLE_NAME == "SUPER_ADMIN") {
            var saCount = variables.dao.countUsersWithRole("SUPER_ADMIN");
            if (saCount <= 1) {
                result.message = "Cannot revoke the last SUPER_ADMIN role assignment.";
                return result;
            }
        }

        variables.dao.revokeRole(arguments.userID, arguments.roleID);
        result.success = true;
        result.message = "Role revoked.";
        return result;
    }

    /* ─────────────────── Private ─────────────────── */

    private struct function validateCougarnet(required string username) {
        var result = { found = false, displayName = "", detail = "" };
        try {
            var qUser = "";
            cfldap(
                action      = "QUERY",
                name        = "qUser",
                attributes  = "displayName,sAMAccountName",
                start       = "DC=cougarnet,DC=uh,DC=edu",
                scope       = "SUBTREE",
                maxrows     = "1",
                server      = "cougarnet.uh.edu",
                filter      = "(&(objectClass=user)(sAMAccountName=#arguments.username#))",
                username    = "COUGARNET\uhcoweb",
                password    = "5E9##WN!ag"
            );
            if (qUser.recordCount GT 0) {
                result.found       = true;
                result.displayName = qUser.displayName;
            }
        } catch (any e) {
            result.detail = e.message;
        }
        return result;
    }

}
