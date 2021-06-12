--CREATE ERROR_TYPES TABLE
create table errm$error_types (
    code number(5) primary key,
    name varchar2(100 char) unique not null,
    info varchar2(2000 char)
);

create sequence errm$errors_type_seq start with 4 increment by 1;

insert into errm$error_types values (0, 'error', 'Exception');
insert into errm$error_types values (1, 'warning', 'Warning');
insert into errm$error_types values (2, 'log', 'Log information');
insert into errm$error_types values (3, 'critical_error', 'Exceptions that require additional actions');

--CREATE ERRORS TABLE
create table errm$errors (
	code number(10) primary key,
	name varchar2(100) unique not null,
	type number(5) default 0 references errm$error_types not null,
	info varchar2(2000) not null,
	usage_comment varchar2(1000),
	create_date date,
	create_by varchar2(100)
);
/

create sequence errm$errors_code_seq start with 5 increment by 1;

create or replace trigger errm$additional_info_biu_trg
    before insert or update
    on errm$errors
    for each row
begin
    :new.name := lower(:new.name);
    if :old.create_date is null then
        :new.create_date := sysdate;
        :new.create_by := SYS_CONTEXT ('USERENV', 'SESSION_USER');
    end if;
end errm$additional_info_biu_trg;

insert into errm$errors values (0, 'default_error', 0, 'Error has occurred', 'Simple error for tests. Do not use it in production!', null, null);
insert into errm$errors values (1, 'not_implemented', 0, 'Code not implemented', 'Use when code not yet implemented.', null, null);
insert into errm$errors values (2, 'default_warning', 1, 'Warning information', 'Simple warning for tests. Do not use it in production!', null, null);
insert into errm$errors values (3, 'default_log', 2, 'Log information', 'Simple log message for tests. Do not use it in production!', null, null);
insert into errm$errors values (4, 'critical_error', 3, 'Critical error has occurred', 'Simple critical error for tests. Do not use it in production!', null, null);

--CREATE LOG TABLE
create table errm$log (
    id number(38) primary key,
    code number(10) references errm$errors not null,
    timestamp timestamp not null,
    message varchar2(1000),
    context varchar2(2000)
);

create sequence errm$log_seq start with 1 increment by 1;

create table errm$parameters (
    name varchar2(50) primary key,
    value varchar2(1000)
);

insert into errm$parameters values ('MAIL', 'mikl181@yandex.ru');

create or replace trigger errm$parameters_biu_trg
    before insert or update
    on errm$parameters
    for each row
begin
    :NEW.name := upper(:NEW.name);
    :NEW.value := lower(:NEW.value);
end errm$parameters_biu_trg;

create table errm$feature_flags (
    name varchar2(50) primary key,
    value char(1) default '0'
);

insert into errm$feature_flags values ('ALWAYS_ADD_DEFAULT_CONTEXT', '1');
insert into errm$feature_flags values ('MAIL_CRITICAL_ERRORS', '0');
insert into errm$feature_flags values ('LOG_ERRORS_TO_FILE', '1');
insert into errm$feature_flags values ('LOG_ERRORS_TO_TABLE', '1');

create or replace trigger errm$feature_flags_biu_trg
    before insert or update
    on errm$feature_flags
    for each row
begin
    :NEW.name := upper(:NEW.name);

    if (:new.value not in ('0', '1')) then
        raise_application_error(-20000, 'Invalid data');
    end if;
end errm$feature_flags_biu_trg;


create or replace view errm$most_often_errors as
with
total_count as (
    select count(*) cnt
    from ERRM$LOG
),
error_count as (
    select code, count(*) cnt
    from ERRM$LOG
    group by code
)
select ec.CODE, ec.cnt, e.name, e.TYPE, et.NAME type_name, e.INFO, e.USAGE_COMMENT
from error_count ec left join ERRM$ERRORS e on ec.CODE = e.CODE left join ERRM$ERROR_TYPES et on e.TYPE = et.CODE
where cnt > 0.1 * (select cnt from total_count);

create or replace view errm$most_popular_errors as
with
error_count as (
    select code, count(*) cnt
    from ERRM$LOG
    group by code
)
select ec.CODE, ec.cnt, e.name, e.TYPE, et.NAME type_name, e.INFO, e.USAGE_COMMENT
from error_count ec left join ERRM$ERRORS e on ec.CODE = e.CODE left join ERRM$ERROR_TYPES et on e.TYPE = et.CODE
order by ec.cnt desc;

create directory errm$log_dir as 'E:/ERRM';

create or replace package errm
is
	--CONSTANTS
    feature_mail_critical_errors constant varchar2(50 char) := 'MAIL_CRITICAL_ERRORS';
    feature_log_errors_to_file constant varchar2(50 char) := 'LOG_ERRORS_TO_FILE';
    feature_log_errors_to_table constant varchar2(50 char) := 'LOG_ERRORS_TO_TABLE';
    feature_add_default_context constant varchar2(50 char) := 'ALWAYS_ADD_DEFAULT_CONTEXT';

	parameter_mail constant varchar2(50 char) := 'MAIL';

	--TYPES
	subtype t_err_code is pls_integer;
	subtype t_err_name is varchar2(100 char);
	subtype t_err_type is pls_integer;

	--PARAMETERS WORK
	function get_feature_value(p_feature_name in varchar2) return boolean;
	procedure set_feature_value(p_feature_name in varchar2, p_value in BOOLEAN);

	function get_parameter_value(p_param_name in varchar2) return varchar2;
	procedure set_parameter_value(p_param_name in varchar2, p_value in varchar2);

	--HELPERS
    function get_error_code(p_name in t_err_name) return t_err_code;

	--PROCEDURE AND FUNCTIONS
	procedure register_error(p_code in t_err_code := null, p_name in t_err_name, p_type t_err_type := 0, p_info in varchar2, p_comment in varchar2 := null);

	procedure add_default_context;
	procedure add_context(p_name in varchar2, p_value in varchar2);
	procedure clear_context;

	procedure raise(p_code in t_err_code, p_log_enabled in boolean := TRUE);
	procedure raise(p_name in t_err_name, p_log_enabled in boolean := TRUE);

	--SILENT RAISES
	procedure sraise(p_code in t_err_code);
	procedure sraise(p_name in t_err_name);

	--LOG WORK
	procedure clear_log_table;
	procedure clear_log_file;

	--SIMPLE ERRORS RAISE
	procedure default_error;
	procedure default_log;
	procedure default_warning;
	procedure critical_error;
	procedure not_implemented_exception;

	--LOG
	procedure log (p_text in varchar2);
	procedure nl;
end errm;
/

create or replace package body errm
is
	--CONSTANTS

	c_default_error constant pls_integer := -20000;
	--New line symbol
	c_nl constant char(1) := chr(10);


	--TYPES

   TYPE t_context IS TABLE OF VARCHAR2(100) INDEX BY VARCHAR2(100);

	--VARIABLES

	g_context t_context;

	--PARAMETERS WORK

	function get_feature_value(p_feature_name varchar2)
	return boolean
	is
	    l_value errm$feature_flags.value%type;
	begin
	    select value
	    into l_value
	    from ERRM$FEATURE_FLAGS
	    where NAME = upper(p_feature_name);

	    return l_value = '1';
    end get_feature_value;

	procedure set_feature_value(p_feature_name varchar2, p_value BOOLEAN)
	is
	    pragma autonomous_transaction;
	begin

	    if p_value then
            update ERRM$FEATURE_FLAGS
            set value = '1'
            where NAME = upper(p_feature_name);
	    else
	        update ERRM$FEATURE_FLAGS
            set value = '0'
            where NAME = upper(p_feature_name);
	    end if;

	    if sql%rowcount = 0 then
            raise no_data_found;
        end if;
	    commit;
    end set_feature_value;

	function get_parameter_value(p_param_name varchar2)
	return varchar2
	is
	    l_value ERRM$PARAMETERS.value%type;
	begin
	    select value
	    into l_value
	    from ERRM$PARAMETERS
	    where NAME = upper(p_param_name);

	    return l_value;
    end get_parameter_value;

	procedure set_parameter_value(p_param_name varchar2, p_value varchar2)
	is
	    pragma autonomous_transaction;
	begin
	    update ERRM$PARAMETERS
	    set value = lower(p_value)
	    where NAME = upper(p_param_name);

	    if sql%rowcount = 0 then
            raise no_data_found;
        end if;
	    commit;
    end set_parameter_value;


	--HELPERS

    procedure reset_seq(p_seq_name in varchar2)
    is
        pragma autonomous_transaction;
        l_val number;
    begin
        --Hack from AskTom for reset sequence
        execute immediate 'select ' || p_seq_name || '.nextval from dual' INTO l_val;
        execute immediate 'alter sequence ' || p_seq_name || ' increment by -' || l_val || ' minvalue 0';
        execute immediate 'select ' || p_seq_name || '.nextval from dual' INTO l_val;
        execute immediate 'alter sequence ' || p_seq_name || ' increment by 1 minvalue 0';
    end reset_seq;

procedure add_default_context
is
begin
    add_context('instance', SYS_CONTEXT ('USERENV', 'INSTANCE_NAME'));
    add_context('db_name', SYS_CONTEXT ('USERENV', 'DB_NAME'));
    add_context('user_name', SYS_CONTEXT ('USERENV', 'SESSION_USER'));
    add_context('module', SYS_CONTEXT ('USERENV', 'MODULE'));
    add_context('current_schema', SYS_CONTEXT ('USERENV', 'CURRENT_SCHEMA'));
    add_context('host', SYS_CONTEXT ('USERENV', 'HOST'));
end add_default_context;

procedure add_context(p_name in varchar2, p_value in varchar2)
is
begin
    g_context(p_name) := p_value;
end add_context;

procedure clear_context
is
begin
    g_context.DELETE();
end clear_context;

	function get_error_info(p_code in t_err_code)
	return errm$errors%rowtype
	is
	    l_error errm$errors%rowtype;
	begin
        select *
        into l_error
	    from ERRM$ERRORS
        where code = p_code;

        return l_error;
    end get_error_info;

    function get_context_string(p_use_tab boolean := true)
    return varchar2
    is
        l_index   varchar2(100);
        l_context varchar2(1000);
    begin
        if get_feature_value(errm.FEATURE_ADD_DEFAULT_CONTEXT) then
            add_default_context();
        end if;

        if g_context.COUNT = 0 then
            return null;
        end if;

        l_index := g_context.FIRST;

        while l_index is not null
        loop
            l_context := l_context || case when p_use_tab then '    ' else '' end || l_index || ': ' || g_context(l_index) || c_nl;
            l_index := g_context.next(l_index);
        end loop;

        return l_context;
    end get_context_string;

	function get_error_message(p_code in t_err_code)
	return varchar2
	is
		r_error_instance errm$errors%rowtype;
		l_error_typename errm$error_types.name%type;
		l_context varchar2(2000);
	begin
	    r_error_instance := get_error_info(p_code);

		select name
		into l_error_typename
		from ERRM$ERROR_TYPES
		where code = r_error_instance.TYPE;

	    l_context := get_context_string();

		return  r_error_instance.name || ' (#' || p_code ||')' || c_nl ||
				r_error_instance.info || c_nl ||
				'Type: ' || l_error_typename || c_nl ||
				'Context' ||
		            case
		                when l_context is null then
		                    ' not provided!'
		                else
		                    ': ' || c_nl || l_context
		            end
		        || c_nl;
	end get_error_message;


	procedure log_to_file(p_code in t_err_code)
	is
	    l_log UTL_FILE.file_type;
	begin
	    if NOT get_feature_value(FEATURE_LOG_ERRORS_TO_FILE) then
	        return;
	    end if;

	    l_log := UTL_FILE.FOPEN('ERRM$LOG_DIR', 'log.txt','A'); -- A - append
	    UTL_FILE.PUT(l_log, systimestamp || ': ' || get_error_message(p_code));
	    UTL_FILE.FCLOSE(l_log);
    end log_to_file;

	procedure log_to_table(p_code in t_err_code)
	is
	    pragma autonomous_transaction;

	    l_error errm$errors%rowtype;
	    l_message errm$log.message%type;
	    l_context errm$log.context%type;
	begin
	    if NOT get_feature_value(FEATURE_LOG_ERRORS_TO_TABLE) then
	        return;
	    end if;

	    l_error := get_error_info(p_code);
	    l_message := get_error_message(p_code);
	    l_context := get_context_string(false);

	    insert into ERRM$LOG values (errm$log_seq.nextval, p_code, systimestamp, l_message, l_context);
	    commit;
    end log_to_table;

	procedure log_to_mail(p_code in t_err_code)
	is
	    l_host varchar2(100);
	    l_db_name varchar2(100);
	    l_error_instance errm$errors%rowtype;
	    l_message varchar2(2000);
	begin
	    if NOT get_feature_value(FEATURE_MAIL_CRITICAL_ERRORS) then
	        return;
	    end if;
        l_error_instance := get_error_info(p_code);

	    if l_error_instance.TYPE != 4 then
            return;
        end if;

	    l_host := SYS_CONTEXT ('USERENV', 'HOST');
	    l_db_name := SYS_CONTEXT ('USERENV', 'DB_NAME');
	    l_message := get_error_message(p_code);

	    UTL_MAIL.send(
				sender     => l_db_name || '@' || l_host || '.com',
                recipients => get_parameter_value(errm.PARAMETER_MAIL),
                subject    => l_error_instance.NAME || ' has occurred on ' || l_db_name || '/' || l_host,
                message    => l_message);
	end log_to_mail;

	procedure log_error(p_code in t_err_code)
	is
	begin
	    log_to_table(p_code);
	    log_to_file(p_code);
	    log_to_mail(p_code);
    end log_error;

	function get_error_code(p_name in t_err_name)
	return t_err_code
	is
		l_err_code t_err_code;
	begin
		select code
		into l_err_code
		from errm$errors
		where lower(name) = lower(p_name);

		return l_err_code;
	end get_error_code;


	--PROCEDURE AND FUNCTIONS

	procedure register_error(p_code in t_err_code := null, p_name in t_err_name, p_type t_err_type := 0, p_info in varchar2, p_comment in varchar2)
	is
	    pragma autonomous_transaction;
	begin
	    insert into ERRM$ERRORS
	        values (NVL(p_code, errm$errors_code_seq.nextval), lower(p_name), p_type, p_info, p_comment, null, null);
	    commit;
	end register_error;


	procedure raise(p_code in t_err_code, p_log_enabled in boolean := TRUE)
	is
	    l_message varchar2(2000);
	begin
	    if p_log_enabled then
	        log_error(p_code);
	    end if;

	    l_message := get_error_message(p_code);

	    clear_context();
		raise_application_error(c_default_error, l_message);
	end raise;

	procedure raise(p_name in t_err_name, p_log_enabled in boolean := TRUE)
	is
		l_err_code t_err_code;
	begin
		l_err_code := get_error_code(p_name);
		errm.raise(l_err_code, p_log_enabled);
	end raise;

	procedure sraise(p_code in t_err_code)
	is
	begin
        errm.raise(p_code, FALSE);
    end sraise;

	procedure sraise(p_name in t_err_name)
	is
	begin
        errm.raise(p_name, FALSE);
    end sraise;


	--LOG WORK

	procedure clear_log_table
	is
	    pragma autonomous_transaction;
	begin
	    execute immediate 'truncate table errm$log';

	    --We can't drop and recreate our sequence, because package should be compiled again
	    reset_seq('ERRM$LOG_SEQ');
    end clear_log_table;

	procedure clear_log_file
	is
	    l_log UTL_FILE.file_type;
	begin
	    l_log := UTL_FILE.FOPEN('ERRM$LOG_DIR', 'log.txt','W');
	    UTL_FILE.FCLOSE(l_log);
    end clear_log_file;

	--EASE ERRORS RAISE

	procedure default_error
	is
	begin
        errm.raise(0);
    end default_error;

	procedure not_implemented_exception
	is
	begin
        errm.raise(1);
    end not_implemented_exception;

	procedure default_warning
	is
	begin
        errm.raise(2);
    end default_warning;

	procedure default_log
	is
	begin
        errm.raise(3);
    end default_log;

	procedure critical_error
	is
	begin
	    errm.raise(4);
	end critical_error;


	--LOG

	procedure log (p_text in varchar2)
	is
	begin
		dbms_output.put_line(p_text);
	end log;

	procedure nl
	is
	begin
		dbms_output.new_line;
	end nl;
end errm;
/