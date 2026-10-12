-- 1. Monthly claims and payment summary.
WITH claim_summary AS (
    SELECT DATE_TRUNC('month', service_date)::DATE AS service_month,
           COUNT(*) AS claim_count,
           SUM(billed_amount)::NUMERIC(14,2) AS billed_total,
           SUM(approved_amount)::NUMERIC(14,2) AS approved_total
    FROM claims
    GROUP BY DATE_TRUNC('month', service_date)::DATE
),
payment_summary AS (
    SELECT DATE_TRUNC('month', p.payment_date)::DATE AS payment_month,
           SUM(p.disbursement_amount) FILTER (WHERE p.payment_status = 'CLEARED')::NUMERIC(14,2)
               AS cleared_disbursement_total
    FROM payments p
    GROUP BY DATE_TRUNC('month', p.payment_date)::DATE
)
SELECT COALESCE(c.service_month, p.payment_month) AS month,
       c.claim_count, c.billed_total, c.approved_total,
       p.cleared_disbursement_total
FROM claim_summary c
FULL OUTER JOIN payment_summary p ON p.payment_month = c.service_month
ORDER BY month;

-- 2. Full audit trail for a claim (replace 1002 with the claim_id to investigate).
SELECT c.claim_number, c.service_date, c.claim_status,
       cl.line_number, cl.procedure_code, cl.billed_amount AS line_billed,
       cl.approved_amount AS line_approved,
       p.payment_number, p.payment_date, p.payment_status,
       pa.allocated_amount, pa.allocation_status
FROM claims c
LEFT JOIN claim_lines cl ON cl.claim_id = c.claim_id
LEFT JOIN payment_allocations pa ON pa.claim_id = c.claim_id
LEFT JOIN payments p ON p.payment_id = pa.payment_id
WHERE c.claim_id = 1002
ORDER BY cl.line_number, p.payment_date;

-- 3. Exception counts by category (based on claim-level reconciliation rules).
WITH claim_totals AS (
    SELECT c.claim_id, c.approved_amount,
           COALESCE(SUM(cl.approved_amount),0)::NUMERIC(12,2) AS line_approved
    FROM claims c
    LEFT JOIN claim_lines cl ON cl.claim_id = c.claim_id
    GROUP BY c.claim_id, c.approved_amount
),
payment_totals AS (
    SELECT pa.claim_id,
           SUM(pa.allocated_amount)::NUMERIC(12,2) AS allocated
    FROM payment_allocations pa
    JOIN payments p ON p.payment_id = pa.payment_id
    WHERE pa.allocation_status = 'ALLOCATED'
      AND p.payment_status IN ('ISSUED','CLEARED')
    GROUP BY pa.claim_id
),
exceptions AS (
    SELECT c.claim_id,
           CASE
             WHEN ct.line_approved <> c.approved_amount THEN 'LINE_TOTAL_MISMATCH'
             WHEN COALESCE(pt.allocated,0) = 0 AND c.approved_amount > 0 THEN 'UNPAID'
             WHEN COALESCE(pt.allocated,0) < c.approved_amount THEN 'UNDERPAID'
             WHEN COALESCE(pt.allocated,0) > c.approved_amount THEN 'OVERPAID'
             ELSE 'RECONCILED'
           END AS exception_type
    FROM claims c
    JOIN claim_totals ct ON ct.claim_id = c.claim_id
    LEFT JOIN payment_totals pt ON pt.claim_id = c.claim_id
)
SELECT exception_type, COUNT(*) AS claim_count
FROM exceptions
GROUP BY exception_type
ORDER BY claim_count DESC, exception_type;

-- 4. Window function: rank providers by approved claim amount.
SELECT provider_name, approved_total,
       DENSE_RANK() OVER (ORDER BY approved_total DESC) AS provider_rank
FROM (
    SELECT pr.provider_name, SUM(c.approved_amount)::NUMERIC(14,2) AS approved_total
    FROM providers pr
    JOIN claims c ON c.provider_id = pr.provider_id
    GROUP BY pr.provider_id, pr.provider_name
) s
ORDER BY provider_rank, provider_name;
