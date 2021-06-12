--Example 1. Standard exception raise
declare
	not_implemented_exception EXCEPTION;
	pragma exception_init(not_implemented_exception, -20000);
begin
	raise not_implemented_exception;
end;
/

--Example 2. Define new error and raise
begin
	errm.register_error(p_name => 'new_not_implemented', p_info => 'Code not implemented');
	errm.raise('new_not_implemented');
end;
/

--Example 3. Raise predefined error
begin
	errm.not_implemented_exception;
end;
/

--Example 4. Using context for save information
begin
	errm.add_context('local_variable', 'null');
	errm.default_error;
end;
/

--Example 5. Silent raise with code
begin
	errm.sraise(1);
end;
/

--Example 6. Silent raise with name
begin
	errm.sraise('critical_error');
end;
/

--Example 7. Raise with name
begin
	errm.raise('critical_error');
end;
/

--Example 8. Raise with error code
begin
	errm.raise(0);
end;
/