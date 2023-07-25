-- Create Function to let the users in different roles(departments) only can see their department records
CREATE or ALTER FUNCTION SECURITY.securitypredicate (@Department AS nvarchar(50))
    RETURNS TABLE
    WITH SCHEMABINDING
AS
RETURN 

    SELECT 1 AS securitypredicate_result
    WHERE 
    
        (@Department = 'Sales' AND IS_MEMBER('Sales')=1) OR
        (@Department = 'Engineering' AND IS_MEMBER('Engineering')=1) OR
        (@Department = 'Finance' AND IS_MEMBER('Finance')=1) OR
        (@Department = 'Administration' AND IS_MEMBER('Administration')=1) or
		(user_name()='dbo')
;
GO

--drop security policy EmployeesSecurityPolicy

CREATE SECURITY POLICY EmployeesSecurityPolicy
ADD FILTER PREDICATE SECURITY.securitypredicate(Department) ON dbo.employees
WITH (STATE = ON);
GO

-- Allow SELECT permissions to the securitypredicate function
GRANT SELECT ON SECURITY.securitypredicate TO Sales;
GRANT SELECT ON SECURITY.securitypredicate TO Engineering;
GRANT SELECT ON SECURITY.securitypredicate TO Finance;
GRANT SELECT ON SECURITY.securitypredicate TO Administration;
GO
-- Grant permissions based on table ownership
GRANT SELECT ON dbo.employees to Sales;
GRANT SELECT ON dbo.employees to Engineering;
GRANT SELECT ON dbo.employees to Finance;
GRANT SELECT ON dbo.employees to Administration;