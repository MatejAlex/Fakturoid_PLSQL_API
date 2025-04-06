CREATE TABLE l0_fakturoid_expenses
(
    fakturoid_expense_id number GENERATED ALWAYS AS IDENTITY,
    id_source            number,
    num                  varchar2(500),
    variable_symbol      number,
    issued_on            date,
    supplier_name        varchar2(500),
    supplier_ic          varchar2(20),
    subtotal             number,
    tags                 varchar2(90),
    deletion_type        varchar2(80),
    del_flg              varchar2(1),
    deleted_dt           date,
    client_checked_flg   varchar2(1),
    upd_dt               date,
    upd_by               varchar2(80),
    crtd_dt              date,
    crtd_by              varchar2(80)
);

CREATE INDEX idx1_l0_fakturoid_expenses ON l0_fakturoid_expenses (id_source);

CREATE INDEX idx2_l0_fakturoid_expenses ON l0_fakturoid_expenses (issued_on);


CREATE OR REPLACE TRIGGER trg_l0_fakturoid_expenses_ins
    BEFORE INSERT
    ON l0_fakturoid_expenses
    FOR EACH ROW
BEGIN
    :new.crtd_dt := SYSDATE;
    :new.upd_dt := SYSDATE;
    :new.crtd_by := NVL(:new.crtd_by, (NVL(v('APP_USER'), USER)));
    :new.upd_by := NVL(:new.crtd_by, (NVL(v('APP_USER'), USER)));
END;
/

CREATE OR REPLACE TRIGGER trg_l0_fakturoid_expenses_upd
    BEFORE UPDATE
    ON l0_fakturoid_expenses
    FOR EACH ROW
BEGIN
    :new.upd_dt := SYSDATE;
    :new.crtd_by := NVL(:new.crtd_by, (NVL(v('APP_USER'), USER)));
    :new.upd_by := NVL(:new.crtd_by, (NVL(v('APP_USER'), USER)));
END;
/