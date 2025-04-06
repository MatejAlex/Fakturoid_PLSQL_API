CREATE TABLE json_api_import
(
    id            number GENERATED ALWAYS AS IDENTITY,
    response_json clob,
    created_at    timestamp(6) DEFAULT SYSTIMESTAMP
)