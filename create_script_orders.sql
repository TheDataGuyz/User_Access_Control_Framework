CREATE TABLE dbo.Orders (
  order_id INT PRIMARY KEY,
  customer_id INT,
  order_date DATE,
  total_amount DECIMAL(10, 2),
  shipping_address VARCHAR(255),
  status VARCHAR(20)
);
INSERT INTO dbo.Orders (order_id, customer_id, order_date, total_amount, shipping_address, status)
VALUES
  (1, 101, '2023-07-01', 49.99, '123 Main St, City, Country', 'shipped'),
  (2, 102, '2023-07-02', 79.99, '456 Elm St, City, Country', 'pending'),
  (3, 103, '2023-07-03', 29.99, '789 Oak St, City, Country', 'delivered'),
  (4, 101, '2023-07-04', 99.99, '321 Pine St, City, Country', 'shipped'),
  (5, 104, '2023-07-05', 19.99, '987 Maple St, City, Country', 'pending');

SELECT * FROM dbo.Orders;

INSERT INTO SECURITY.permissions (schema_name, object_name, column_name, row_filter)
VALUES
    ('dbo', 'Orders', NULL, NULL);

INSERT INTO SECURITY.role_permissions (role_id, permission_id, is_active)
SELECT r.role_id, p.permission_id, 1
FROM SECURITY.roles r
JOIN SECURITY.permissions p ON p.schema_name = 'dbo'
                             AND p.object_name = 'Orders'
                             AND p.column_name IS NULL
                             AND p.row_filter IS NULL
WHERE r.role_name = 'Sales';

SELECT r.role_name, rp.permission_id, rp.is_active,p.schema_name,p.object_name,p.column_name,p.row_filter
FROM SECURITY.role_permissions rp
JOIN SECURITY.roles r ON r.role_id = rp.role_id
JOIN SECURITY.permissions p ON p.permission_id = rp.permission_id
WHERE r.role_name = 'Sales';

EXEC SECURITY.GrantAccessToRole;