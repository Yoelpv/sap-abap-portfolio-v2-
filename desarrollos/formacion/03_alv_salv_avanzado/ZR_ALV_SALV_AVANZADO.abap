*&---------------------------------------------------------------------*
*& Programa : ZR_ALV_SALV_AVANZADO
*& Módulo   : MM — Materials Management
*& Entorno  : ECC / S/4HANA On-Premise
*&
*& Descripción:
*&   ALV avanzado con CL_SALV_TABLE mostrando materiales por centro.
*&   Incluye: cabeceras en español, ordenación por defecto, color
*&   condicional por tipo de material y botón personalizado en toolbar.
*&
*& ORIGEN DIRECTO: Este ejercicio es la evolución del código que escribí
*& durante la formación (z_ypalacios_lock_t44_v2). El código original ya
*& usaba CL_SALV_TABLE=>FACTORY() pero se quedaba en el display básico.
*&
*& Qué se añadió respecto al código original:
*&   1. Cabeceras de columna en español (antes: nombres técnicos del campo)
*&   2. Ordenación por defecto al abrir el ALV (MATNR ascendente)
*&   3. Coloreado de filas: FERT en azul, ROH en verde, resto sin color
*&   4. Botón personalizado en la barra de herramientas (refresco de datos)
*&   5. Manejo de eventos con una clase local (SET HANDLER)
*&---------------------------------------------------------------------*
REPORT zr_alv_salv_avanzado.

*----------------------------------------------------------------------*
* TIPOS
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_material,
         " Campo de color: CL_SALV_TABLE busca la columna T_COLOR
         " para colorear filas. Debe ser de tipo LVC_T_SCOL.
         t_color TYPE lvc_t_scol,
         matnr   TYPE mara-matnr,
         mtart   TYPE mara-mtart,
         werks   TYPE marc-werks,
         maktx   TYPE makt-maktx,
         netpr   TYPE mbew-verpr,  " Precio medio ponderado
         meins   TYPE mara-meins,  " Unidad de medida base
       END OF ty_material.

*----------------------------------------------------------------------*
* CLASE LOCAL DE EVENTOS
* CL_SALV_TABLE lanza eventos; para capturarlos necesitamos una clase
* que implemente la interfaz IF_SALV_EVENTS_FUNCTIONS.
*----------------------------------------------------------------------*
CLASS lcl_eventos DEFINITION.
  PUBLIC SECTION.
    " Evento USER_COMMAND: se dispara cuando el usuario pulsa un botón
    METHODS on_user_command
      FOR EVENT added_function OF cl_salv_events_functions
      IMPORTING e_salv_function.
ENDCLASS.

CLASS lcl_eventos IMPLEMENTATION.
  METHOD on_user_command.
    " Botón personalizado "REFRESCA": volver a leer y recargar el ALV
    CASE e_salv_function.
      WHEN 'REFRESCA'.
        " En un caso real aquí se llamaría al FORM de lectura de datos
        MESSAGE 'Función de refresco ejecutada.' TYPE 'S'.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* PANTALLA DE SELECCIÓN
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS so_mtart FOR mara-mtart.
  SELECT-OPTIONS so_werks FOR marc-werks OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b1.

*----------------------------------------------------------------------*
* VARIABLES GLOBALES
*----------------------------------------------------------------------*
DATA: gt_materials TYPE TABLE OF ty_material,
      go_alv       TYPE REF TO cl_salv_table,
      go_eventos   TYPE REF TO lcl_eventos.

*----------------------------------------------------------------------*
* INICIO
*----------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM f_leer_datos.
  PERFORM f_mostrar_alv.


*&---------------------------------------------------------------------*
*& FORM F_LEER_DATOS
*& Lee materiales con JOIN y calcula el color de cada fila.
*&---------------------------------------------------------------------*
FORM f_leer_datos.

  DATA ls_mat TYPE ty_material.
  DATA ls_color TYPE lvc_s_scol.

  " Leer datos base con JOIN (sin el campo T_COLOR, que es calculado)
  SELECT mara~matnr,
         mara~mtart,
         marc~werks,
         makt~maktx,
         mbew~verpr AS netpr,
         mara~meins
    FROM mara
    INNER JOIN marc ON marc~matnr = mara~matnr
    INNER JOIN makt ON makt~matnr = mara~matnr
                   AND makt~spras = @sy-langu
    LEFT OUTER JOIN mbew ON mbew~matnr = mara~matnr
                        AND mbew~bwkey = marc~werks
    INTO TABLE @DATA(lt_raw)
    WHERE mara~mtart IN @so_mtart
      AND mara~lvorm =  ''
      AND marc~werks IN @so_werks.

  IF lt_raw IS INITIAL.
    MESSAGE 'Sin datos para los filtros indicados.' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  " Calcular color por fila según tipo de material
  LOOP AT lt_raw INTO DATA(ls_raw).
    CLEAR ls_mat.
    MOVE-CORRESPONDING ls_raw TO ls_mat.

    " Limpiar color anterior y calcular el nuevo
    CLEAR ls_mat-t_color.

    CASE ls_raw-mtart.
      WHEN 'FERT'.
        " Producto terminado → fondo azul claro (color SAP 1)
        ls_color-col = col_heading.    " Azul
        ls_color-int = 1.
        ls_color-inv = 0.
        APPEND ls_color TO ls_mat-t_color.

      WHEN 'ROH'.
        " Materia prima → fondo verde claro (color SAP 5)
        ls_color-col = col_positive.   " Verde
        ls_color-int = 1.
        ls_color-inv = 0.
        APPEND ls_color TO ls_mat-t_color.

      WHEN 'HALB'.
        " Semielaborado → fondo amarillo (color SAP 3)
        ls_color-col = col_key.        " Amarillo/key
        ls_color-int = 1.
        ls_color-inv = 0.
        APPEND ls_color TO ls_mat-t_color.
        " Resto → sin color (fila normal)
    ENDCASE.

    APPEND ls_mat TO gt_materials.
  ENDLOOP.

ENDFORM.


*&---------------------------------------------------------------------*
*& FORM F_MOSTRAR_ALV
*& Crea y configura el ALV con todas las opciones avanzadas.
*&---------------------------------------------------------------------*
FORM f_mostrar_alv.

  CHECK gt_materials IS NOT INITIAL.

  " Crear instancia
  TRY.
    cl_salv_table=>factory(
      IMPORTING r_salv_table = go_alv
      CHANGING  t_table      = gt_materials
    ).
  CATCH cx_salv_msg INTO DATA(lx_err).
    MESSAGE lx_err->get_text( ) TYPE 'E'.
    RETURN.
  ENDTRY.

  " Funciones estándar (filtro, ordenación, Excel)
  go_alv->get_functions( )->set_all( abap_true ).

  " Añadir botón personalizado "REFRESCA" a la toolbar
  " El icono ICON_REFRESH muestra el símbolo de refresco estándar
  TRY.
    go_alv->get_functions( )->add_function(
      name     = 'REFRESCA'
      icon     = CONV string( icon_refresh )
      text     = 'Refrescar'
      tooltip  = 'Volver a leer los datos del sistema'
      position = if_salv_c_function_position=>right_of_salv_functions
    ).
  CATCH cx_salv_existing cx_salv_wrong_call. "#EC NO_HANDLER
  ENDTRY.

  " Registrar manejador de eventos
  CREATE OBJECT go_eventos.
  SET HANDLER go_eventos->on_user_command FOR go_alv->get_event( ).

  " Ocultar la columna T_COLOR (es técnica, el usuario no debe verla)
  TRY.
    go_alv->get_columns( )->get_column( 'T_COLOR' )->set_visible( abap_false ).
  CATCH cx_salv_not_found. "#EC NO_HANDLER
  ENDTRY.

  " Activar coloreado de filas
  go_alv->get_display_settings( )->set_row_coloring( abap_true ).

  " Ajuste automático de anchura de columnas
  go_alv->get_display_settings( )->set_fit_column_width( abap_true ).

  " Ordenación por defecto: número de material ascendente
  TRY.
    DATA(lo_sorts) = go_alv->get_sorts( ).
    lo_sorts->add_sort(
      columnname = 'MATNR'
      order      = if_salv_c_sort_order=>ascending
    ).
  CATCH cx_salv_not_found cx_salv_existing cx_salv_data_error. "#EC NO_HANDLER
  ENDTRY.

  " Configurar cabeceras en español
  PERFORM f_configurar_columnas.

  go_alv->display( ).

ENDFORM.


*&---------------------------------------------------------------------*
*& FORM F_CONFIGURAR_COLUMNAS
*& Pone textos en español en todas las columnas del ALV.
*&---------------------------------------------------------------------*
FORM f_configurar_columnas.

  DATA: lo_col TYPE REF TO cl_salv_column_table.

  DEFINE set_col_text.
    TRY.
      lo_col ?= go_alv->get_columns( )->get_column( &1 ).
      lo_col->set_short_text(  &2 ).
      lo_col->set_medium_text( &3 ).
      lo_col->set_long_text(   &4 ).
    CATCH cx_salv_not_found. "#EC NO_HANDLER
    ENDTRY.
  END-OF-DEFINITION.

  set_col_text 'MATNR' 'Material' 'N° Material'   'Número de Material'.
  set_col_text 'MTART' 'Tipo'     'Tipo Mat.'     'Tipo de Material'.
  set_col_text 'WERKS' 'Centro'   'Centro'        'Centro (Planta)'.
  set_col_text 'MAKTX' 'Descrip.' 'Descripción'   'Descripción del Material'.
  set_col_text 'NETPR' 'Precio'   'Precio medio'  'Precio Medio Ponderado'.
  set_col_text 'MEINS' 'UM'       'Unidad med.'   'Unidad de Medida Base'.

ENDFORM.
