*&---------------------------------------------------------------------*
*& Programa : ZR_MATERIALES_YPALACIOS
*& Módulo   : MM — Materials Management
*& Entorno  : ECC / S/4HANA On-Premise
*&
*& Descripción:
*&   Reporte de materiales activos filtrado por tipo y centro.
*&   Muestra número, descripción, tipo y planta asignada.
*&   Despliega el resultado en ALV con CL_SALV_TABLE.
*&
*& Basado en: ejercicio de formación TAW10 (Report.docx del curso)
*& Qué se mejoró respecto al código original del curso:
*&   1. SELECT con JOIN en lugar de FOR ALL ENTRIES + bucle doble anidado
*&      (el original tenía O(n²) en el LOOP, esto es O(n) en la BD)
*&   2. Idioma dinámico con SY-LANGU en lugar de 'S' hardcodeado
*&   3. SELECTION-SCREEN con SELECT-OPTIONS (el original no tenía)
*&   4. CL_SALV_TABLE con cabeceras en español (el original usaba WRITE)
*&   5. Modularización con FORM/ENDFORM en lugar de código en línea
*&---------------------------------------------------------------------*
REPORT zr_materiales_ypalacios.

*----------------------------------------------------------------------*
* TIPOS — estructura de salida del ALV
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_output,
         matnr TYPE mara-matnr,   " Número de material
         mtart TYPE mara-mtart,   " Tipo de material (ROH, FERT, HALB...)
         werks TYPE marc-werks,   " Centro (planta) asignado
         maktx TYPE makt-maktx,   " Descripción en el idioma del usuario
       END OF ty_output.

*----------------------------------------------------------------------*
* PANTALLA DE SELECCIÓN
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  " Filtro por tipo de material — en el curso lo teníamos hardcodeado a ROH/HALB/FERT
  SELECT-OPTIONS so_mtart FOR mara-mtart DEFAULT 'FERT'.
  " Filtro por centro — imprescindible en producción (MARC puede tener millones de filas)
  SELECT-OPTIONS so_werks FOR marc-werks.
SELECTION-SCREEN END OF BLOCK b1.

*----------------------------------------------------------------------*
* VARIABLES GLOBALES
*----------------------------------------------------------------------*
DATA: gt_output TYPE TABLE OF ty_output,
      go_alv    TYPE REF TO cl_salv_table.

*----------------------------------------------------------------------*
* INICIO DEL PROGRAMA
*----------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM f_leer_datos.
  PERFORM f_mostrar_alv.


*&---------------------------------------------------------------------*
*& FORM F_LEER_DATOS
*& Obtiene materiales de MARA + texto de MAKT + centros de MARC.
*&
*& Mejora clave: el código del curso usaba dos SELECT separados + un
*& LOOP AT / READ TABLE para cruzar los datos. Aquí usamos un JOIN directo
*& que ejecuta una sola query en base de datos — más eficiente y legible.
*&---------------------------------------------------------------------*
FORM f_leer_datos.

  " JOIN de tres tablas: MARA (datos del material) + MAKT (texto) + MARC (centro)
  " La condición AND mara~lvorm = '' excluye los materiales marcados para borrado
  SELECT mara~matnr,
         mara~mtart,
         marc~werks,
         makt~maktx
    FROM mara
    INNER JOIN marc ON marc~matnr = mara~matnr
    INNER JOIN makt ON makt~matnr = mara~matnr
                   AND makt~spras = @sy-langu     " idioma del usuario en sesión
    INTO TABLE @gt_output
    WHERE mara~mtart IN @so_mtart
      AND mara~lvorm =  ''                        " excluir borrados lógicos
      AND marc~werks IN @so_werks.

  IF gt_output IS INITIAL.
    MESSAGE 'No se encontraron materiales con los filtros indicados.' TYPE 'S'
            DISPLAY LIKE 'W'.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& FORM F_MOSTRAR_ALV
*& Configura y muestra el ALV con CL_SALV_TABLE.
*&
*& Mejora clave: el código del curso mostraba los datos con WRITE (lista
*& clásica). CL_SALV_TABLE da al usuario opciones de filtro, ordenación
*& y exportación a Excel de forma gratuita, sin código adicional.
*&---------------------------------------------------------------------*
FORM f_mostrar_alv.

  " Crear instancia del ALV a partir de la tabla interna
  TRY.
    cl_salv_table=>factory(
      IMPORTING r_salv_table = go_alv
      CHANGING  t_table      = gt_output
    ).
  CATCH cx_salv_msg INTO DATA(lx_err).
    MESSAGE lx_err->get_text( ) TYPE 'E'.
    RETURN.
  ENDTRY.

  " Activar funciones estándar: ordenar, filtrar, exportar a Excel
  go_alv->get_functions( )->set_all( abap_true ).

  " Configurar optimización automática del ancho de columnas
  go_alv->get_display_settings( )->set_fit_column_width( abap_true ).

  " Configurar cabeceras de columna en español
  PERFORM f_configurar_columnas.

  " Mostrar el ALV
  go_alv->display( ).

ENDFORM.


*&---------------------------------------------------------------------*
*& FORM F_CONFIGURAR_COLUMNAS
*& Pone cabeceras en español y ajusta columnas individuales.
*&---------------------------------------------------------------------*
FORM f_configurar_columnas.

  DATA: lo_cols TYPE REF TO cl_salv_columns_table,
        lo_col  TYPE REF TO cl_salv_column_table.

  lo_cols = go_alv->get_columns( ).

  " MATNR — número de material
  TRY.
    lo_col ?= lo_cols->get_column( 'MATNR' ).
    lo_col->set_short_text( 'Material' ).
    lo_col->set_medium_text( 'N° Material' ).
    lo_col->set_long_text( 'Número de Material' ).
  CATCH cx_salv_not_found. "#EC NO_HANDLER
  ENDTRY.

  " MTART — tipo de material
  TRY.
    lo_col ?= lo_cols->get_column( 'MTART' ).
    lo_col->set_short_text( 'Tipo' ).
    lo_col->set_medium_text( 'Tipo Mat.' ).
    lo_col->set_long_text( 'Tipo de Material' ).
  CATCH cx_salv_not_found. "#EC NO_HANDLER
  ENDTRY.

  " WERKS — centro
  TRY.
    lo_col ?= lo_cols->get_column( 'WERKS' ).
    lo_col->set_short_text( 'Centro' ).
    lo_col->set_medium_text( 'Centro' ).
    lo_col->set_long_text( 'Centro (Planta)' ).
  CATCH cx_salv_not_found. "#EC NO_HANDLER
  ENDTRY.

  " MAKTX — descripción
  TRY.
    lo_col ?= lo_cols->get_column( 'MAKTX' ).
    lo_col->set_short_text( 'Descrip.' ).
    lo_col->set_medium_text( 'Descripción' ).
    lo_col->set_long_text( 'Descripción del Material' ).
  CATCH cx_salv_not_found. "#EC NO_HANDLER
  ENDTRY.

ENDFORM.
