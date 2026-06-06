*&---------------------------------------------------------------------*
*& Include : ZR_MATERIALES_MODULAR_F01
*& Programa: ZR_MATERIALES_MODULAR
*&
*& Contenido: Subrutinas FORM/ENDFORM con toda la lógica del programa.
*&
*& Basado en: ZNNAVARROI_INCLUDE.docx del curso.
*& Mejoras aplicadas:
*&   - Nombres de FORMs descriptivos (antes: busqueda, procesar, borrar)
*&   - Parámetros tipados correctamente (USING/CHANGING según corresponde)
*&   - Mensajes al usuario claros (antes: MESSAGE TEXT-001 sin contexto)
*&   - Join en el SELECT en lugar de FOR ALL ENTRIES + LOOP anidado
*&   - MODIFY con tabla interna completa (más eficiente que fila a fila)
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& FORM F_INICIALIZAR
*& Pre-rellena los select-options con valores habituales de negocio.
*& Se ejecuta en el evento INITIALIZATION (antes de la pantalla).
*&---------------------------------------------------------------------*
FORM f_inicializar.

  " Activar tipos de material más comunes por defecto
  " El usuario puede añadir o quitar en la pantalla de selección
  so_mtart-sign   = 'I'.
  so_mtart-option = 'EQ'.
  so_mtart-low    = 'ROH'.   " Materia prima
  APPEND so_mtart.
  so_mtart-low    = 'HALB'.  " Semielaborado
  APPEND so_mtart.
  so_mtart-low    = 'FERT'.  " Producto terminado
  APPEND so_mtart.

  REFRESH gt_materials.

ENDFORM.


*&---------------------------------------------------------------------*
*& FORM F_VALIDAR_SELECCION
*& Valida que los parámetros de la pantalla sean coherentes.
*& Se ejecuta en AT SELECTION-SCREEN (si hay error, SAP no continúa).
*&---------------------------------------------------------------------*
FORM f_validar_seleccion.

  IF so_mtart IS INITIAL AND p_carga = 'X'.
    " Avisar al usuario que sin filtro de tipo se leerían todos los materiales
    " (puede ser muy lento en sistemas productivos)
    MESSAGE 'Indica al menos un tipo de material para la carga.' TYPE 'W'.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& FORM F_BUSCAR_DATOS
*& Lee materiales de MARA/MAKT/MARC según los filtros de la pantalla.
*& Solo actúa en modo "Carga" (P_CARGA = 'X').
*&---------------------------------------------------------------------*
FORM f_buscar_datos.

  " En modo "borrar" no hay nada que leer
  CHECK p_carga = 'X'.

  " JOIN directo — en el código del curso se hacían tres SELECT separados
  " y luego un LOOP/READ TABLE para cruzarlos (O(n²)). El JOIN es más limpio.
  SELECT mara~matnr,
         mara~mtart,
         marc~werks,
         makt~maktx
    FROM mara
    INNER JOIN marc ON marc~matnr  = mara~matnr
    INNER JOIN makt ON makt~matnr  = mara~matnr
                   AND makt~spras  = @sy-langu
    INTO TABLE @gt_materials
    WHERE mara~mtart IN @so_mtart
      AND mara~lvorm =  ''          " excluir materiales marcados para borrado
      AND marc~werks IN @so_werks.

  IF sy-subrc <> 0.
    gv_error = 'X'.
    MESSAGE 'No se encontraron materiales con los criterios indicados.' TYPE 'S'
            DISPLAY LIKE 'W'.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& FORM F_PROCESAR_DATOS
*& Guarda los materiales encontrados en la tabla Z, o bien la borra.
*&
*& La tabla ZMATERIALES_YP debe existir en el Diccionario de Datos (SE11)
*& con la misma estructura que TY_MATERIAL (definida en _TOP).
*&---------------------------------------------------------------------*
FORM f_procesar_datos.

  IF p_carga = 'X'.
    " -------------------------
    " Modo CARGA: guardar en Z
    " -------------------------
    CHECK gv_error IS INITIAL AND gt_materials IS NOT INITIAL.

    " MODIFY inserta si no existe y actualiza si ya existe (por clave primaria)
    " Más seguro que INSERT puro, que fallaría si el registro ya está
    MODIFY zmateriales_yp FROM TABLE gt_materials.

    IF sy-subrc = 0.
      MESSAGE |Se cargaron { lines( gt_materials ) } materiales correctamente.| TYPE 'S'.
    ELSE.
      MESSAGE 'Error al guardar los datos en la tabla Z.' TYPE 'S' DISPLAY LIKE 'E'.
    ENDIF.

  ELSE.
    " -------------------------
    " Modo BORRADO: limpiar tabla Z
    " -------------------------
    DELETE FROM zmateriales_yp.   " Borra todos los registros de la tabla

    IF sy-subrc = 0.
      MESSAGE 'Tabla ZMATERIALES_YP borrada correctamente.' TYPE 'S'.
    ELSE.
      MESSAGE 'La tabla estaba vacía o se produjo un error al borrar.' TYPE 'S'
              DISPLAY LIKE 'W'.
    ENDIF.

  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*& FORM F_MOSTRAR_RESULTADO
*& Muestra los materiales procesados en un ALV rápido (SALV).
*& Solo en modo carga y si hay datos.
*&---------------------------------------------------------------------*
FORM f_mostrar_resultado.

  CHECK p_carga = 'X' AND gt_materials IS NOT INITIAL.

  DATA lo_alv TYPE REF TO cl_salv_table.

  TRY.
    cl_salv_table=>factory(
      IMPORTING r_salv_table = lo_alv
      CHANGING  t_table      = gt_materials
    ).
    lo_alv->get_functions( )->set_all( abap_true ).
    lo_alv->get_display_settings( )->set_fit_column_width( abap_true ).
    lo_alv->display( ).
  CATCH cx_salv_msg INTO DATA(lx_err).
    MESSAGE lx_err->get_text( ) TYPE 'E'.
  ENDTRY.

ENDFORM.
