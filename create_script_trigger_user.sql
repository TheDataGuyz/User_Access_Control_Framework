-- CREATE TRIGGER UserTrigger
CREATE OR ALTER TRIGGER UserTrigger_insert_delete
ON SECURITY.users
AFTER INSERT, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    -- Check if it's an insert operation
    IF EXISTS (SELECT * FROM inserted)
    BEGIN
        -- Get the user id, user name, and password from the inserted records
        DECLARE @UserIdInsert INT;
        DECLARE @UserNameInsert VARCHAR(255);
        DECLARE @UserPasswordInsert VARCHAR(255);
        DECLARE @is_active BIT;

        -- Use a cursor to iterate over the inserted records
        DECLARE cursor_inserted CURSOR FOR
        SELECT user_id, user_name, password, is_active FROM inserted;

        OPEN cursor_inserted;

        FETCH NEXT FROM cursor_inserted INTO @UserIdInsert, @UserNameInsert, @UserPasswordInsert, @is_active;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Check if the user exists
            IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @UserNameInsert AND type = 'U')
            BEGIN
                -- Create the user dynamically
                DECLARE @CreateUserSQL NVARCHAR(MAX);
                IF @UserPasswordInsert IS NULL
                BEGIN
                    SET @CreateUserSQL = 'CREATE USER ' + QUOTENAME(@UserNameInsert) + ' WITHOUT LOGIN;';
                END
                ELSE
                BEGIN
                    SET @CreateUserSQL = 'CREATE USER ' + QUOTENAME(@UserNameInsert) + ' WITH PASSWORD = ' + QUOTENAME(@UserPasswordInsert, '''') + ';';
                END
                EXEC sp_executesql @CreateUserSQL;
            END;

            FETCH NEXT FROM cursor_inserted INTO @UserIdInsert, @UserNameInsert, @UserPasswordInsert, @is_active;
        END;

        CLOSE cursor_inserted;
        DEALLOCATE cursor_inserted;
    END
    ELSE
    BEGIN
        -- Check if it's a delete operation
        IF EXISTS (SELECT * FROM deleted)
        BEGIN
            -- Use a cursor to iterate over the deleted records
            DECLARE @UserIdDelete INT;
            DECLARE @UserNameDelete VARCHAR(255);

            DECLARE cursor_deleted CURSOR FOR
            SELECT user_id, user_name FROM deleted;

            OPEN cursor_deleted;

            FETCH NEXT FROM cursor_deleted INTO @UserIdDelete, @UserNameDelete;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Delete the user from the database and the user_role relations
                DELETE FROM SECURITY.user_roles
                WHERE user_id = @UserIdDelete;

                DECLARE @DeleteUserSQL NVARCHAR(MAX);
                SET @DeleteUserSQL = 'DROP USER ' + QUOTENAME(@UserNameDelete) + ';';
                EXEC sp_executesql @DeleteUserSQL;

                FETCH NEXT FROM cursor_deleted INTO @UserIdDelete, @UserNameDelete;
            END;

            CLOSE cursor_deleted;
            DEALLOCATE cursor_deleted;
        END;
    END;
END;



-- DROP trigger
-- DROP TRIGGER SECURITY.UserTrigger_insert_delete;
-- DROP TRIGGER SECURITY.UserTrigger_update;


CREATE OR ALTER TRIGGER UserTrigger_update
ON SECURITY.users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
        BEGIN
            -- Check if the specific columns have been modified
            IF UPDATE(user_name) OR UPDATE(is_active)
            BEGIN
                -- Iterate over the updated records
                DECLARE @UpdatedUserId INT;
                DECLARE @UpdatedUserName VARCHAR(255);
				DECLARE @UserPasswordInsert VARCHAR(255);
                DECLARE @UpdatedIsActive BIT;

                DECLARE cursor_updated CURSOR FOR
                SELECT user_id, user_name, is_active FROM inserted;

                OPEN cursor_updated;
                FETCH NEXT FROM cursor_updated INTO @UpdatedUserId, @UpdatedUserName, @UpdatedIsActive;

                WHILE @@FETCH_STATUS = 0
                BEGIN
                    -- Check if the updated user exists
                    IF UPDATE(user_name)
                    BEGIN
                        -- Only attempt to create the user if it doesn't already exist
                        IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @UpdatedUserName AND type = 'U')
                        BEGIN
                            -- Create the user dynamically
                            DECLARE @CreateUserSQL2 NVARCHAR(MAX);
                            IF @UserPasswordInsert IS NULL
                            BEGIN
                                SET @CreateUserSQL2 = 'CREATE USER ' + QUOTENAME(@UpdatedUserName) + ' WITHOUT LOGIN;';
                            END
                            ELSE
                            BEGIN
                                SET @CreateUserSQL2 = 'CREATE USER ' + QUOTENAME(@UpdatedUserName) + ' WITH PASSWORD = ' + QUOTENAME(@UserPasswordInsert, '''') + ';';
                            END
                            EXEC sp_executesql @CreateUserSQL2;
                        END;
                    END;
                    ELSE
                    BEGIN
                        IF @UpdatedIsActive = 0
                        BEGIN
                            -- Delete the user from the user_role relations
                            DELETE FROM SECURITY.user_roles
                            WHERE user_id = @UpdatedUserId;
                        END;
                    END;

                    FETCH NEXT FROM cursor_updated INTO @UpdatedUserId, @UpdatedUserName, @UpdatedIsActive;
                END;

                CLOSE cursor_updated;
                DEALLOCATE cursor_updated;
            END;
        END;
END;


