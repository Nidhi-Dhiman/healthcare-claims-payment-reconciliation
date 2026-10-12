-- Claim-level reconciliation.
-- Include only active allocations linked to payments that are not void/reversed.
-- For a real payment ledger, the treatment of issued vs cleared payments must be agreed with Finance.
WITH approved AS (
    SELECT c.claim_id, c.claim_number, c.member_id, c.provider_id,
           c.service_date, c.claim_status, c.approved_amount,
           COALESCE(SUM(cl.approved_amount),0)::NUMERIC(12,2) AS line_approved_amount
    FROM claims c
    LEFT JOIN claim_lines cl ON cl.claim_id = c.claim_id
    GROUP BY c.claim_id, c.claim_number, c.member_id, c.provider_id,
             c.service_date, c.claim_status, c.approved_amount
),
allocated AS (
    SELECT pa.claim_id,
           SUM(pa.allocated_amount)::NUMERIC(12,2) AS allocated_amount
    FROM payment_allocations pa
    JOIN payments p ON p.payment_id = pa.payment_id
    WHERE pa.allocation_status = 'ALLOCATED'
      AND p.payment_status IN ('ISSUED','CLEARED')
    GROUP BY pa.claim_id
),
recon AS (
    SELECT a.*,
           COALESCE(al.allocated_amount,0)::NUMERIC(12,2) AS allocated_amount,
           (COALESCE(al.allocated_amount,0) - a.approved_amount)::NUMERIC(12,2) AS variance
    FROM approved a
    LEFT JOIN allocated al ON al.claim_id = a.claim_id
)
SELECT
    r.claim_number,
    m.member_number,
    pr.provider_name,
    r.service_date,
    r.claim_status,
    r.approved_amount,
    r.line_approved_amount,
    r.allocated_amount,
    r.variance,
    CASE
        WHEN r.line_approved_amount <> r.approved_amount THEN 'REVIEW_LINE_TOTAL_MISMATCH'
        WHEN r.allocated_amount = 0 AND r.approved_amount > 0 THEN 'UNPAID'
        WHEN r.allocated_amount < r.approved_amount THEN 'UNDERPAID'
        WHEN r.allocated_amount > r.approved_amount THEN 'OVERPAID'
        ELSE 'RECONCILED'
    END AS reconciliation_status
FROM recon r
JOIN members m ON m.member_id = r.member_id
JOIN providers pr ON pr.provider_id = r.provider_id
ORDER BY
    CASE
        WHEN r.line_approved_amount <> r.approved_amount THEN 1
        WHEN r.allocated_amount = 0 AND r.approved_amount > 0 THEN 2
        WHEN r.allocated_amount <> r.approved_amount THEN 3
        ELSE 4
    END,
    r.claim_number;

-- Payment-level reconciliation: disbursement header vs allocations.
-- For CLEARED payments, this checks whether the full payment amount is allocated.
WITH allocation_totals AS (
    SELECT p.payment_id, p.payment_number, p.payment_date, p.payment_status,
           p.disbursement_amount,
           COALESCE(SUM(pa.allocated_amount) FILTER (WHERE pa.allocation_status = 'ALLOCATED'),0)::NUMERIC(12,2)
               AS allocated_amount
    FROM payments p
    LEFT JOIN payment_allocations pa ON pa.payment_id = p.payment_id
    GROUP BY p.payment_id, p.payment_number, p.payment_date, p.payment_status, p.disbursement_amount
)
SELECT *,
       (allocated_amount - disbursement_amount)::NUMERIC(12,2) AS variance,
       CASE
           WHEN payment_status IN ('VOID','REVERSED') AND allocated_amount > 0 THEN 'VOID_OR_REVERSED_WITH_ALLOCATION'
           WHEN payment_status = 'CLEARED' AND allocated_amount <> disbursement_amount THEN 'CLEARED_AMOUNT_MISMATCH'
           WHEN allocated_amount = 0 THEN 'UNALLOCATED'
           WHEN payment_status = 'ISSUED' THEN 'ISSUED_NOT_CLEARED'
           ELSE 'REVIEW'
       END AS payment_reconciliation_status
FROM allocation_totals
ORDER BY payment_date, payment_number;
