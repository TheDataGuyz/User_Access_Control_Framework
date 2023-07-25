-- CREATE TRIGGER AddRemoveRoleMemberTrigger(trigger 1)
CREATE OR ALTER TRIGGER AddRemoveRoleMemberTrigger
ON SECURITY.user_roles
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Check if it's an insert operation
    IF EXISTS (SELECT * FROM inserted)
    BEGIN
        -- Get the role id and member name from the inserted records
        DECLARE @RoleIdInsert INT;
        DECLARE @UserIdInsert INT;
		DECLARE @is_active BIT;

        -- Use a cursor to iterate over the inserted records
        DECLARE cursor_inserted CURSOR FOR
        SELECT role_id, user_id,is_active FROM inserted;

        OPEN cursor_inserted;

        FETCH NEXT FROM cursor_inserted INTO @RoleIdInsert, @UserIdInsert,@is_active;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Check if the user exists

		IF @is_active=1
		BEGIN
		/*
            IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE [name] = @UserNameInsert AND [type] IN ('U', 'S'))
            BEGIN
                -- Create the user dynamically
                DECLARE @CreateUserSQL NVARCHAR(MAX) = 'CREATE USER ' + QUOTENAME(@UserNameInsert) + ' WITHOUT LOGIN;';
                EXEC sp_executesql @CreateUserSQL;
            END;
		*/

            -- Add the user to the role
            DECLARE @RoleNameInsert NVARCHAR(50) = (SELECT role_name FROM SECURITY.roles WHERE role_id = @RoleIdInsert);
			DECLARE @UserNameInsert NVARCHAR(50) = (SELECT user_name FROM SECURITY.users WHERE user_id = @UserIdInsert);
            DECLARE @AddRoleMemberSQL NVARCHAR(MAX) = 'ALTER ROLE ' + QUOTENAME(@RoleNameInsert) + ' ADD MEMBER ' + QUOTENAME(@UserNameInsert) + ';';
            EXEC sp_executesql @AddRoleMemberSQL;

            
        END;
		

		IF @is_active=0
		BEGIN

			DECLARE @RoleNameDelete NVARCHAR(50) = (SELECT role_name FROM SECURITY.roles WHERE role_id = @RoleIdInsert);
			DECLARE @UserNameDelete NVARCHAR(50) = (SELECT user_name FROM SECURITY.users WHERE user_id = @UserIdInsert);
			DECLARE @DeleteRoleMemberSQL NVARCHAR(MAX) = 'ALTER ROLE ' + QUOTENAME(@RoleNameDelete) + ' DROP MEMBER ' + QUOTENAME(@UserNameInsert) + ';';
			EXEC sp_executesql @DeleteRoleMemberSQL;

		END
		FETCH NEXT FROM cursor_inserted INTO @RoleIdInsert, @UserIdInsert,@is_active;
		END;

        CLOSE cursor_inserted;
        DEALLOCATE cursor_inserted;
    END
    ELSE
    BEGIN
        ----------------------------------------------------------------------------------
        -- Check if it's a delete operation
        IF EXISTS (SELECT * FROM deleted)
        BEGIN
            DECLARE @RoleIdDelete INT;
            DECLARE @UserIdDelete INT;

            -- Use a cursor to iterate over the deleted records
            DECLARE cursor_deleted CURSOR FOR
            SELECT role_id, user_id FROM deleted;

            OPEN cursor_deleted;

            FETCH NEXT FROM cursor_deleted INTO @RoleIdDelete, @UserIdDelete;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- DELETE the user from the role
                DECLARE @RoleName_Delete NVARCHAR(50) = (SELECT role_name FROM SECURITY.roles WHERE role_id = @RoleIdDelete);
				DECLARE @UserName_Delete NVARCHAR(50) = (SELECT user_name FROM SECURITY.users WHERE user_id = @UserIdDelete);
                DECLARE @DeleteRole_MemberSQL NVARCHAR(MAX) = 'ALTER ROLE ' + QUOTENAME(@RoleName_Delete) + ' DROP MEMBER ' + QUOTENAME(@UserName_Delete) + ';';
                EXEC sp_executesql @DeleteRole_MemberSQL;

                FETCH NEXT FROM cursor_deleted INTO @RoleIdDelete, @UserIdDelete;
            END;

            CLOSE cursor_deleted;
            DEALLOCATE cursor_deleted;
        END
        ELSE
        BEGIN
            ----------------------------------------------------------------------------------
            -- Check if the specific columns that influence role membership have been modified
            IF UPDATE(role_id) OR UPDATE(user_id)
            BEGIN
                SET NOCOUNT ON;

                -- Iterate over the updated records
                DECLARE @UpdatedRoleId INT;
                DECLARE @UpdatedUserId INT;

                DECLARE cursor_updated CURSOR FOR
                SELECT d.role_id, d.user_id,d.is_active,i.role_id, i.user_id,i.is_active
                FROM deleted d
                JOIN inserted i ON d.user_role_id = i.user_role_id;

                OPEN cursor_updated;
                FETCH NEXT FROM cursor_updated INTO @UpdatedRoleId, @UpdatedUserId,@is_active;
				
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    -- Check if the updated user exists

					IF @is_active=1
					BEGIN 
					/*
                    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE [name] = @UserName_Update AND [type] IN ('U', 'S'))
                    BEGIN
                        -- Create the updated user dynamically
                        DECLARE @UpdateCreateUserSQL NVARCHAR(MAX) = N'CREATE USER ' + QUOTENAME(@UpdatedUserName) + N' WITHOUT LOGIN;';
                        EXEC sp_executesql @UpdateCreateUserSQL;
                    END;
					*/

                    -- Add the updated user to the updated role
                    DECLARE @UpdateRoleName NVARCHAR(50) = (SELECT role_name FROM SECURITY.roles WHERE role_id = @UpdatedRoleId);
					DECLARE @UserName_Update NVARCHAR(50) = (SELECT user_name FROM SECURITY.users WHERE user_id = @UpdatedUserId);
                    DECLARE @UpdateAddRoleMemberSQL NVARCHAR(MAX) = N'ALTER ROLE ' + QUOTENAME(@UpdateRoleName) + N' ADD MEMBER ' + QUOTENAME(@UserName_Update) + N';';
                    EXEC sp_executesql @UpdateAddRoleMemberSQL;
					END

                    FETCH NEXT FROM cursor_updated INTO @UpdatedRoleId, @UpdatedUserId,@is_active;
                END;

                CLOSE cursor_updated;
                DEALLOCATE cursor_updated;
            END;
        END;
    END;
END;



-- DROP trigger
-- DROP TRIGGER SECURITY.AddRemoveRoleMemberTrigger;
-- DROP TRIGGER SECURITY.AfterUpdateTrigger;




-- CREATE TRIGGER AfterUpdateTrigger(trigger 2)
CREATE OR ALTER TRIGGER AfterUpdateTrigger
ON SECURITY.user_roles
AFTER UPDATE
AS
BEGIN
    -- Check if it's a delete operation

    IF EXISTS (SELECT * FROM deleted)
    BEGIN
        -- Check if role_id or user_name columns are updated
        IF UPDATE(role_id) OR UPDATE(user_id)
        BEGIN
            DECLARE @RoleIdDelete INT;
            DECLARE @UserIdDelete INT;
			DECLARE @is_active BIT;

            -- Use a cursor to iterate over the deleted records
            DECLARE cursor_deleted CURSOR FOR
            SELECT role_id, user_id FROM deleted;

            OPEN cursor_deleted;

            FETCH NEXT FROM cursor_deleted INTO @RoleIdDelete, @UserIdDelete;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- DELETE the user from the role

			IF @is_active=0
			BEGIN 
                DECLARE @DeleteRoleMemberSQL NVARCHAR(MAX) = 'ALTER ROLE ' + QUOTENAME((SELECT role_name FROM SECURITY.roles WHERE role_id = @RoleIdDelete)) 
															+ ' DROP MEMBER ' + QUOTENAME((SELECT user_name FROM SECURITY.users WHERE user_id = @UserIdDelete)) + ';';
                EXEC sp_executesql @DeleteRoleMemberSQL;
			END

                FETCH NEXT FROM cursor_deleted INTO @RoleIdDelete, @UserIdDelete;
            END;

            CLOSE cursor_deleted;
            DEALLOCATE cursor_deleted;
        END;
    END;
END;