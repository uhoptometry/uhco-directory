component extends="dao.BaseDAO" output="false" {

    /**
     * adminAuth_DAO — CRUD for AdminUsers, AdminRoles, AdminUserRoles
     */

    public any function init() {
        super.init();        return this;
    }

    /* ─────────────────── AdminRoles ─────────────────── */

    public array function getAllRoles() {
        var qry = executeQueryWithRetry(
            sql     = "SELECT role_id, role_name FROM AdminRoles ORDER BY role_name",
            params  = {},
            options = { datasource = variables.dsn }
        );
        return queryToArray(qry);
    }

    public struct function getRoleByID(required numeric roleID) {
        var qry = executeQueryWithRetry(
            sql     = "SELECT role_id, role_name FROM AdminRoles WHERE role_id = :roleID",
            params  = { roleID = { value = arguments.roleID, cfsqltype = "cf_sql_integer" } },
            options = { datasource = variables.dsn }
        );
        var arr = queryToArray(qry);
        return arrayLen(arr) ? arr[1] : {};
    }

    public struct function getRoleByName(required string roleName) {
        var qry = executeQueryWithRetry(
            sql     = "SELECT role_id, role_name FROM AdminRoles WHERE role_name = :roleName",
            params  = { roleName = { value = arguments.roleName, cfsqltype = "cf_sql_varchar" } },
            options = { datasource = variables.dsn }
        );
        var arr = queryToArray(qry);
        return arrayLen(arr) ? arr[1] : {};
    }

    public numeric function createRole(required string roleName) {
        var qry = executeQueryWithRetry(
            sql     = "INSERT INTO AdminRoles (role_name) OUTPUT INSERTED.role_id VALUES (:roleName)",
            params  = { roleName = { value = arguments.roleName, cfsqltype = "cf_sql_varchar" } },
            options = { datasource = variables.dsn }
        );
        return qry.role_id;
    }

    public void function updateRole(required numeric roleID, required string roleName) {
        executeQueryWithRetry(
            sql     = "UPDATE AdminRoles SET role_name = :roleName WHERE role_id = :roleID",
            params  = {
                roleID   = { value = arguments.roleID,   cfsqltype = "cf_sql_integer" },
                roleName = { value = arguments.roleName, cfsqltype = "cf_sql_varchar" }
            },
            options = { datasource = variables.dsn }
        );
    }

    public void function deleteRole(required numeric roleID) {
        executeQueryWithRetry(
            sql     = "DELETE FROM AdminUserRoles WHERE role_id = :roleID",
            params  = { roleID = { value = arguments.roleID, cfsqltype = "cf_sql_integer" } },
            options = { datasource = variables.dsn }
        );
        executeQueryWithRetry(
            sql     = "DELETE FROM AdminRoles WHERE role_id = :roleID",
            params  = { roleID = { value = arguments.roleID, cfsqltype = "cf_sql_integer" } },
            options = { datasource = variables.dsn }
        );
    }

    /* ─────────────────── AdminUsers ─────────────────── */

    public array function getAllUsers() {
        var qry = executeQueryWithRetry(
            sql     = "
                SELECT  u.user_id, u.cougarnet, u.is_active,
                        STUFF((
                            SELECT ', ' + r.role_name
                            FROM AdminUserRoles ur
                            JOIN AdminRoles r ON r.role_id = ur.role_id
                            WHERE ur.user_id = u.user_id
                            FOR XML PATH(''), TYPE
                        ).value('.','nvarchar(max)'), 1, 2, '') AS role_names,
                        STUFF((
                            SELECT ',' + CAST(r.role_id AS VARCHAR)
                            FROM AdminUserRoles ur
                            JOIN AdminRoles r ON r.role_id = ur.role_id
                            WHERE ur.user_id = u.user_id
                            FOR XML PATH(''), TYPE
                        ).value('.','nvarchar(max)'), 1, 1, '') AS role_ids
                FROM AdminUsers u
                ORDER BY u.cougarnet
            ",
            params  = {},
            options = { datasource = variables.dsn }
        );
        return queryToArray(qry);
    }

    public struct function getUserByID(required numeric userID) {
        var qry = executeQueryWithRetry(
            sql     = "SELECT user_id, cougarnet, is_active FROM AdminUsers WHERE user_id = :userID",
            params  = { userID = { value = arguments.userID, cfsqltype = "cf_sql_integer" } },
            options = { datasource = variables.dsn }
        );
        var arr = queryToArray(qry);
        return arrayLen(arr) ? arr[1] : {};
    }

    public struct function getUserByCougarnet(required string cougarnet) {
        var qry = executeQueryWithRetry(
            sql     = "SELECT user_id, cougarnet, is_active FROM AdminUsers WHERE cougarnet = :cn",
            params  = { cn = { value = arguments.cougarnet, cfsqltype = "cf_sql_varchar" } },
            options = { datasource = variables.dsn }
        );
        var arr = queryToArray(qry);
        return arrayLen(arr) ? arr[1] : {};
    }

    public numeric function createUser(required string cougarnet) {
        var qry = executeQueryWithRetry(
            sql     = "INSERT INTO AdminUsers (cougarnet, is_active) OUTPUT INSERTED.user_id VALUES (:cn, 1)",
            params  = { cn = { value = arguments.cougarnet, cfsqltype = "cf_sql_varchar" } },
            options = { datasource = variables.dsn }
        );
        return qry.user_id;
    }

    public void function setUserActive(required numeric userID, required boolean isActive) {
        executeQueryWithRetry(
            sql     = "UPDATE AdminUsers SET is_active = :active WHERE user_id = :userID",
            params  = {
                userID = { value = arguments.userID,                        cfsqltype = "cf_sql_integer" },
                active = { value = arguments.isActive ? 1 : 0,             cfsqltype = "cf_sql_integer" }
            },
            options = { datasource = variables.dsn }
        );
    }

    public void function deleteUser(required numeric userID) {
        executeQueryWithRetry(
            sql     = "DELETE FROM AdminUserRoles WHERE user_id = :userID",
            params  = { userID = { value = arguments.userID, cfsqltype = "cf_sql_integer" } },
            options = { datasource = variables.dsn }
        );
        executeQueryWithRetry(
            sql     = "DELETE FROM AdminUsers WHERE user_id = :userID",
            params  = { userID = { value = arguments.userID, cfsqltype = "cf_sql_integer" } },
            options = { datasource = variables.dsn }
        );
    }

    /* ─────────────────── AdminUserRoles ─────────────────── */

    public array function getRolesForUser(required numeric userID) {
        var qry = executeQueryWithRetry(
            sql     = "
                SELECT r.role_id, r.role_name
                FROM AdminUserRoles ur
                JOIN AdminRoles r ON r.role_id = ur.role_id
                WHERE ur.user_id = :userID
                ORDER BY r.role_name
            ",
            params  = { userID = { value = arguments.userID, cfsqltype = "cf_sql_integer" } },
            options = { datasource = variables.dsn }
        );
        return queryToArray(qry);
    }

    public void function assignRole(required numeric userID, required numeric roleID) {
        executeQueryWithRetry(
            sql     = "
                IF NOT EXISTS (
                    SELECT 1 FROM AdminUserRoles
                    WHERE user_id = :userID AND role_id = :roleID
                )
                INSERT INTO AdminUserRoles (user_id, role_id) VALUES (:userID, :roleID)
            ",
            params  = {
                userID = { value = arguments.userID, cfsqltype = "cf_sql_integer" },
                roleID = { value = arguments.roleID, cfsqltype = "cf_sql_integer" }
            },
            options = { datasource = variables.dsn }
        );
    }

    public void function revokeRole(required numeric userID, required numeric roleID) {
        executeQueryWithRetry(
            sql     = "DELETE FROM AdminUserRoles WHERE user_id = :userID AND role_id = :roleID",
            params  = {
                userID = { value = arguments.userID, cfsqltype = "cf_sql_integer" },
                roleID = { value = arguments.roleID, cfsqltype = "cf_sql_integer" }
            },
            options = { datasource = variables.dsn }
        );
    }

    public numeric function countUsersWithRole(required string roleName) {
        var qry = executeQueryWithRetry(
            sql     = "
                SELECT COUNT(*) AS cnt
                FROM AdminUserRoles ur
                JOIN AdminRoles r ON r.role_id = ur.role_id
                JOIN AdminUsers u ON u.user_id = ur.user_id
                WHERE r.role_name = :roleName AND u.is_active = 1
            ",
            params  = { roleName = { value = arguments.roleName, cfsqltype = "cf_sql_varchar" } },
            options = { datasource = variables.dsn }
        );
        return qry.cnt;
    }

}
