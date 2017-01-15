@init.sql

alter session set current_schema=&INSTALL_USER.;

prompt &h1.State Chart Toolkit (SCT)) Deinstallation

prompt &h2.Deinstall APEX application
@apex/clean_up.sql

prompt &h2.Deinstall PLUGIN
@plugin/clean_up.sql

prompt &h2.Deinstall CORE Functionality
@core/clean_up_install.sql

exit;
