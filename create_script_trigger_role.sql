-- CREATE TRIGGER RoleTrigger_insert_delete
CREATE OR ALTER TRIGGER SECURITY.RoleTrigger_insert_delete
ON SECURITY.roles
AFTER INSERT, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if it's an insert operation
    IF EXISTS (SELECT * FROM inserted)
    BEGIN
        -- Get the role id, role name, and is_active from the inserted records
        DECLARE @RoleIdInsert INT;
        DECLARE @RoleNameInsert VARCHAR(255);
        DECLARE @IsActive BIT;

        -- Use a cursor to iterate over the inserted records
        DECLARE cursor_inserted CURSOR FOR
        SELECT role_id, role_name, is_active FROM inserted;

        OPEN cursor_inserted;

        FETCH NEXT FROM cursor_inserted INTO @RoleIdInsert, @RoleNameInsert, @IsActive;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Check if the role exists
            IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE type = 'R' AND name = @RoleNameInsert)
            BEGIN
                -- Create the role dynamically
                DECLARE @CreateRoleSQL NVARCHAR(MAX);
                SET @CreateRoleSQL = 'CREATE ROLE ' + QUOTENAME(@RoleNameInsert) + ';';
                EXEC sp_executesql @CreateRoleSQL;
            END;

            FETCH NEXT FROM cursor_inserted INTO @RoleIdInsert, @RoleNameInsert, @IsActive;
        END;

        CLOSE cursor_inserted;
        DEALLOCATE cursor_inserted;
    END;
    
    -- Check if it's a delete operation
    IF EXISTS (SELECT * FROM deleted)
    BEGIN
        -- Get the role name from the deleted records
        DECLARE @RoleNameDelete VARCHAR(255);

        -- Use a cursor to iterate over the deleted records
        DECLARE cursor_deleted CURSOR FOR
        SELECT role_name FROM deleted;

        OPEN cursor_deleted;

        FETCH NEXT FROM cursor_deleted INTO @RoleNameDelete;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Check if the role exists
            IF EXISTS (SELECT 1 FROM sys.database_principals WHERE type = 'R' AND name = @RoleNameDelete)
            BEGIN
                -- Drop the role dynamically
                DECLARE @DropRoleSQL NVARCHAR(MAX);
                SET @DropRoleSQL = 'DROP ROLE ' + QUOTENAME(@RoleNameDelete) + ';';
                EXEC sp_executesql @DropRoleSQL;
            END;

            FETCH NEXT FROM cursor_deleted INTO @RoleNameDelete;
        END;

        CLOSE cursor_deleted;
        DEALLOCATE cursor_deleted;
    END;
END;


-- DROP trigger
-- DROP TRIGGER SECURITY.RoleTrigger_insert_delete;
-- DROP TRIGGER SECURITY.RoleTrigger_update;
/*SELECT 
    name AS trigger_name,
    is_disabled AS trigger_disabled,
    create_date AS trigger_created_date,
    modify_date AS trigger_last_modified_date
FROM sys.triggers
WHERE parent_class = 1 -- 1 indicates a table object
    AND parent_id = OBJECT_ID('SECURITY.roles'); -- Replace 'YourSchema.YourTable' with the actual schema and table name
*/

-- CREATE OR ALTER TRIGGER RoleTrigger_update
CREATE OR ALTER TRIGGER SECURITY.RoleTrigger_update
ON SECURITY.roles
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if the specific columns have been modified
    IF UPDATE(role_name) OR UPDATE(is_active)
    BEGIN
        -- Iterate over the updated records
        DECLARE @UpdatedRoleId INT;
        DECLARE @UpdatedRoleName VARCHAR(255);
        DECLARE @UpdatedIsActive BIT;

        DECLARE cursor_updated CURSOR FOR
        SELECT role_id, role_name, is_active FROM inserted;

        OPEN cursor_updated;
        FETCH NEXT FROM cursor_updated INTO @UpdatedRoleId, @UpdatedRoleName, @UpdatedIsActive;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Check if the updated role exists
            IF UPDATE(role_name)
            BEGIN
                -- Only attempt to create the role if it doesn't already exist
                IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE type = 'R' AND name = @UpdatedRoleName)
                BEGIN
                    -- Create the role dynamically
                    DECLARE @CreateRoleSQL2 NVARCHAR(MAX);
                    SET @CreateRoleSQL2 = 'CREATE ROLE ' + QUOTENAME(@UpdatedRoleName) + ';';
                    EXEC sp_executesql @CreateRoleSQL2;
                END;
            END;
            ELSE
            BEGIN
                IF @UpdatedIsActive = 0
                BEGIN
                    -- Delete the role from the role_permission relations
                    DELETE FROM SECURITY.role_permissions
                    WHERE role_id = @UpdatedRoleId;
                END;
            END;

            FETCH NEXT FROM cursor_updated INTO @UpdatedRoleId, @UpdatedRoleName, @UpdatedIsActive;
        END;

        CLOSE cursor_updated;
        DEALLOCATE cursor_updated;
    END;
END;
