create or replace package body utl_xml_admin 
as
  
  c_pkg constant varchar2(30) := $$PLSQL_UNIT;
  c_analyze_xsd_id constant utl_xml_data.uxd_id%type := 1;
  c_true constant char(1 byte) := 'Y';
  c_false constant char(1 byte) := 'N';
  cr constant char(1 byte) := chr(13);
  c_choice constant varchar2(10) := 'CHOICE';
  c_multi constant varchar2(10) := 'MULTI';
  c_merge constant varchar2(10) := 'MERGE';

  c_target_namespace varchar2(100) := 'http://wsekazo.ekasse.bund.drv.de/types';  
  -- Konstante, die dem Packagenamen vorangestellt wird
  c_pkg_prefix constant varchar2(10) := 'XML_API_';
  -- Liste von XML-Element-Praefixen, die fuer die Namensgebung entfernt werden sollen.
  c_prefix_list constant char_table := char_table('ip_rec');

  g_pkg_spec clob;
  g_pkg_body clob;
  g_pkg_specs clob;
  g_pkg_bodies clob;
  
  cursor xml_data(
    p_uxd_id in utl_xml_data.uxd_id%type,
    p_root_element_list in char_table)
  is
      with xsl as (
           select uxd_content xsl
             from utl_xml_data
            where uxd_id = c_analyze_xsd_id),
           data as (
           select x.uxd_content.transform(s.xsl) xml
             from utl_xml_data x
            cross join xsl s
            where uxd_id = p_uxd_id),
           root_elements as (
           select column_value root_element
             from table(p_root_element_list))
    select case when x.choice = 'Y' and pattern is not null then 'CHOICE'
                when x.multi = 'Y' THEN 'MULTI'
                else 'MERGE' end proc_type,
           case when pattern is null then x.name else x.parent end proc_name, x.parent, x.name,
           regexp_substr(x.element_path, '[^/]+', 1, 1) root_element,
           x.optional, x.data_type, x.element_path, x.pattern, case when pattern is not null then 0 else order_seq end order_seq,
           row_number() over (partition by case when pattern is not null then name else parent end order by case when pattern is not null then 0 else order_seq end) seq,
           count(*) over (partition by case when pattern is not null then name else parent end) amount
      from data d
     cross join 
           xmltable(
             '/schema/einsprungpunkt/element'
             passing d.xml
             columns
               parent varchar2(30) path '@parent',
               order_seq number path '@position',
               name varchar2(30) path '@name',
               choice char(1) path '@choice',
               multi char(1) path '@multi',
               optional char(1) path '@optional',
               data_type varchar2(30) path '@dataType',
               element_path varchar2(200) path '@path',
               pattern xmltype path '*') x
       join root_elements r on regexp_substr(x.element_path, '[^/]+', 1, 1) = r.root_element
      order by case when pattern is not null then name else parent end, case when pattern is not null then 0 else order_seq end;

  type proc_list is table of xml_data%rowtype;

  /* HILFSMETHODEN */
  -- initialisiert die CLOBs
  procedure initialize
  as
  begin
    dbms_lob.createtemporary(g_pkg_spec, false, dbms_lob.call);
    dbms_lob.createtemporary(g_pkg_body, false, dbms_lob.call);
    dbms_lob.createtemporary(g_pkg_specs, false, dbms_lob.call);
    dbms_lob.createtemporary(g_pkg_bodies, false, dbms_lob.call);
  end initialize;
  
  
  -- Ermittelt Prozedurname aus dem einzufuegenden Element
  function get_proc_name(
    p_row in xml_data%rowtype)
    return varchar2
  as
    l_raw_name varchar2(30);
  begin
    l_raw_name := case when p_row.pattern is null then p_row.parent else p_row.name end;
    for i in c_prefix_list.first .. c_prefix_list.last loop
      l_raw_name := replace(l_raw_name, c_prefix_list(i));
    end loop;
    return upper(substr(l_raw_name, 1, 23));
  end get_proc_name;
  
  
  -- Erstellt Prozedur-Spezifikationen fuer das Wurzelelement und fuegt es der 
  -- List der Prozedur-Spezifikationen hinzu
  procedure add_proc_spec(
    p_row in xml_data%rowtype)
  as
    c_add constant varchar2(10) := 'ADD_';
    c_remove constant varchar2(10) := 'REMOVE_';
    c_merge constant varchar2(10) := 'MERGE_';
    l_proc_name varchar2(23);
  begin
    l_proc_name := get_proc_name(p_row);
    if p_row.proc_type = c_multi then
      dbms_lob.append(
        g_pkg_specs, 
        utl_text.bulk_replace(utl_xml_const.proc_spec_template, char_table(
          '#PROC_NAME#', c_add || l_proc_name,
          '#XPATH#', p_row.element_path,
          '#CR#', cr)));
      dbms_lob.append(
        g_pkg_bodies, 
        utl_text.bulk_replace(utl_xml_const.proc_body_template, char_table(
          '#PROC_NAME#', c_add || l_proc_name,
          '#PROC_BODY#', '#' || c_add || 'BODY#',
          '#CR#', cr)));
      dbms_lob.append(
        g_pkg_specs, 
        utl_text.bulk_replace(utl_xml_const.proc_spec_template, char_table(
          '#PROC_NAME#', c_remove || l_proc_name,
          '#XPATH#', p_row.element_path,
          '#CR#', cr)));
      dbms_lob.append(
        g_pkg_bodies, 
        utl_text.bulk_replace(utl_xml_const.proc_body_template, char_table(
          '#PROC_NAME#', c_remove || l_proc_name,
          '#PROC_BODY#', '#' || c_remove || 'BODY#',
          '#CR#', cr)));
    end if;
    dbms_lob.append(
      g_pkg_specs, 
      utl_text.bulk_replace(utl_xml_const.proc_spec_template, char_table(
        '#PROC_NAME#', c_merge || l_proc_name,
        '#XPATH#', case when p_row.pattern is null then replace(p_row.element_path, '/'|| p_row.name) else p_row.element_path end,
        '#CR#', cr)));
      dbms_lob.append(
        g_pkg_bodies, 
        utl_text.bulk_replace(utl_xml_const.proc_body_template, char_table(
          '#PROC_NAME#', c_merge || l_proc_name,
          '#PROC_BODY#', '#' || c_merge || 'BODY#',
          '#CR#', cr)));
  end add_proc_spec;
  
  
  procedure add_proc_body(
    p_proc_list in out nocopy proc_list)
  as
    l_first_row xml_data%rowtype;
    l_row xml_data%rowtype;
    l_merge_query varchar2(32767);
    l_add_query varchar2(32767);
    l_remove_query varchar2(32767);
    l_replace_list varchar2(32767);
    l_col_list varchar2(32767);
  begin
    l_first_row := p_proc_list(p_proc_list.first);
    if l_first_row.proc_type = c_multi then
      l_add_query := utl_text.bulk_replace(utl_xml_const.xquery_replace_template, char_table(
                       '#NAMESPACE#', c_target_namespace,
                       '#SESSION_ID#', v('SESSION'),
                       '#ROOT_ELEMENT#', l_first_row.root_element));
      l_remove_query := utl_text.bulk_replace(utl_xml_const.xquery_replace_template, char_table(
                          '#NAMESPACE#', c_target_namespace,
                          '#SESSION_ID#', v('SESSION'),
                          '#ROOT_ELEMENT#', l_first_row.root_element));
    end if;
    l_merge_query := utl_text.bulk_replace(utl_xml_const.xquery_replace_template, char_table(
                       '#NAMESPACE#', c_target_namespace,
                       '#SESSION_ID#', v('SESSION'),
                       '#ROOT_ELEMENT#', l_first_row.root_element));
    for i in p_proc_list.first .. p_proc_list.last loop
      l_row := p_proc_list(i);
      utl_text.append(l_replace_list,
        utl_text.bulk_replace(
          utl_xml_const.col_replace_template, char_table(
            '#ELEMENT#', l_row.name,
            '#ELEMENT_PATH#', l_row.name)));
      utl_text.append(l_col_list,
        utl_text.bulk_replace(
          utl_xml_const.col_template, char_table(
            '#ELEMENT#', upper(l_row.name))));
      if i < p_proc_list.last then
        l_col_list := l_col_list || utl_xml_const.col_delimiter;
      end if;
    end loop;
    l_merge_query := utl_text.bulk_replace(l_merge_query, char_table(
                      '#COL_REPLACE_LIST#', l_replace_list,
                      '#COL_LIST#', l_col_list));
    g_pkg_bodies := replace(g_pkg_bodies, '#XQUERY#', l_merge_query);
    p_proc_list.delete();
  end add_proc_body;


  procedure wrap_spec(
    p_stmt in out nocopy clob,
    p_spec in clob,
    p_name in varchar2)
  as
    l_spec_start varchar2(1000);
    l_spec_end varchar2(1000);
  begin
    l_spec_start := utl_text.bulk_replace(utl_xml_const.pkg_spec_template_start, char_table(
                      '#PKG_NAME#', p_name,
                      '#CR#', cr));
    l_spec_end := utl_text.bulk_replace(utl_xml_const.pkg_spec_template_end, char_table(
                    '#PKG_NAME#', p_name,
                    '#CR#', cr));
    dbms_lob.append(p_stmt, l_spec_start || p_spec || l_spec_end);
  end wrap_spec;


  procedure wrap_body(
    p_stmt in out nocopy clob,
    p_body in clob,
    p_name in varchar2)
  as
    l_body_start varchar2(1000);
    l_body_end varchar2(1000);
  begin
    l_body_start := utl_text.bulk_replace(utl_xml_const.pkg_body_template_start, char_table(
                      '#PKG_NAME#', p_name,
                      '#CR#', cr));
    l_body_end := utl_text.bulk_replace(utl_xml_const.pkg_body_template_end, char_table(
                    '#PKG_NAME#', p_name,
                    '#CR#', cr));
    dbms_lob.append(p_stmt, l_body_start || p_body || l_body_end);
  end wrap_body;
  
  
  procedure generate_xml_api(
    p_uxd_id in utl_xml_data.uxd_id%type,
    p_root_element_list in char_table) 
  as
    l_proc_list proc_list := proc_list();
    l_root_element varchar2(30);
  begin
    initialize;
    for el in xml_data(p_uxd_id, p_root_element_list) loop
      l_root_element := c_pkg_prefix || upper(el.root_element);
      if el.seq = 1 then
        add_proc_spec(el);
      end if;
      if el.order_seq > 0 then
        -- Elemente vermerken, die fuer den Body verwendet werden
        l_proc_list.extend();
        l_proc_list(l_proc_list.count) := el;
      end if;
      if el.seq = el.amount then
        -- Ende der Prozedur erreicht, Body erstellen
        add_proc_body(l_proc_list);
      end if;
    end loop;
    wrap_spec(g_pkg_spec, g_pkg_specs, l_root_element);
    wrap_body(g_pkg_body, g_pkg_bodies, l_root_element);
    dbms_output.put_line(g_pkg_spec);
    dbms_output.put_line(g_pkg_body);
  end generate_xml_api;

end utl_xml_admin;
/