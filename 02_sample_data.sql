-- Synthetic sample data. Intentional exceptions are documented below.
INSERT INTO members VALUES
(1,'M1001','Avery','Morgan','1985-04-12','ACTIVE'),
(2,'M1002','Jordan','Lee','1972-09-03','ACTIVE'),
(3,'M1003','Casey','Patel','1991-01-22','ACTIVE'),
(4,'M1004','Taylor','Reed','2000-06-14','INACTIVE');

INSERT INTO providers VALUES
(10,'1234567890','Northside Family Clinic','PRIMARY_CARE','IN_NETWORK'),
(11,'2345678901','Lakeview Imaging Center','IMAGING','IN_NETWORK'),
(12,'3456789012','Cedar Orthopedics','SPECIALIST','OUT_OF_NETWORK');

INSERT INTO claims VALUES
(1001,'CLM-1001',1,10,'2026-01-05','2026-01-08','PAID',200.00,160.00,'USD'),
(1002,'CLM-1002',2,11,'2026-01-07','2026-01-10','PARTIALLY_PAID',500.00,400.00,'USD'),
(1003,'CLM-1003',3,12,'2026-01-09','2026-01-12','APPROVED',300.00,250.00,'USD'),
(1004,'CLM-1004',1,10,'2026-01-05','2026-01-13','PAID',200.00,160.00,'USD'), -- duplicate candidate
(1005,'CLM-1005',4,11,'2026-01-15','2026-01-17','APPROVED',150.00,120.00,'USD'),
(1006,'CLM-1006',2,10,'2026-01-18','2026-01-20','PAID',100.00,80.00,'USD');

INSERT INTO claim_lines VALUES
(5001,1001,1,'99213',1,120.00,100.00),
(5002,1001,2,'87070',1,80.00,60.00),
(5003,1002,1,'72148',1,500.00,400.00),
(5004,1003,1,'73030',1,300.00,250.00),
(5005,1004,1,'99213',1,120.00,100.00),
(5006,1004,2,'87070',1,80.00,60.00),
(5007,1005,1,'77067',1,150.00,120.00),
(5008,1006,1,'99214',1,100.00,80.00);

INSERT INTO payments VALUES
(9001,'PAY-9001','2026-01-20','EFT','CLEARED',160.00,'USD'),
(9002,'PAY-9002','2026-01-22','CHECK','ISSUED',250.00,'USD'),
(9003,'PAY-9003','2026-01-25','EFT','CLEARED',350.00,'USD'),
(9004,'PAY-9004','2026-01-26','EFT','VOID',80.00,'USD'),
(9005,'PAY-9005','2026-01-27','EFT','CLEARED',25.00,'USD'); -- unallocated payment

INSERT INTO payment_allocations VALUES
(7001,9001,1001,160.00,'ALLOCATED'),
(7002,9002,1003,250.00,'ALLOCATED'),
(7003,9003,1002,350.00,'ALLOCATED'), -- underpayment vs approved amount
(7004,9004,1006,80.00,'ALLOCATED'); -- allocation tied to void payment

-- Expected demonstration findings:
-- * Claims 1001 and 1004 are duplicate candidates.
-- * Claim 1002 is underpaid by 50.00.
-- * Claim 1003 is reconciled at 250.00.
-- * Claims 1005 and 1006 are unpaid / need review.
-- * Payment 9005 has no allocation.
-- * Payment 9004 is void but still has an allocation.
