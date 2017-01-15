create or replace package utl_xml_admin
as
  /* Prozedur zur Generierung eines XML-API fuer eine XSD-Datei
   * %param p_uxd_id ID der Schemadatei, fuer die ein API geschaffen werden soll
   * %param p_root_element_list Liste von Wurzelelementwerten, die als Einstiegspunkt
   *        in die XSD deklariert sind und fuer die ein API erstellt werden soll
   */
  procedure generate_xml_api(
    p_uxd_id in utl_xml_data.uxd_id%type,
    p_root_element_list in char_table);
end utl_xml_admin;
/