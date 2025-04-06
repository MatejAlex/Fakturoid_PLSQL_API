CREATE TABLE l0_fakturoid_invoices2
(
    fakturoid_invoice_id number GENERATED ALWAYS AS IDENTITY,
    your_name            varchar2(500),
    id_source            number,
    num                  varchar2(500),
    document_type        varchar2(80),
    variable_symbol      number,
    issued_on            date,
    client_name          varchar2(500),
    client_ic            varchar2(20),
    subtotal             number,
    tags                 varchar2(90),
    upd_dt               date,
    upd_by               varchar2(80),
    crtd_dt              date,
    crtd_by              varchar2(80)
);

CREATE INDEX idx1_l0_fakturoid_invoices ON l0_fakturoid_invoices (id_source, your_name);

CREATE INDEX idx2_l0_fakturoid_invoices ON l0_fakturoid_invoices (issued_on, invoice_segment);


CREATE OR REPLACE TRIGGER trg_l0_fakturoid_invoices_ins
    BEFORE INSERT
    ON l0_fakturoid_invoices
    FOR EACH ROW
BEGIN
    :new.crtd_dt := SYSDATE;
    :new.upd_dt := SYSDATE;
    :new.crtd_by := NVL(:new.crtd_by, (NVL(v('APP_USER'), USER)));
    :new.upd_by := NVL(:new.crtd_by, (NVL(v('APP_USER'), USER)));
END;
/

CREATE OR REPLACE TRIGGER trg_l0_fakturoid_invoices_upd
    BEFORE UPDATE
    ON l0_fakturoid_invoices
    FOR EACH ROW
BEGIN
    :new.upd_dt := SYSDATE;
    :new.crtd_by := NVL(:new.crtd_by, (NVL(v('APP_USER'), USER)));
    :new.upd_by := NVL(:new.crtd_by, (NVL(v('APP_USER'), USER)));
END;
/