# Data dictionary

## `members`
One row per synthetic plan member.
- `member_id`: internal primary key.
- `member_number`: unique business identifier.
- `coverage_status`: ACTIVE, INACTIVE, or TERMINATED.

## `providers`
One row per healthcare provider.
- `provider_id`: internal primary key.
- `npi`: synthetic 10-character provider identifier used for this demo.
- `provider_type`: broad provider category.
- `network_status`: IN_NETWORK or OUT_OF_NETWORK.

## `claims`
One row per claim header.
- `claim_id`: internal primary key.
- `claim_number`: unique business claim identifier.
- `member_id`, `provider_id`: foreign keys.
- `service_date`, `received_date`: dates used for operational analysis.
- `claim_status`: claim processing state.
- `billed_amount`, `approved_amount`: header-level financial amounts.

## `claim_lines`
One row per claim line.
- `claim_line_id`: primary key.
- `claim_id`, `line_number`: identifies a line within a claim.
- `procedure_code`, `units`: synthetic procedure/service details.
- `billed_amount`, `approved_amount`: line-level financial amounts.

## `payments`
One row per disbursement instrument.
- `payment_id`: primary key.
- `payment_number`: unique payment identifier.
- `payment_status`: ISSUED, CLEARED, VOID, or REVERSED.
- `disbursement_amount`: payment-header amount.

## `payment_allocations`
Maps a payment to a claim and amount. This bridge supports a payment covering multiple claims and a claim receiving multiple payments.
- `allocation_id`: primary key.
- `payment_id`, `claim_id`: foreign keys.
- `allocated_amount`: amount assigned to the claim.
- `allocation_status`: ALLOCATED or REVERSED.

## Relationships
- `members` 1 → many `claims`
- `providers` 1 → many `claims`
- `claims` 1 → many `claim_lines`
- `payments` many ↔ many `claims` through `payment_allocations`

## Financial definitions
- **Approved amount:** claim header's approved amount.
- **Line approved amount:** sum of approved claim-line amounts.
- **Allocated amount:** sum of eligible allocations from payments whose status is ISSUED or CLEARED and whose allocation status is ALLOCATED.
- **Variance:** allocated amount minus approved amount; negative indicates underpayment and positive indicates overpayment.
