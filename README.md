# Healthcare Claims & Payment Reconciliation (SQL Portfolio)

## Project overview
This portfolio project simulates a healthcare claims payment workflow. It models members, providers, claims, claim-line details, payments, and payment allocations so that claims can be reconciled against disbursements and exceptions can be investigated.

**Database:** PostgreSQL  
**Skills demonstrated:** Relational database modeling, primary and foreign key constraints, SQL joins, Common Table Expressions (CTEs), window functions, duplicate claim detection, claims-to-payment reconciliation, exception reporting, audit trail validation, and data quality checks.

> **Important:** This repository uses synthetic data only. It contains no real patient information and is not intended for clinical, billing, or production use.

## Business problem
A healthcare payer needs to confirm that:
1. Claims are not duplicated.
2. Approved claim amounts agree with payment allocations.
3. Payments and disbursements can be traced back to claims.
4. Unpaid, underpaid, overpaid, and orphaned transactions are flagged for review.
5. Reconciliation results can be reproduced and audited.

## Repository contents
- `sql/01_schema.sql` — creates tables, keys, and constraints.
- `sql/02_sample_data.sql` — inserts synthetic sample data, including intentional exceptions.
- `sql/03_data_quality_checks.sql` — duplicate and referential/data-quality checks.
- `sql/04_claim_payment_reconciliation.sql` — claim-level reconciliation and exception report.
- `sql/05_audit_queries.sql` — traceability and summary reporting.
- `docs/data_dictionary.md` — table and field descriptions.

## How to run
Run the scripts in order using PostgreSQL (for example, pgAdmin or psql):

```bash
psql -d healthcare_portfolio -f sql/01_schema.sql
psql -d healthcare_portfolio -f sql/02_sample_data.sql
psql -d healthcare_portfolio -f sql/03_data_quality_checks.sql
psql -d healthcare_portfolio -f sql/04_claim_payment_reconciliation.sql
psql -d healthcare_portfolio -f sql/05_audit_queries.sql
```

## Reconciliation logic
- **Expected amount:** sum of approved claim-line amounts for a claim.
- **Allocated amount:** sum of payment allocations linked to that claim.
- **Variance:** allocated amount minus expected amount.
- **Status:** `UNPAID`, `UNDERPAID`, `OVERPAID`, `RECONCILED`, or `REVIEW`.
- Duplicate candidates are identified using member, provider, service date, and billed amount. This is a review signal, not automatic proof of fraud or duplication.


