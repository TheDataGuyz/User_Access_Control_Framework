------------------Craete Scripts-------------------

-- Create users table
-- The password should be encrypted
CREATE TABLE SECURITY.users (
    user_id INT IDENTITY(1, 1) PRIMARY KEY,
    user_name VARCHAR(255),
    password VARCHAR(255),
    employee_id INT,
    is_active BIT
);
ALTER TABLE SECURITY.users
ADD CONSTRAINT UQ_user_name UNIQUE (user_name);

/*
UPDATE SECURITY.users
SET password = HASHBYTES('SHA2_256', password);
ALTER TABLE SECURITY.users
ALTER COLUMN password VARCHAR(255); -- Assuming the password column has a maximum length of 255 characters
*/

--Create roles table
CREATE TABLE SECURITY.roles (
  role_id INT IDENTITY(1,1) PRIMARY KEY,
  role_name VARCHAR(50) NOT NULL,
  description VARCHAR(255),
  is_active BIT,
  CONSTRAINT UQ_RoleName UNIQUE (role_name)
);


-- Create user_roles table and set constraint to make sure the uniqueness of the combination
-- Create the user-defined function
CREATE FUNCTION dbo.IsActiveUser(@user_id INT)
RETURNS BIT
AS
BEGIN
    DECLARE @is_active BIT;

    SELECT @is_active = is_active
    FROM SECURITY.users
    WHERE user_id = @user_id;

    RETURN CASE WHEN @is_active = 0 THEN 0 ELSE 1 END;
END;
GO

-- Create the user_roles table with the CHECK constraint
CREATE TABLE SECURITY.user_roles (
    user_role_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    role_id INT,
    FOREIGN KEY (role_id) REFERENCES SECURITY.roles(role_id),
    FOREIGN KEY (user_id) REFERENCES SECURITY.users(user_id),
    UNIQUE (user_id, role_id),
    is_active BIT,
    CHECK (dbo.IsActiveUser(user_id) = 1)
);


-- Create permissions table and set constraint to make sure the uniqueness of the combination
CREATE TABLE SECURITY.permissions (
    permission_id INT IDENTITY(1, 1) PRIMARY KEY,
    schema_name NVARCHAR(50) NOT NULL,
    object_name NVARCHAR(50) NOT NULL,
    column_name NVARCHAR(50) NULL,
    row_filter NVARCHAR(255) NULL,
);

ALTER TABLE [SECURITY].permissions
ADD CONSTRAINT [CHK_CombinationUniqueness] UNIQUE (
    [schema_name],
    [object_name],
    [column_name],
    [row_filter]
);

--CREATE TABLE SECURITY.role_permissions and set constraint to make sure the uniqueness of the combination
-- Create the user-defined function
CREATE FUNCTION dbo.IsActiveRole(@role_id INT)
RETURNS BIT
AS
BEGIN
    DECLARE @is_active BIT;

    SELECT @is_active = is_active
    FROM SECURITY.roles
    WHERE role_id = @role_id;

    RETURN CASE WHEN @is_active = 0 THEN 0 ELSE 1 END;
END;
GO

-- Create the role_permissions table with the CHECK constraint
CREATE TABLE SECURITY.role_permissions (
    role_permission_id INT IDENTITY(1,1) PRIMARY KEY,
    role_id INT NOT NULL,
    permission_id INT,
    FOREIGN KEY (role_id) REFERENCES SECURITY.roles(role_id),
    FOREIGN KEY (permission_id) REFERENCES SECURITY.permissions(permission_id),
    UNIQUE (role_id, permission_id),
    is_active BIT,
    CHECK (dbo.IsActiveRole(role_id) = 1)
);


------------------Drop Script-------------------
--DROP TABLE IF EXISTS SECURITY.users;
--DROP TABLE IF EXISTS SECURITY.roles;
--DROP TABLE IF EXISTS SECURITY.user_roles;
--DROP TABLE IF EXISTS SECURITY.permissions;
--DROP TABLE IF EXISTS SECURITY.role_permissions;

------------------Insert Values--------------------
INSERT INTO SECURITY.users (user_name, is_active)
VALUES
    ('casey', 1)


INSERT INTO SECURITY.roles (role_name, description, is_active)
VALUES
  ('Sales', 'Users can access Sales department data.',1),
  ('Engineering', 'Users can access Engineering department data.',1),
  ('Finance', 'Users can access Finance department data.',1),
  ('Administration', 'Users can access Administration department data and BirthDate column in employee table.',1);

INSERT INTO SECURITY.user_roles (user_id, role_id, is_active)
VALUES
    (1, 1, 1),
    (1, 2, 1),
	(1, 3, 1)

INSERT INTO SECURITY.permissions (schema_name, object_name, column_name, row_filter)
VALUES
    ('dbo', 'Employees', NULL, NULL),
    ('dbo', 'Employees', 'BirthDate', NULL),
	('dbo', 'Employees', NULL, 'where department = user.department');

INSERT INTO SECURITY.role_permissions (role_id, permission_id, is_active)
VALUES
    (1, 1, 1),
	(1, 3, 1),
	(2, 1, 1),    
	(2, 3, 1),
    (3, 1, 1),
	(3, 3, 1),
	(4, 1, 1),
	(4, 2, 1),
	(4, 3, 1);


---- Check the tables----
select * from SECURITY.users;
select * from SECURITY.roles;
select * from SECURITY.user_roles;
select * from SECURITY.permissions;
select * from SECURITY.role_permissions;

-- Create Roles based on their departments
/*
CREATE ROLE Sales;
CREATE ROLE Engineering;
CREATE ROLE Finance;
CREATE ROLE Administration;
*/

-- Check roles in database
/*
SELECT name
FROM sys.database_principals
WHERE type = 'R';

SELECT name AS user_name, type_desc AS user_type
FROM sys.database_principals
WHERE type IN ('U', 'S');

SELECT name AS role_name
FROM sys.database_principals
WHERE type = 'R';

*/

--DROP ROLES
/*
DROP ROLE Sales;
DROP ROLE Engineering;
DROP ROLE Finance;
DROP ROLE Administration;
DROP ROLE Audit;

SELECT 
    RM.member_principal_id AS member_id,
    DP.name AS member_name,
    RM.role_principal_id AS role_id,
    DR.name AS role_name
FROM sys.database_role_members RM
JOIN sys.database_principals DP ON DP.principal_id = RM.member_principal_id
JOIN sys.database_principals DR ON DR.principal_id = RM.role_principal_id
WHERE DR.name = 'Audit'; -- Replace 'Sales' with the name of the role you want to check

*/

/*
-- Add constraints
ALTER TABLE [SECURITY].[role_permissions]
ADD CONSTRAINT [CHK_CombinationUniqueness] UNIQUE (
    [schema_name],
    [object_name],
    [column_name],
    [row_name]
);

ALTER TABLE [SECURITY].[role_permissions]
ADD CONSTRAINT [CHK_ObjectNotNullWithColumns] CHECK (
    ([row_name] IS NOT NULL OR [column_name]IS NOT NULL)
    AND [object_name] IS NOT NULL
);

CREATE OR ALTER FUNCTION SECURITY.CheckSchemaPermissionCode (
    @schema_name NVARCHAR(50),
    @permission_code BIT
)
RETURNS BIT
AS
BEGIN
    DECLARE @hasConflict BIT;

    IF EXISTS (
        SELECT 1
        FROM [SECURITY].[role_permissions]
        WHERE [schema_name] = @schema_name
          AND [permission_code] = 1
          AND [object_name] IS NULL
          AND [column_name] IS NULL
          AND [row_name] IS NULL
    )
    BEGIN
        SET @hasConflict = 1;
    END
    ELSE
    BEGIN
        SET @hasConflict = 0;
    END;

    RETURN @hasConflict;
END;

ALTER TABLE [SECURITY].[role_permissions]
ADD CONSTRAINT [CHK_SchemaPermissionCode]
CHECK (
    [SECURITY].CheckSchemaPermissionCode([schema_name], [permission_code]) = 0
);

CREATE FUNCTION [SECURITY].CheckObjectOnlyPermission (
    @object_name NVARCHAR(50),
    @permission_code BIT
)
RETURNS BIT
AS
BEGIN
    DECLARE @hasConflict BIT;

    IF EXISTS (
        SELECT 1
        FROM [SECURITY].[role_permissions]
        WHERE [object_name] = @object_name
          AND [permission_code] = 1
          AND [column_name] IS NULL
          AND [row_name] IS NULL
    )
    BEGIN
        SET @hasConflict = 1;
    END
    ELSE
    BEGIN
        SET @hasConflict = 0;
    END;

    RETURN @hasConflict;
END;

ALTER TABLE [SECURITY].[role_permissions]
ADD CONSTRAINT [CHK_ObjectOnlyPermission]
CHECK (
    [SECURITY].CheckObjectOnlyPermission([object_name], [permission_code]) = 0
);
*/