*&---------------------------------------------------------------------*
*& Reporte : ZR_EQUIP_ALV
*& Módulo  : PM — Plant Maintenance
*& Entorno : S/4HANA On-Premise / ECC  (NO aplica en BTP Cloud ABAP)
*&
*& Descripción:
*&   Lista de equipos de mantenimiento filtrada por centro.
*&   Muestra número, tipo, denominación, fechas de servicio y adquisición.
*&   Los equipos sin fecha de puesta en servicio aparecen en amarillo.
*&
*& Qué demuestra este ejercicio:
*&   - cl_salv_table: reemplazo moderno de REUSE_ALV_GRID_DISPLAY
*&   - SELECT con JOIN en sintaxis moderna (FROM ... INTO TABLE @lt_...)
*&   - Pantalla de selección con SELECT-OPTIONS y bloque enmarcado
*&   - Configuración de columnas: cabeceras en español, iconos de estado
*&   - Funciones estándar ALV: ordenar, filtrar, exportar a Excel
*&---------------------------------------------------------------------*
REPORT zr_equip_alv.

*----------------------------------------------------------------------*
* TIPOS: estructura de salida del ALV
* El campo ICON va primero — cl_salv_table lo muestra como columna icono
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_equip,
         icon  TYPE icon_d,        " Icono LED de estado (calculado en F_READ_DATA)
         equnr TYPE equi-equnr,    " Número de equipo
         eqtyp TYPE equi-eqtyp,    " Tipo de equipo (A=Genérico, M=Máquina, etc.)
         eqktx TYPE eqkt-eqktx,    " Denominación (texto corto del equipo)
         inbdt TYPE equi-inbdt,    " Fecha de puesta en servicio
         ansdt TYPE equi-ansdt,    " Fecha de adquisición
       END OF ty_equip.

*----------------------------------------------------------------------*
* PANTALLA DE SELECCIÓN
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  " Centro obligatorio: EQUI puede tener millones de filas en producción,
  " sin filtro la query podría saturar el sistema
  SELECT-OPTIONS so_werks FOR equi-swerk OBLIGATORY.
  SELECT-OPTIONS so_eqtyp FOR equi-eqtyp.
SELECTION-SCREEN END OF BLOCK b1.

*----------------------------------------------------------------------*
* VARIABLES GLOBALES
*----------------------------------------------------------------------*
DATA: lt_equip TYPE TABLE OF ty_equip,
      lo_alv   TYPE REF TO cl_salv_table.

*----------------------------------------------------------------------*
* INICIO DEL PROGRAMA
*----------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM f_read_data.
  PERFORM f_show_alv.


*&---------------------------------------------------------------------*
*& FORM F_READ_DATA
*& Lee EQUI (datos del equipo) + EQKT (texto en el idioma del usuario)
*&---------------------------------------------------------------------*
FORM f_read_data.

  SELECT e~equnr,
         e~eqtyp,
         e~inbdt,
         e~ansdt,
         t~eqktx
    FROM equi AS e
    LEFT OUTER JOIN eqkt AS t
      ON  t~equnr = e~equnr
      AND t~spras = @sy-langu         " Solo el texto en el idioma del usuario
    INTO CORRESPONDING FIELDS OF TABLE @lt_equip
    WHERE e~swerk IN @so_werks        " swerk = centro de planificación PM
      AND e~eqtyp IN @so_eqtyp
      AND e~lvorm = @space.           " Excluir equipos marcados para borrar

  IF lt_equip IS INITIAL.
    MESSAGE 'No se encontraron equipos para los criterios indicados'
            TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  " Asigna icono según si el equipo ya fue puesto en servicio
  LOOP AT lt_equip ASSIGNING FIELD-SYMBOL(<ls>).
    IF <ls>-inbdt IS INITIAL.
      <ls>-icon = ICON_LED_YELLOW.    " Pendiente de puesta en servicio
    ELSE.
      <ls>-icon = ICON_LED_GREEN.     " En servicio
    ENDIF.
  ENDLOOP.

ENDFORM.


*&---------------------------------------------------------------------*
*& FORM F_SHOW_ALV
*& Configura y muestra el ALV con cl_salv_table
*&---------------------------------------------------------------------*
FORM f_show_alv.

  CHECK lt_equip IS NOT INITIAL.

  " Factory: vincula la instancia ALV a la tabla interna lt_equip
  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = lo_alv
        CHANGING  t_table      = lt_equip ).
    CATCH cx_salv_msg INTO DATA(lx_err).
      MESSAGE lx_err->get_text( ) TYPE 'E'.
      RETURN.
  ENDTRY.

  " Activa todas las funciones estándar de la barra de herramientas:
  " ordenar, filtrar, agrupar, exportar a Excel/PDF, etc.
  lo_alv->get_functions( )->set_all( abap_true ).

  " Título del informe y rayas zebra para facilitar la lectura
  lo_alv->get_display_settings( )->set_list_header( 'Lista de Equipos de Mantenimiento' ).
  lo_alv->get_display_settings( )->set_striped_pattern( abap_true ).

  " Ajuste automático del ancho de cada columna al contenido
  DATA(lo_cols) = lo_alv->get_columns( ).
  lo_cols->set_optimize( abap_true ).

  " --- Cabeceras de columna en español ---
  " Patrón: get_column( nombre ) → cast a cl_salv_column_table → set texts
  " SHORT_TEXT: visible con poco espacio | LONG_TEXT: tooltip completo
  DATA lo_col TYPE REF TO cl_salv_column_table.

  DEFINE set_header.
    TRY.
      lo_col ?= lo_cols->get_column( &1 ).
      lo_col->set_short_text(  &2 ).
      lo_col->set_medium_text( &3 ).
      lo_col->set_long_text(   &4 ).
    CATCH cx_salv_not_found cx_sy_move_cast_error.
    ENDTRY.
  END-DEFINE.

  set_header 'ICON'  ''           ''               'Estado'.
  set_header 'EQUNR' 'Equipo'     'Nº Equipo'      'Número de Equipo'.
  set_header 'EQTYP' 'Tipo'       'Tipo'           'Tipo de Equipo'.
  set_header 'EQKTX' 'Descrip.'   'Descripción'    'Denominación del Equipo'.
  set_header 'INBDT' 'F.Servicio' 'Fecha Servicio' 'Fecha Puesta en Servicio'.
  set_header 'ANSDT' 'F.Adquis.'  'Fecha Adquis.'  'Fecha de Adquisición'.

  " Ordenación por defecto: por número de equipo ascendente
  TRY.
      lo_alv->get_sorts( )->add_sort( columnname = 'EQUNR' ).
    CATCH cx_salv_not_found cx_salv_existing cx_salv_data_error.
  ENDTRY.

  lo_alv->display( ).

ENDFORM.
