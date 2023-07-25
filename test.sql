-- CHECK EMPLOYEE TABLE
SELECT * FROM dbo.employees;

SELECT TABLE_SCHEMA, table_name FROM INFORMATION_SCHEMA.TABLES;


-- CHECK USER TABLE
SELECT * FROM SECURITY.users;
SELECT * FROM SECURITY.roles;
SELECT * FROM SECURITY.role_permissions ORDER BY role_id;

-- TRUNCATE TABLE
--DELETE FROM SECURITY.users;

-- TEST INSERT TRIGGER
INSERT INTO SECURITY.users (user_name, role_id, is_active)
values('pranaou', 2, 1);

INSERT INTO SECURITY.users (user_name, role_id, is_active)
values('pranaou', 4, 1);

EXECUTE AS user = 'pranaou';
SELECT * FROM dbo.employees;

REVERT;

SELECT name FROM sys.database_principals WHERE type = 'R';


-- TEST DELETE TRIGGER
UPDATE SECURITY.users
SET is_active = 0
WHERE 1=1
AND user_name = 'pranaou'
AND role_id = 4;


EXECUTE AS user = 'pranaou';
SELECT * FROM dbo.employees;

REVERT;
SELECT * FROM SECURITY.users;

UPDATE SECURITY.users
SET is_active = 0
WHERE 1=1
AND user_name = 'pranaou';


EXECUTE AS user = 'pranaou';
SELECT * FROM dbo.employees;

REVERT;

-- TEST UPDATE TRIGGER - ROLE 
INSERT INTO SECURITY.users (user_name, role_id)
SELECT 'casey', role_id
FROM SECURITY.roles
WHERE role_id = 1;


UPDATE SECURITY.users SET user_name = 'cassie' 
WHERE 1=1
AND user_name = 'casey';

EXECUTE AS user = 'casey';
SELECT * FROM dbo.employees;


EXECUTE AS user = 'cassie';
SELECT * FROM dbo.employees;


REVERT;


	SELECT perm.permission_name,schema_name(obj.schema_id),obj.name,princ.name, * FROM sys.database_principals AS princ
	JOIN sys.database_permissions AS perm ON princ.principal_id = perm.grantee_principal_id
	JOIN sys.objects AS obj ON perm.major_id = obj.object_id
	WHERE princ.type = 'R'
	AND princ.name NOT IN ('public', 'db_owner', 'db_accessadmin', 'db_securityadmin', 
	'db_ddladmin', 'db_backupoperator', 'db_datareader', 'db_datawriter', 
	'db_denydatareader', 'db_denydatawriter');



INSERT INTO SECURITY.users (user_name, is_active)
values( 'van', 1);


EXECUTE AS user = 'casey';
EXECUTE AS user = 'pranaou';
SELECT * FROM dbo.employees;
revert;
SELECT * FROM SECURITY.user_roles


UPDATE SECURITY.users SET is_active = 1 WHERE user_name = 'pranaou';
INSERT INTO SECURITY.user_roles (user_id, role_id, is_active)
VALUES
    ((select user_id from SECURITY.users WHERE user_name = 'pranaou'), 4, 1)

DELETE FROM SECURITY.users WHERE user_name = 'van';

select * from SECURITY.users;

select * from SECURITY.roles;

revert;
SELECT u.user_name, r.role_name, ur.user_id,ur.role_id 
FROM SECURITY.user_roles ur
JOIN SECURITY.users u ON u.user_id = ur.user_id
JOIN SECURITY.roles r ON r.role_id =  ur.role_id;


select * from SECURITY.permissions;

INSERT INTO SECURITY.roles (role_name, description, is_active)
values( 'Audit' ,  'Users belonging to Audit can access Administration department data and also the unmasked BirthDate.',1  );


SELECT rp.is_active,r.role_name, rp.permission_id FROM SECURITY.role_permissions rp
JOIN SECURITY.permissions p ON p.permission_id = rp.permission_id
JOIN SECURITY.roles r ON r.role_id =  rp.role_id
WHERE 1=1 
AND r.role_name = 'Administration'
OR r.role_name = 'Audit';


INSERT INTO SECURITY.role_permissions (role_id, permission_id, is_active)
SELECT
    (SELECT role_id FROM SECURITY.roles WHERE role_name='Audit'),
    rp.permission_id,
    1 as is_active
FROM SECURITY.role_permissions rp
JOIN SECURITY.permissions p ON p.permission_id = rp.permission_id
JOIN SECURITY.roles r ON r.role_id = rp.role_id
WHERE r.role_name = 'Administration'
AND rp.is_active = 1;

CREATE ROLE Audit;

EXEC SECURITY.GrantAccessToRole;

INSERT INTO SECURITY.users (user_name, is_active)
values( 'van', 1);
INSERT INTO SECURITY.user_roles (user_id, role_id, is_active)
VALUES
    ((select user_id from SECURITY.users WHERE user_name = 'van'), (select role_id from SECURITY.roles WHERE role_name= 'Audit'), 1);



-- Add the 'Salary' column to the 'employees' table
ALTER TABLE dbo.employees
ADD Salary DECIMAL(10, 2);

-- Insert data into the 'Salary' column
UPDATE dbo.employees
SET Salary = 
    CASE 
        WHEN EmployeeID = 33 THEN 100000.00
        WHEN EmployeeID = 16 THEN 70000.00
        WHEN EmployeeID = 17 THEN 90000.00
        WHEN EmployeeID = 18 THEN 60000.00
        WHEN EmployeeID = 19 THEN 65000.00
        WHEN EmployeeID = 20 THEN 85000.00
        WHEN EmployeeID = 21 THEN 55000.00
        WHEN EmployeeID = 22 THEN 70000.00
        WHEN EmployeeID = 23 THEN 50000.00
        WHEN EmployeeID = 24 THEN 60000.00
        WHEN EmployeeID = 25 THEN 80000.00
        WHEN EmployeeID = 26 THEN 90000.00
        WHEN EmployeeID = 27 THEN 65000.00
        WHEN EmployeeID = 28 THEN 50000.00
        WHEN EmployeeID = 29 THEN 75000.00
        WHEN EmployeeID = 30 THEN 90000.00
        WHEN EmployeeID = 31 THEN 70000.00
        WHEN EmployeeID = 32 THEN 50000.00
        WHEN EmployeeID = 34 THEN 75000.00
        WHEN EmployeeID = 35 THEN 60000.00
        WHEN EmployeeID = 36 THEN 55000.00
        ELSE NULL
    END;

	select* from security.permissions

INSERT INTO SECURITY.permissions (schema_name, object_name, column_name, row_filter)
VALUES
    ('dbo', 'Employees', 'Salary', NULL)

INSERT INTO SECURITY.role_permissions (role_id, permission_id, is_active)
SELECT r.role_id, p.permission_id, 0
FROM SECURITY.roles r
CROSS JOIN SECURITY.permissions p
WHERE p.column_name = 'Salary' AND r.is_active = 1;



SELECT r.role_name, p.permission_id, p.column_name
FROM SECURITY.roles r
JOIN SECURITY.role_permissions rp ON r.role_id = rp.role_id
JOIN SECURITY.permissions p ON rp.permission_id = p.permission_id;

EXEC SECURITY.GrantAccessToRole;

SELECT u.user_name, r.role_name
FROM SECURITY.user_roles ur
JOIN SECURITY.users u ON ur.user_id = u.user_id
JOIN SECURITY.roles r ON ur.role_id = r.role_id
WHERE u.is_active = 1
AND r.is_active = 1;



EXECUTE AS user = 'casey';
SELECT * FROM dbo.Orders;
revert;

EXECUTE AS user = 'pranaou';
SELECT * FROM dbo.Orders;

select * from SECURITY.role_permissions



