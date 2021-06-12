SET SERVEROUTPUT ON;
declare
    l_bool_value boolean;
    l_varchar_value varchar2(2000);
    l_int_value pls_integer;
begin
--Auto test
--No data found
    errm.LOG('Test 1');
    begin
        errm.RAISE('code_implemented');
    exception
        when no_data_found then
            errm.LOG('Correct!');
        when others then
            errm.LOG('Error!');
    end;

    errm.LOG('Test 2');
    begin
        l_bool_value := errm.GET_FEATURE_VALUE('unknown_feature');
    exception
        when no_data_found then
            errm.LOG('Correct!');
        when others then
            errm.LOG('Error!');
    end;

    errm.LOG('Test 3');
    begin
        errm.SET_FEATURE_VALUE('unknown_feature', false);
    exception
        when no_data_found then
            errm.LOG('Correct!');
        when others then
            errm.LOG('Error!');
    end;

    errm.LOG('Test 4');
    begin
        l_varchar_value := errm.GET_PARAMETER_VALUE('unknown_parameter');
    exception
        when no_data_found then
            errm.LOG('Correct!');
        when others then
            errm.LOG('Error!');
    end;

    errm.LOG('Test 5');
    begin
        errm.SET_PARAMETER_VALUE('unknown_parameter', 'unknown_value');
    exception
    when no_data_found then
        errm.LOG('Correct!');
    when others then
        errm.LOG('Error!');
    end;

    errm.LOG('Test 6');
    begin
        l_int_value := errm.GET_ERROR_CODE('unknown_error');
    exception
    when no_data_found then
        errm.LOG('Correct!');
    when others then
        errm.LOG('Error!');
    end;

    errm.LOG('Test 7');
    begin
        errm.RAISE(-1);
    exception
    when no_data_found then
        errm.LOG('Correct!');
    when others then
        errm.LOG('Error!');
    end;

    errm.LOG('Test 8');
    begin
        errm.RAISE(-1, false);
    exception
    when no_data_found then
        errm.LOG('Correct!');
    when others then
        errm.LOG('Error!');
    end;

    errm.LOG('Test 9');
    begin
        errm.RAISE('unknown_error');
    exception
    when no_data_found then
        errm.LOG('Correct!');
    when others then
        errm.LOG('Error!');
    end;

    errm.LOG('Test 10');
    begin
        errm.RAISE('unknown_error', false);
    exception
    when no_data_found then
        errm.LOG('Correct!');
    when others then
        errm.LOG('Error!');
    end;

    errm.LOG('Test 11');
    begin
        errm.SRAISE(-1);
    exception
    when no_data_found then
        errm.LOG('Correct!');
    when others then
        errm.LOG('Error!');
    end;

    errm.LOG('Test 12');
    begin
        errm.SRAISE('unknown_error');
    exception
    when no_data_found then
        errm.LOG('Correct!');
    when others then
        errm.LOG('Error!');
    end;

--Manual test
--Context added to error
--     errm.ADD_DEFAULT_CONTEXT;
--     errm.ADD_CONTEXT('user_context', 'user_value');
--     errm.DEFAULT_ERROR;

--No context
--     errm.SET_FEATURE_VALUE(errm.FEATURE_ADD_DEFAULT_CONTEXT, false);
--     errm.ADD_CONTEXT('user_context', 'user_value');
--     errm.CLEAR_CONTEXT;
--     errm.DEFAULT_ERROR;

--Default context
--     errm.SET_FEATURE_VALUE(errm.FEATURE_ADD_DEFAULT_CONTEXT, true);
--     errm.ADD_CONTEXT('user_context', 'user_value');
--     errm.CLEAR_CONTEXT;
--     errm.DEFAULT_ERROR;

--Table ERRM$LOG should be clean
--     errm.CLEAR_LOG_TABLE;

--Table ERRM$LOG should be clean
--     errm.SET_FEATURE_VALUE(errm.FEATURE_LOG_ERRORS_TO_TABLE, false);
--     errm.DEFAULT_ERROR;

--Correct types for each error
--     errm.DEFAULT_ERROR;
--     errm.DEFAULT_LOG;
--     errm.DEFAULT_WARNING;
--     errm.NOT_IMPLEMENTED_EXCEPTION;
--     errm.CRITICAL_ERROR;

--Error occurred
--     errm.raise('critical_error');
--     errm.RAISE(4);

--Error occurred with no additional log
--     errm.SET_FEATURE_VALUE(errm.FEATURE_LOG_ERRORS_TO_TABLE, true);
--     errm.SRAISE(4);

--Added information to file
--     errm.SET_FEATURE_VALUE(errm.FEATURE_LOG_ERRORS_TO_FILE, true);
--     errm.DEFAULT_LOG;
end;
/