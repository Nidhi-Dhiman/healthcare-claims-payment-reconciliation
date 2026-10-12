-- Healthcare Claims & Payment Reconciliation
-- PostgreSQL schema; synthetic portfolio data only.
DROP VIEW IF EXISTS v_claim_payment_reconciliation CASCADE;
DROP TABLE IF EXISTS payment_allocations CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS claim_lines CASCADE;
DROP TABLE IF EXISTS claims CASCADE;
DROP TABLE IF EXISTS providers CASCADE;
DROP TABLE IF EXISTS members CASCADE;

CREATE TABLE members (
    member_id       BIGINT PRIMARY KEY,
    member_number   VARCHAR(20) NOT NULL UNIQUE,
    first_name      VARCHAR(60) NOT NULL,
    last_name       VARCHAR(60) NOT NULL,
    date_of_birth   DATE NOT NULL,
    coverage_status VARCHAR(20) NOT NULL CHECK (coverage_status IN ('ACTIVE','INACTIVE','TERMINATED'))
);

CREATE TABLE providers (
    provider_id     BIGINT PRIMARY KEY,
    npi             VARCHAR(10) NOT NULL UNIQUE,
    provider_name   VARCHAR(120) NOT NULL,
    provider_type   VARCHAR(30) NOT NULL,
    network_status  VARCHAR(20) NOT NULL CHECK (network_status IN ('IN_NETWORK','OUT_OF_NETWORK'))
);

CREATE TABLE claims (
    claim_id          BIGINT PRIMARY KEY,
    claim_number      VARCHAR(30) NOT NULL UNIQUE,
    member_id         BIGINT NOT NULL REFERENCES members(member_id),
    provider_id       BIGINT NOT NULL REFERENCES providers(provider_id),
    service_date      DATE NOT NULL,
    received_date     DATE NOT NULL,
    claim_status      VARCHAR(20) NOT NULL CHECK (claim_status IN ('RECEIVED','PENDING','APPROVED','DENIED','PAID','PARTIALLY_PAID')),
    billed_amount     NUMERIC(12,2) NOT NULL CHECK (billed_amount >= 0),
    approved_amount   NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (approved_amount >= 0),
    currency_code     CHAR(3) NOT NULL DEFAULT 'USD',
    CHECK (received_date >= service_date - 365),
    CHECK (approved_amount <= billed_amount)
);

CREATE TABLE claim_lines (
    claim_line_id    BIGINT PRIMARY KEY,
    claim_id         BIGINT NOT NULL REFERENCES claims(claim_id),
    line_number      INTEGER NOT NULL CHECK (line_number > 0),
    procedure_code   VARCHAR(10) NOT NULL,
    units            NUMERIC(8,2) NOT NULL DEFAULT 1 CHECK (units > 0),
    billed_amount    NUMERIC(12,2) NOT NULL CHECK (billed_amount >= 0),
    approved_amount  NUMERIC(12,2) NOT NULL CHECK (approved_amount >= 0),
    UNIQUE (claim_id, line_number),
    CHECK (approved_amount <= billed_amount)
);

CREATE TABLE payments (
    payment_id       BIGINT PRIMARY KEY,
    payment_number   VARCHAR(30) NOT NULL UNIQUE,
    payment_date     DATE NOT NULL,
    payment_method   VARCHAR(20) NOT NULL CHECK (payment_method IN ('EFT','CHECK','VIRTUAL_CARD')),
    payment_status   VARCHAR(20) NOT NULL CHECK (payment_status IN ('ISSUED','CLEARED','VOID','REVERSED')),
    disbursement_amount NUMERIC(12,2) NOT NULL CHECK (disbursement_amount >= 0),
    currency_code    CHAR(3) NOT NULL DEFAULT 'USD'
);

-- One payment can fund multiple claims; one claim can receive multiple payments.
CREATE TABLE payment_allocations (
    allocation_id   BIGINT PRIMARY KEY,
    payment_id      BIGINT NOT NULL REFERENCES payments(payment_id),
    claim_id        BIGINT NOT NULL REFERENCES claims(claim_id),
    allocated_amount NUMERIC(12,2) NOT NULL CHECK (allocated_amount >= 0),
    allocation_status VARCHAR(20) NOT NULL CHECK (allocation_status IN ('ALLOCATED','REVERSED')),
    UNIQUE (payment_id, claim_id)
);

CREATE INDEX idx_claims_member_service ON claims(member_id, service_date);
CREATE INDEX idx_claims_provider_service ON claims(provider_id, service_date);
CREATE INDEX idx_claim_lines_claim ON claim_lines(claim_id);
CREATE INDEX idx_allocations_claim ON payment_allocations(claim_id);
CREATE INDEX idx_allocations_payment ON payment_allocations(payment_id);
CREATE INDEX idx_payments_date_status ON payments(payment_date, payment_status);
