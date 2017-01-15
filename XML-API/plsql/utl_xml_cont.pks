create or replace package utl_xml_const
as

  xquery_replace_template constant varchar2(1000) := q'^
    update utl_xml_session_state
       set uxs_xml_content =
           xmlquery('declare default element namespace "#NAMESPACE#"; (: :)
                     copy $i := $x modify
                       (#COL_REPLACE_LIST#
                       )
                       return $i'
                     passing 
                       uxs_xml_content as "x",#COL_LIST#
                     returning content)
     where uxs_session_id = (select v('SESSION') from dual)
       and uxs_root_element = '#ROOT_ELEMENT#';^';

  col_replace_template constant varchar2(1000) := q'^
                         (for $j in $i#ELEMENT_PATH# return replace value of node $j with $#ELEMENT#)^';
  col_template constant varchar2(100) := q'^
                       l_page_values('#ELEMENT#') as "#ELEMENT#"^';
  col_delimiter constant char(1) := ',';
  
  pkg_spec_template_start constant varchar2(1000) := q'^create or replace package #PKG_NAME##CR#as#CR#^';
  pkg_spec_template_end constant varchar2(1000) := q'^end #PKG_NAME#;#CR#/#CR#^';

  pkg_body_template_start constant varchar2(1000) := q'^create or replace package body #PKG_NAME##CR#as#CR#^';
  pkg_body_template_end constant varchar2(1000) := q'^end #PKG_NAME#;#CR#/#CR#^';
   
  proc_spec_template constant varchar2(1000) := q'^  -- Prozedur zur Verwaltung des Elements #XPATH##CR#  procedure #PROC_NAME#;#CR##CR#^';
  proc_body_template constant varchar2(1000) := q'^  procedure #PROC_NAME##CR#  as#CR#    l_page_values utl_apex.value_table;#CR#  begin#CR#    l_page_values := utl_apex.get_page_values;#CR#    #XQUERY##CR#  end #PROC_NAME#;#CR##CR#^';

  proc_content constant varchar2(1000) := '    -- Element #ELEMENT##CR#';
end utl_xml_const;
/