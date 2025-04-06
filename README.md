# Fakturoid_PLSQL_API
PL/sql code used to get data from fakturoid <br>
This code is derived from other project


<h3>Prerequisites </h3>
<li>You need to have ACL to host app.fakturoid.cz set up</li>
<li>Obtain the client secret and client id from https://app.fakturoid.cz/YOUR_USER_NAME/user  </li>
    <li> The identifiers are under the API v3 section</li>

<h3> Flow of the request </h3>
<li> Procedure p_fakturoid_obtain_access_token stores access token</li>
<li> This token is saved in table integration_acess_token</li>
<li> Then each downloading procedure uses this token to retrieve data</li>
<li> Fakturoid supports up to 40 rows fetched per page, therefore whole code retrieval runs in loop</li>
<li> The responses are stored in clob from which they are parsed via json_table and inserted to temp table</li>
<li> Provided rows are then merged into your production table</li>

<h3> Required objects </h3>

<li>CONF_INTEGRATION_ACESS_TOKEN - used to store the access token</li>
<li>JSON_API_IMPORT - used to store the downloaded json</li>
<li>L0_FAKTUROID_EXPENSES - production table for expenses </li>
<li>L0_FAKTUROID_EXPENSES_INTEGRATION - temp table for expenses</li>
<li>L0_FAKTUROID_INVOICES - temp table for invoices</li>
<li>L0_FAKTUROID_INVOICES_INTEGRATION - temp table for invoices</li>