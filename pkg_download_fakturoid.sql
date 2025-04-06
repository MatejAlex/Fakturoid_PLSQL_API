CREATE OR REPLACE PACKAGE pkg_download_fakturoid
IS
    PROCEDURE p_fakturoid_download_invoices;
    PROCEDURE p_fakturoid_download_expenses;
    PROCEDURE p_fakturoid_obtain_access_token;

END pkg_download_fakturoid;
/

CREATE OR REPLACE PACKAGE BODY pkg_download_fakturoid
IS

    FUNCTION f_get_access_token RETURN varchar2
        IS
        ltxt_access_token varchar2(800);
        ex_token_not_found EXCEPTION;
    BEGIN

        SELECT
            ciat.token
        INTO ltxt_access_token
        FROM conf_integration_acess_token ciat
        WHERE 1 = 1
        ORDER BY
            crtd_dt DESC
            FETCH FIRST ROW ONLY;

        IF ltxt_access_token IS NULL
        THEN
            RAISE ex_token_not_found;
        END IF;

        RETURN ltxt_access_token;
    EXCEPTION
        WHEN OTHERS THEN RAISE;

    END f_get_access_token;

    PROCEDURE p_store_access_token(token_clob IN clob)
        IS
        ltxt_access_token_raw varchar2(900);
        ltxt_access_token     varchar2(500);
    BEGIN

        ltxt_access_token_raw := dbms_lob.substr(token_clob, 4000, 1);
        SELECT
            REGEXP_SUBSTR(
                    ltxt_access_token_raw,
                    '"access_token":"([^"]+)"',
                    1,
                    1,
                    NULL,
                    1
            ) AS access_token
        INTO
            ltxt_access_token
        FROM dual;
        INSERT INTO conf_integration_acess_token(token)
        VALUES (ltxt_access_token);

    END p_store_access_token;

    PROCEDURE p_fakturoid_download_invoices IS

        ltxt_access_token     varchar2(500);
        l_auth                varchar2(4000) ;
        l_http_req            utl_http.req;
        l_http_resp           utl_http.resp;
        l_response_raw        raw(32767);
        l_response_total      clob;
        lnum_json_id          number;
        lnum_pages_to_request number := 3; --this results in 120 invoices downloaded (3x40)

        PROCEDURE p_store_response(p_response IN clob, out_json_id OUT number)
            IS
            llnum_json_id number;
        BEGIN

            INSERT INTO json_api_import a (response_json)
            VALUES (p_response)
            RETURNING a.id INTO llnum_json_id;


            out_json_id := llnum_json_id;
        END p_store_response;

        PROCEDURE p_insert_into_fakturoid(p_json_id number)
            IS
        BEGIN

            EXECUTE IMMEDIATE 'TRUNCATE TABLE l0_fakturoid_invoices_integration';


            FOR i IN (
                SELECT
                    jt.*
                FROM json_api_import j,
                     JSON_TABLE(j.response_json, '$[*]'
                                COLUMNS (
                                    id number PATH '$.id',
                                    custom_id varchar2(500) PATH '$.custom_id',
                                    document_type varchar2(500) PATH '$.document_type',
                                    proforma_followup_document varchar2(500) PATH '$.proforma_followup_document',
                                    correction_id varchar2(500) PATH '$.correction_id',
                                    num varchar2(500) PATH '$.number',
                                    number_format_id varchar2(500) PATH '$.number_format_id',
                                    variable_symbol varchar2(500) PATH '$.variable_symbol',
                                    your_name varchar2(500) PATH '$.your_name',
                                    your_street varchar2(500) PATH '$.your_street',
                                    your_city varchar2(500) PATH '$.your_city',
                                    your_zip varchar2(500) PATH '$.your_zip',
                                    your_country varchar2(500) PATH '$.your_country',
                                    your_registration_no varchar2(500) PATH '$.your_registration_no',
                                    your_vat_no varchar2(500) PATH '$.your_vat_no',
                                    your_local_vat_no varchar2(500) PATH '$.your_local_vat_no',
                                    client_name varchar2(500) PATH '$.client_name',
                                    client_street varchar2(500) PATH '$.client_street',
                                    client_city varchar2(500) PATH '$.client_city',
                                    client_zip varchar2(500) PATH '$.client_zip',
                                    client_country varchar2(500) PATH '$.client_country',
                                    client_registration_no varchar2(500) PATH '$.client_registration_no',
                                    client_vat_no varchar2(500) PATH '$.client_vat_no',
                                    client_local_vat_no varchar2(500) PATH '$.client_local_vat_no',
                                    client_has_delivery_address varchar2(500) PATH '$.client_has_delivery_address',
                                    client_delivery_name varchar2(500) PATH '$.client_delivery_name',
                                    client_delivery_street varchar2(500) PATH '$.client_delivery_street',
                                    client_delivery_city varchar2(500) PATH '$.client_delivery_city',
                                    client_delivery_zip varchar2(500) PATH '$.client_delivery_zip',
                                    client_delivery_country varchar2(500) PATH '$.client_delivery_country',
                                    subject_id varchar2(500) PATH '$.subject_id',
                                    subject_custom_id varchar2(500) PATH '$.subject_custom_id',
                                    generator_id varchar2(500) PATH '$.generator_id',
                                    related_id varchar2(500) PATH '$.related_id',
                                    paypal varchar2(500) PATH '$.paypal',
                                    gopay varchar2(500) PATH '$.gopay',
                                    token varchar2(500) PATH '$.token',
                                    status varchar2(500) PATH '$.status',
                                    order_number varchar2(500) PATH '$.order_number',
                                    issued_on varchar2(500) PATH '$.issued_on',
                                    taxable_fulfillment_due varchar2(500) PATH '$.taxable_fulfillment_due',
                                    due varchar2(500) PATH '$.due',
                                    due_on varchar2(500) PATH '$.due_on',
                                    sent_at varchar2(500) PATH '$.sent_at',
                                    paid_on varchar2(500) PATH '$.paid_on',
                                    reminder_sent_at varchar2(500) PATH '$.reminder_sent_at',
                                    cancelled_at varchar2(500) PATH '$.cancelled_at',
                                    uncollectible_at varchar2(500) PATH '$.uncollectible_at',
                                    locked_at varchar2(500) PATH '$.locked_at',
                                    webinvoice_seen_on varchar2(500) PATH '$.webinvoice_seen_on',
                                    note varchar2(500) PATH '$.note',
                                    footer_note varchar2(500) PATH '$.footer_note',
                                    private_note varchar2(500) PATH '$.private_note',
                                    tags varchar2(500) PATH '$.tags[*]',
                                    bank_account varchar2(500) PATH '$.bank_account',
                                    iban varchar2(500) PATH '$.iban',
                                    swift_bic varchar2(500) PATH '$.swift_bic',
                                    iban_visibility varchar2(500) PATH '$.iban_visibility',
                                    show_already_paid_note_in_pdf varchar2(500) PATH '$.show_already_paid_note_in_pdf',
                                    payment_method varchar2(500) PATH '$.payment_method',
                                    custom_payment_method varchar2(500) PATH '$.custom_payment_method',
                                    hide_bank_account varchar2(500) PATH '$.hide_bank_account',
                                    currency varchar2(500) PATH '$.currency',
                                    exchange_rate varchar2(500) PATH '$.exchange_rate',
                                    language varchar2(500) PATH '$.language',
                                    transferred_tax_liability varchar2(500) PATH '$.transferred_tax_liability',
                                    supply_code varchar2(500) PATH '$.supply_code',
                                    oss varchar2(500) PATH '$.oss',
                                    vat_price_mode varchar2(500) PATH '$.vat_price_mode',
                                    subtotal varchar2(500) PATH '$.subtotal',
                                    total varchar2(500) PATH '$.total',
                                    native_subtotal varchar2(500) PATH '$.native_subtotal',
                                    native_total varchar2(500) PATH '$.native_total',
                                    remaining_amount varchar2(500) PATH '$.remaining_amount',
                                    remaining_native_amount varchar2(500) PATH '$.remaining_native_amount',
                                    html_url varchar2(500) PATH '$.html_url',
                                    public_html_url varchar2(500) PATH '$.public_html_url',
                                    url varchar2(500) PATH '$.url',
                                    pdf_url varchar2(500) PATH '$.pdf_url',
                                    subject_url varchar2(500) PATH '$.subject_url',
                                    created_at varchar2(500) PATH '$.created_at',
                                    updated_at varchar2(500) PATH '$.updated_at'
                                    )
                     ) jt
                WHERE 1 = 1
                  AND j.id = p_json_id)
                LOOP
                    INSERT INTO l0_fakturoid_invoices_integration a
                    VALUES i;
                END LOOP;

        END p_insert_into_fakturoid;

        PROCEDURE p_merge_invoices IS
        BEGIN


            FOR i IN
                (SELECT * FROM l0_fakturoid_invoices_integration l0fii)
                LOOP
                    MERGE INTO l0_fakturoid_invoices a
                    USING (
                              SELECT
                                  1
                              FROM dual)
                    ON
                        (a.id_source = TO_NUMBER(i.id) AND a.your_name = i.your_name)
                    WHEN MATCHED THEN
                        UPDATE
                        SET a.num             = i.num,
                            a.issued_on       = TO_DATE(i.issued_on, 'YYYY-MM-DD'),
                            a.client_name     = i.client_name,
                            a.subtotal        = TO_NUMBER(i.subtotal),
                            a.variable_symbol = TO_NUMBER(i.variable_symbol),
                            a.document_type   = i.document_type,
                            a.tags            = i.tags,
                            a.client_ic       = i.client_registration_no
                    WHEN NOT MATCHED THEN
                        INSERT
                        (id_source, your_name, num, document_type, variable_symbol, issued_on, client_name, client_ic,
                         subtotal,
                         tags)
                        VALUES (TO_NUMBER(i.id), i.your_name, i.num, i.document_type, TO_NUMBER(i.variable_symbol),
                                TO_DATE(i.issued_on, 'YYYY-MM-DD'), i.client_name,
                                i.client_registration_no, TO_NUMBER(i.subtotal), i.tags);
                END LOOP;


        END p_merge_invoices;

    BEGIN

        ltxt_access_token := f_get_access_token;
        l_auth := 'Bearer ' || ltxt_access_token;

        FOR i IN 1 .. lnum_pages_to_request
            LOOP
                l_http_req := utl_http.begin_request(
                        'https://app.fakturoid.cz/api/v3/accounts/YOUR_ACCOUNT_NAME/invoices.json?page=' || i,
                        'GET',
                        'HTTP/1.1'
                              );

                utl_http.set_header(l_http_req, 'User-Agent', 'APP_NAME (your_email@email.cz)');
                utl_http.set_header(l_http_req, 'Accept', 'application/json');
                utl_http.set_header(l_http_req, 'Authorization', l_auth);

                l_http_resp := utl_http.get_response(l_http_req);
                l_response_total := EMPTY_CLOB();

                LOOP
                    BEGIN
                        utl_http.read_raw(l_http_resp, l_response_raw, 32767);
                        -- Convert the RAW response to a proper UTF-8 string
                        l_response_total := l_response_total || utl_raw.cast_to_varchar2(l_response_raw);
                    EXCEPTION
                        WHEN OTHERS THEN
                            utl_http.end_response(l_http_resp);
                            EXIT;
                    END;
                END LOOP;

                p_store_response(l_response_total, lnum_json_id);
                p_insert_into_fakturoid(lnum_json_id);
                p_merge_invoices;

                COMMIT;
            END LOOP;
    EXCEPTION
        WHEN OTHERS THEN RAISE;
    END p_fakturoid_download_invoices;

    PROCEDURE p_fakturoid_download_expenses IS
        ltxt_access_token     varchar2(500);
        l_auth                varchar2(4000) ;
        l_http_req            utl_http.req;
        l_http_resp           utl_http.resp;
        l_response_raw        raw(32767);
        l_response_total      clob;
        lnum_json_id          number;
        lnum_pages_to_request number := 3; --this results in 120 invoices downloaded (3x40)

        PROCEDURE p_store_response(p_response IN clob, out_json_id OUT number)
            IS
            llnum_json_id number;
        BEGIN

            INSERT INTO json_api_import a (response_json)
            VALUES (p_response)
            RETURNING a.id INTO llnum_json_id;


            out_json_id := llnum_json_id;
        END p_store_response;

        PROCEDURE p_insert_into_fakturoid(p_json_id number)
            IS
        BEGIN

            EXECUTE IMMEDIATE 'TRUNCATE TABLE l0_fakturoid_expenses_integration';

            FOR i IN (
                SELECT
                    jt.id,
                    custom_id,
                    num,
                    original_number,
                    variable_symbol,
                    supplier_name,
                    supplier_street,
                    supplier_city,
                    supplier_zip,
                    supplier_country,
                    supplier_registration_no,
                    supplier_vat_no,
                    supplier_local_vat_no,
                    subject_id,
                    status,
                    document_type,
                    issued_on,
                    taxable_fulfillment_due,
                    received_on,
                    due_on,
                    remind_due_date,
                    paid_on,
                    locked_at,
                    description,
                    private_note,
                    tags,
                    bank_account,
                    iban,
                    swift_bic,
                    payment_method,
                    custom_payment_method,
                    currency,
                    exchange_rate,
                    transferred_tax_liability,
                    vat_price_mode,
                    supply_code,
                    proportional_vat_deduction,
                    tax_deductible,
                    subtotal,
                    total,
                    native_subtotal,
                    native_total,
                    html_url,
                    url,
                    subject_url,
                    jt.created_at,
                    updated_at
                FROM json_api_import j,
                     JSON_TABLE(j.response_json, '$[*]'
                                COLUMNS (
                                    id varchar2(500) PATH '$.id',
                                    custom_id varchar2(500) PATH '$.custom_id',
                                    num varchar2(500) PATH '$.number',
                                    original_number varchar2(500) PATH '$.original_number',
                                    variable_symbol varchar2(500) PATH '$.variable_symbol',
                                    supplier_name varchar2(500) PATH '$.supplier_name',
                                    supplier_street varchar2(500) PATH '$.supplier_street',
                                    supplier_city varchar2(500) PATH '$.supplier_city',
                                    supplier_zip varchar2(500) PATH '$.supplier_zip',
                                    supplier_country varchar2(500) PATH '$.supplier_country',
                                    supplier_registration_no varchar2(500) PATH '$.supplier_registration_no',
                                    supplier_vat_no varchar2(500) PATH '$.supplier_vat_no',
                                    supplier_local_vat_no varchar2(500) PATH '$.supplier_local_vat_no',
                                    subject_id varchar2(500) PATH '$.subject_id',
                                    status varchar2(500) PATH '$.status',
                                    document_type varchar2(500) PATH '$.document_type',
                                    issued_on varchar2(500) PATH '$.issued_on',
                                    taxable_fulfillment_due varchar2(500) PATH '$.taxable_fulfillment_due',
                                    received_on varchar2(500) PATH '$.received_on',
                                    due_on varchar2(500) PATH '$.due_on',
                                    remind_due_date varchar2(500) PATH '$.remind_due_date',
                                    paid_on varchar2(500) PATH '$.paid_on',
                                    locked_at varchar2(500) PATH '$.locked_at',
                                    description varchar2(500) PATH '$.description',
                                    private_note varchar2(500) PATH '$.private_note',
                                    tags varchar2(500) PATH '$.tags[*]',
                                    bank_account varchar2(500) PATH '$.bank_account',
                                    iban varchar2(500) PATH '$.iban',
                                    swift_bic varchar2(500) PATH '$.swift_bic',
                                    payment_method varchar2(500) PATH '$.payment_method',
                                    custom_payment_method varchar2(500) PATH '$.custom_payment_method',
                                    currency varchar2(500) PATH '$.currency',
                                    exchange_rate varchar2(500) PATH '$.exchange_rate',
                                    transferred_tax_liability varchar2(500) PATH '$.transferred_tax_liability',
                                    vat_price_mode varchar2(500) PATH '$.vat_price_mode',
                                    supply_code varchar2(500) PATH '$.supply_code',
                                    proportional_vat_deduction varchar2(500) PATH '$.proportional_vat_deduction',
                                    tax_deductible varchar2(500) PATH '$.tax_deductible',
                                    subtotal varchar2(500) PATH '$.subtotal',
                                    total varchar2(500) PATH '$.total',
                                    native_subtotal varchar2(500) PATH '$.native_subtotal',
                                    native_total varchar2(500) PATH '$.native_total',
                                    html_url varchar2(500) PATH '$.html_url',
                                    url varchar2(500) PATH '$.url',
                                    subject_url varchar2(500) PATH '$.subject_url',
                                    created_at varchar2(500) PATH '$.created_at',
                                    updated_at varchar2(500) PATH '$.updated_at'


                                    )
                     ) jt
                WHERE j.id = p_json_id
                )
                LOOP

                    INSERT INTO l0_fakturoid_expenses_integration

                    VALUES i;

                END LOOP;

        END p_insert_into_fakturoid;

        PROCEDURE p_merge_expenses IS
        BEGIN


            FOR i IN
                (SELECT * FROM l0_fakturoid_expenses_integration l0fii)
                LOOP
                    MERGE INTO l0_fakturoid_expenses a
                    USING (
                              SELECT
                                  1
                              FROM dual)
                    ON
                        (a.id_source = TO_NUMBER(i.id))
                    WHEN MATCHED THEN
                        UPDATE
                        SET num             = i.num,
                            variable_symbol = TO_NUMBER(i.variable_symbol),
                            issued_on       = TO_DATE(i.issued_on, 'YYYY-MM-DD'),
                            supplier_name   = i.supplier_name,
                            supplier_ic     = i.supplier_registration_no,
                            subtotal        = TO_NUMBER(i.subtotal),
                            tags            = i.tags
                    WHEN NOT MATCHED THEN
                        INSERT
                        (id_source, num, variable_symbol, issued_on, supplier_name, supplier_ic, subtotal,
                         tags)
                        VALUES (TO_NUMBER(i.id), i.num, TO_NUMBER(i.variable_symbol),
                                TO_DATE(i.issued_on, 'YYYY-MM-DD'), i.supplier_name,
                                i.supplier_registration_no, TO_NUMBER(i.subtotal), i.tags);
                END LOOP;


        END p_merge_expenses;

    BEGIN

        ltxt_access_token := f_get_access_token;
        l_auth := 'Bearer ' || ltxt_access_token;

        FOR i IN 1 .. lnum_pages_to_request
            LOOP
                l_http_req := utl_http.begin_request(
                        'https://app.fakturoid.cz/api/v3/accounts/YOUR_NAME/expenses.json?page=' || i,
                        'GET',
                        'HTTP/1.1'
                              );

                utl_http.set_header(l_http_req, 'User-Agent', 'APP_NAME (your_email@email.cz)');
                utl_http.set_header(l_http_req, 'Accept', 'application/json');
                utl_http.set_header(l_http_req, 'Authorization', l_auth);
                l_http_resp := utl_http.get_response(l_http_req);
                l_response_total := EMPTY_CLOB();

                LOOP
                    BEGIN
                        utl_http.read_raw(l_http_resp, l_response_raw, 32767);
                        -- Convert the RAW response to a proper UTF-8 string
                        l_response_total := l_response_total || utl_raw.cast_to_varchar2(l_response_raw);
                    EXCEPTION
                        WHEN OTHERS THEN
                            utl_http.end_response(l_http_resp);
                            EXIT;
                    END;
                END LOOP;


                p_store_response(l_response_total, lnum_json_id);
                p_insert_into_fakturoid(lnum_json_id);
                p_merge_expenses;
                DBMS_LOCK.SLEEP(0.5);
                    --so there are not too many requests in short period of time - avoiding too many requests error
                COMMIT;
            END LOOP;
    EXCEPTION
        WHEN OTHERS THEN RAISE;
    END
    p_fakturoid_download_expenses;

    PROCEDURE p_fakturoid_obtain_access_token
        IS
        l_http_req  utl_http.req;
        l_http_resp utl_http.resp;
        l_response  clob;
        l_auth      varchar2(4000);
        l_body      clob;
    BEGIN

        l_auth :=
                'Basic xxxx';
        --replace xxxx with base64 encoded client_id:client_secret

        -- Request body
        l_body := '{"grant_type":"client_credentials"}';

        -- Open HTTP request
        l_http_req := utl_http.begin_request('https://app.fakturoid.cz/api/v3/oauth/token', 'POST', 'HTTP/1.1');

        -- Set headers
        utl_http.set_header(l_http_req, 'User-Agent', 'APP_NAME (your_email@email.cz)');
        utl_http.set_header(l_http_req, 'Accept', 'application/json');
        utl_http.set_header(l_http_req, 'Authorization', l_auth);
        utl_http.set_header(l_http_req, 'Content-Type', 'application/json');
        utl_http.set_header(l_http_req, 'Content-Length', LENGTH(l_body));

        -- Write request body
        utl_http.write_text(l_http_req, l_body);

        -- Get response
        l_http_resp := utl_http.get_response(l_http_req);
        utl_http.read_text(l_http_resp, l_response);
        utl_http.end_response(l_http_resp);

        -- Print response
        p_store_access_token(l_response);


        COMMIT;
    END p_fakturoid_obtain_access_token;

END pkg_download_fakturoid;