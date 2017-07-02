define sql_dir=sql/
define table_dir=&sql_dir.tables/
define type_dir=&sql_dir.types/
define view_dir=&sql_dir.views/
define plsql_dir=plsql/

prompt &h3.Check installation prerquisites
@check_prerequisites.sql

prompt &h3.Remove existing installation
@clean_up_install.sql

prompt &h3.Setting compile flags
@set_compile_flags.sql


prompt &h3.CREATE SEQUENCES


prompt &h3.CREATE MESSAGES
@create_messages.sql

prompt &h3.CREATE TABLES


prompt &h3.CREATE VIEWS
prompt &s1.Create view SCT_UI_ACTION_TYPE
--@&view_dir.sct_ui_action_type.vw



prompt &h3.Create packages
prompt &s1.Create package UTL_XML_CONST
@&plsql_dir.utl_xml_const.pks
show errors

prompt &s1.Create package CODE_GENERATOR
@&plsql_dir.code_generator.pks
show errors

prompt &s1.Create package Body CODE_GENERATOR
@&plsql_dir.code_generator.pkb
show errors

prompt &s1.Create package UTL_XML_ADMIN
@&plsql_dir.utl_xml_admin.pks
show errors

prompt &s1.Create package Body UTL_XML_ADMIN
@&plsql_dir.utl_xml_admin.pkb
show errors

