drop view ERRM$MOST_OFTEN_ERRORS;
drop view ERRM$MOST_POPULAR_ERRORS;

drop trigger errm$additional_info_biu_trg;
drop trigger errm$parameters_biu_trg;
drop trigger errm$feature_flags_biu_trg;

drop table ERRM$PARAMETERS;
drop table ERRM$FEATURE_FLAGS;

drop table ERRM$LOG;
drop table ERRM$ERRORS;
drop table ERRM$ERROR_TYPES;

drop sequence ERRM$ERRORS_CODE_SEQ;
drop sequence ERRM$ERRORS_TYPE_SEQ;
drop sequence ERRM$LOG_SEQ;

drop package ERRM;

drop directory errm$log_dir;