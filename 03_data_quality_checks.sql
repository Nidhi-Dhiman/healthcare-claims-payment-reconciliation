-- 1. Duplicate claim candidates: same member, provider, service date, billed amount.
-- A candidate requires business review; it is not proof of duplication.
SELECT
    member_id, provider_id, service_date, billed_amount,
    COUNT(*) AS claim_count,
    ARRAY_AGG(claim_number ORDER BY claim_number) AS claim_numbers
FROM claims
GROUP BY member_id, provider_id, service_date, billed_amount
HAVING COUNT(*) > 1
ORDER BY claim_count DESC, member_id;

-- 2. Claim-header vs claim-line amount mismatches.
SELECT
    c.claim_id, c.claim_number,
    c.billed_amount AS header_billed,
    COALESCE(SUM(cl.billed_amount),0) AS line_billed,
    c.approved_amount AS header_approved,
    COALESCE(SUM(cl.approved_amount),0) AS line_approved
FROM claims c
LEFT JOIN claim_lines cl ON cl.claim_id = c.claim_id
GROUP BY c.claim_id, c.claim_number, c.billed_amount, c.approved_amount
HAVING c.billed_amount <> COALESCE(SUM(cl.billed_amount),0)
    OR c.approved_amount <> COALESCE(SUM(cl.approved_amount),0)
ORDER BY c.claim_id;

-- 3. Inactive members with claims.
SELECT c.claim_number, m.member_number, m.coverage_status, c.service_date
FROM claims c
JOIN members m ON m.member_id = c.member_id
WHERE m.coverage_status <> 'ACTIVE'
ORDER BY c.service_date;

-- 4. Allocations linked to void/reversed payments.
SELECT p.payment_number, p.payment_status, pa.claim_id, pa.allocated_amount, pa.allocation_status
FROM payment_allocations pa
JOIN payments p ON p.payment_id = pa.payment_id
WHERE p.payment_status IN ('VOID','REVERSED')
   OR pa.allocation_status = 'REVERSED'
ORDER BY p.payment_number;

-- 5. Payments without allocations.
SELECT p.payment_id, p.payment_number, p.payment_date, p.disbursement_amount, p.payment_status
FROM payments p
LEFT JOIN payment_allocations pa ON pa.payment_id = p.payment_id
WHERE pa.allocation_id IS NULL
ORDER BY p.payment_date;
