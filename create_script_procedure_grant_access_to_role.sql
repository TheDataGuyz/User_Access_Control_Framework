-- Create the procedure
CREATE PROCEDURE SECURITY.GrantAccessToRole
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX) = '';
    DECLARE @revokeSql NVARCHAR(MAX) = '';

    -- Grant access to schemas
    SELECT @sql = @sql + 'GRANT SELECT ON SCHEMA::' + QUOTENAME(p.schema_name) + ' TO ' + QUOTENAME(r.role_name) + ';' + CHAR(13)
	FROM SECURITY.role_permissions rp
    INNER JOIN SECURITY.roles r ON rp.role_id = r.role_id
	INNER JOIN SECURITY.permissions p ON rp.permission_id = p.permission_id
    WHERE 1=1
    AND rp.is_active = 1
    AND p.object_name IS NULL
    AND p.column_name IS NULL
    AND p.row_filter IS NULL;

    -- Grant access to objects
    SELECT @sql = @sql + 'GRANT SELECT ON ' + QUOTENAME(p.schema_name) + '.' + QUOTENAME(p.object_name) + ' TO ' + QUOTENAME(r.role_name) + ';' + CHAR(13)
	FROM SECURITY.role_permissions rp
    INNER JOIN SECURITY.roles r ON rp.role_id = r.role_id
	INNER JOIN SECURITY.permissions p ON rp.permission_id = p.permission_id
    WHERE 1=1
    AND rp.is_active = 1
    AND p.column_name IS NULL
    AND p.row_filter IS NULL;

    -- Apply dynamic masking rules
    -- Apply mask
    SELECT @sql = @sql + 'ALTER TABLE ' + QUOTENAME(p.schema_name) + '.' + QUOTENAME(p.object_name) + ' ALTER COLUMN ' + QUOTENAME(p.column_name) + ' ADD MASKED WITH (FUNCTION = ''default()'');' + CHAR(13)
	FROM SECURITY.role_permissions rp
    INNER JOIN SECURITY.roles r ON rp.role_id = r.role_id
	INNER JOIN SECURITY.permissions p ON rp.permission_id = p.permission_id
    WHERE 1=1
    AND rp.is_active = 0
	AND p.column_name IS NOT NULL;

    -- Grant UNMASK
    SELECT @sql = @sql + 'GRANT UNMASK ON ' + QUOTENAME(p.schema_name) + '.' + QUOTENAME(p.object_name) + '(' + QUOTENAME(p.column_name) + ') TO ' + QUOTENAME(r.role_name) + ';' + CHAR(13)
	FROM SECURITY.role_permissions rp
    INNER JOIN SECURITY.roles r ON rp.role_id = r.role_id
	INNER JOIN SECURITY.permissions p ON rp.permission_id = p.permission_id
    WHERE 1=1
    AND rp.is_active = 1
	AND p.column_name IS NOT NULL;

    -- Execute the generated SQL statement
    EXEC sp_executesql @sql;

	-- Revoke the grant permission if column is_active is 0
	SELECT @revokeSql = @revokeSql + 'REVOKE SELECT ON' + QUOTENAME(p.object_name) + ' FROM ' + QUOTENAME(r.role_name) + ';' + CHAR(13)
	FROM SECURITY.role_permissions rp
    INNER JOIN SECURITY.roles r ON rp.role_id = r.role_id
	INNER JOIN SECURITY.permissions p ON rp.permission_id = p.permission_id
    WHERE 1=1
    AND rp.is_active = 0
    AND p.column_name IS NULL
    AND p.row_filter IS NULL;

	-- Revoke the UNMASK permission if column is_active is 0
	SELECT @revokeSql = @revokeSql + 'REVOKE UNMASK ON' + QUOTENAME(p.schema_name) + '.' + QUOTENAME(p.object_name) + '(' + QUOTENAME(p.column_name) + ') TO ' + QUOTENAME(r.role_name) + ';' + CHAR(13)
	FROM SECURITY.role_permissions rp
    INNER JOIN SECURITY.roles r ON rp.role_id = r.role_id
	INNER JOIN SECURITY.permissions p ON rp.permission_id = p.permission_id
    WHERE 1=1
    AND rp.is_active = 0
    AND p.column_name IS NOT NULL
    AND p.row_filter IS NULL;

	-- Execute the revoke SQL statement
	EXEC sp_executesql @revokeSql;

    RETURN;
END;

GO

-- Execute the procdure

/* 
EXEC SECURITY.GrantAccessToRole;
*/

-- DROP Procedure if exists SECURITY.GrantAccessToRole;

-- Check what access each role has
/*
SELECT
    Username           = pri.name,
    [User Type]        = pri.type_desc,
    Permission         = permit.permission_name,
    [Permission State] = permit.state_desc,
    Class              = permit.class_desc,
    [Database Name]    = DB_NAME(),
    [Schema Name]      = SCHEMA_NAME(obj.schema_id),
    [Table Name]       = obj.name,
    [Column Name]      = col.name
FROM
    sys.database_principals pri
    LEFT JOIN sys.database_permissions permit ON permit.grantee_principal_id = pri.principal_id
    LEFT JOIN sys.columns col ON col.object_id = permit.major_id AND col.column_id = permit.minor_id
    LEFT JOIN sys.objects obj ON obj.object_id = permit.major_id
WHERE 1=1
AND pri.name NOT IN ('public', 'db_owner', 'db_accessadmin', 'db_securityadmin', 
    'db_ddladmin', 'db_backupoperator', 'db_datareader', 'db_datawriter', 
    'db_denydatareader', 'db_denydatawriter')
AND permit.permission_name = 'UNMASK';
*/

