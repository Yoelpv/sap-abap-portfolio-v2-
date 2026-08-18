*&---------------------------------------------------------------------*
*&  Include  ZALV_SFLIGHT_OCUPACION_F01
*&  FORMs de logica de negocio:
*&    CHEQUEAR_AEROLINEA      -> validacion en pantalla de seleccion
*&    PRINCIPAL               -> coordinador de flujo principal
*&    OBTENER_DATOS           -> SELECT JOIN SCARR/SFLIGHT
*&    ANADIR_DATOS_A_CONSULTA -> calcular % y asignar icono semaforo
*&    USER_COMMAND_0100       -> navegacion back/exit del Dynpro
*&    CARGA_DATOS_ALV         -> inicializar grid + registrar eventos
*&    CONSTRUIR_CATALOGO_ALV  -> definir columnas del ALV
*&    MOSTRAR_POPUP_INFORMACION -> popup de detalle de vuelo seleccionado
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&  FORM CHEQUEAR_AEROLINEA
*&  Valida que la aerolinea introducida en la seleccion exista en SCARR.
*&  Se llama desde AT SELECTION-SCREEN ON p_carrid (report principal).
*&---------------------------------------------------------------------*
FORM chequear_aerolinea USING i_carrid TYPE s_carr_id.
  DATA: ls_scarr TYPE scarr.

  " El campo es obligatorio; se corta con mensaje de error tipo 'E'
  IF i_carrid IS INITIAL.
    MESSAGE e000(z_mensajes_01). " 'El dato ID AEROLINEA es obligatorio'
  ENDIF.

  " Comprobamos que la aerolinea existe en el maestro SCARR
  SELECT SINGLE * INTO ls_scarr FROM scarr
    WHERE carrid EQ i_carrid.

  " Guardamos el nombre para usarlo en el titulo del ALV
  gv_nombreaerolinea = ls_scarr-carrname.

  IF sy-subrc NE 0.
    MESSAGE e006(z_mensajes_01). " 'No existen vuelos para la aerolinea'
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&  FORM PRINCIPAL
*&  Coordina el flujo de ejecucion del reporte:
*&    1. Obtiene datos del JOIN
*&    2. Calcula semaforo de ocupacion
*&    3. Llama al Dynpro 0100 que contiene el ALV
*&---------------------------------------------------------------------*
FORM principal.
  PERFORM obtener_datos.
  PERFORM anadir_datos_a_consulta.
  CALL SCREEN 0100.
ENDFORM.

*&---------------------------------------------------------------------*
*&  FORM OBTENER_DATOS
*&  SELECT con INNER JOIN entre SCARR (aerolineas) y SFLIGHT (vuelos).
*&  Recupera: codigo/nombre de aerolinea, numero de vuelo, fecha,
*&  capacidad maxima y asientos ocupados.
*&---------------------------------------------------------------------*
FORM obtener_datos.

  SELECT scarr~carrid
         scarr~carrname
         sflight~connid
         sflight~fldate
         sflight~seatsmax
         sflight~seatsocc
    INTO CORRESPONDING FIELDS OF TABLE gt_sflight
    FROM scarr
    INNER JOIN sflight ON sflight~carrid = scarr~carrid
    WHERE scarr~carrid = p_carrid.

  IF sy-subrc NE 0.
    MESSAGE e006(z_mensajes_01). " 'No existen vuelos para la aerolinea'
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&  FORM ANADIR_DATOS_A_CONSULTA
*&  Recorre la tabla de vuelos y, para cada fila:
*&    - Calcula el porcentaje de ocupacion = (seatsocc * 100) / seatsmax
*&    - Asigna el icono semaforo segun umbrales:
*&        >= 80 % -> Rojo    (@0A@) -> accion urgente
*&        >= 50 % -> Amarillo(@09@) -> atencion
*&        <  50 % -> Verde   (@08@) -> correcto
*&  Este patron de semaforo es el precursor conceptual del campo
*&  'criticality' que usa RAP/Fiori Elements en S/4HANA moderno.
*&---------------------------------------------------------------------*
FORM anadir_datos_a_consulta.
  DATA: lv_porcentaje TYPE s_sum.

  FIELD-SYMBOLS: <fs_sflight> LIKE st_sflight.

  LOOP AT gt_sflight ASSIGNING <fs_sflight>.
    " Calculo del porcentaje; seatsmax nunca es 0 en datos SFLIGHT de demo
    lv_porcentaje = ( ( <fs_sflight>-seatsocc * 100 ) / <fs_sflight>-seatsmax ).

    " Asignacion de icono semaforo segun nivel de ocupacion
    IF lv_porcentaje GE 80.
      <fs_sflight>-icon = '@0A@'.  " Rojo: vuelo casi lleno (>= 80 %)
    ELSEIF lv_porcentaje GE 50 AND lv_porcentaje LT 80.
      <fs_sflight>-icon = '@09@'.  " Amarillo: ocupacion media (50-79 %)
    ELSEIF lv_porcentaje LT 50.
      <fs_sflight>-icon = '@08@'.  " Verde: poca ocupacion (< 50 %)
    ENDIF.

    " Guardamos el porcentaje entero formateado para mostrarlo en el ALV
    <fs_sflight>-porporcentaje = lv_porcentaje.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*&  FORM USER_COMMAND_0100
*&  Gestiona los codigos de funcion del Dynpro 0100.
*&  BACK/EXIT/CANCEL -> salir al menu anterior (pantalla 0).
*&---------------------------------------------------------------------*
FORM user_command_0100 USING i_ucomm TYPE sy-ucomm.
  CASE i_ucomm.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      LEAVE TO SCREEN 0.
    WHEN OTHERS.
      " El ALV gestiona sus propios comandos internos
  ENDCASE.
ENDFORM.

*&---------------------------------------------------------------------*
*&  FORM CARGA_DATOS_ALV
*&  Inicializa el contenedor y el grid ALV en el Dynpro 0100.
*&  Se llama desde el modulo CARGAR_DATOS (MOD, evento OUTPUT).
*&  La creacion de objetos se protege con IS INITIAL para evitar
*&  recrearlos en cada ciclo PBO (patron singleton de Dynpro).
*&---------------------------------------------------------------------*
FORM carga_datos_alv.

  " Solo crear los objetos la primera vez que se pinta el Dynpro
  IF g_container IS INITIAL.
    " Contenedor vinculado al Custom Control 'G_CONTAINER' del Dynpro 0100
    CREATE OBJECT g_container
      EXPORTING
        container_name = 'G_CONTAINER'.

    " ALV grid que vive dentro del contenedor
    CREATE OBJECT gcl_gui_alv_grid
      EXPORTING
        i_parent = g_container.
  ENDIF.

  " Opciones visuales del ALV
  gs_layout-sel_mode  = 'A'.  " Columna de seleccion visible (checkbox)
  gs_layout-zebra     = 'X'.  " Filas alternadas con color (mas legible)
  gs_layout-cwidth_opt = 'X'. " Ajuste automatico del ancho de columnas
  gs_layout-no_hgridln = 'X'. " Sin lineas horizontales (aspecto limpio)

  " Construir el catalogo de columnas antes de mostrar el ALV
  PERFORM construir_catalogo_alv.

  " Registrar el manejador de eventos (patron Observer del ALV OO)
  CREATE OBJECT glcl_event.
  SET HANDLER: glcl_event->handle_user_command FOR gcl_gui_alv_grid,
               glcl_event->handle_toolbar      FOR gcl_gui_alv_grid,
               glcl_event->on_doble_click      FOR gcl_gui_alv_grid.

  " Mostrar la tabla con el catalogo y el layout configurados
  CALL METHOD gcl_gui_alv_grid->set_table_for_first_display
    EXPORTING
      is_layout            = gs_layout
      it_toolbar_excluding = gt_toolbar_excluding  " Botones ocultos (ninguno en este caso)
    CHANGING
      it_outtab            = gt_sflight
      it_fieldcatalog      = gt_fieldcat.

  IF sy-subrc <> 0.
    MESSAGE e398(00) WITH 'Error al mostrar el ALV'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&  FORM CONSTRUIR_CATALOGO_ALV
*&  Define cada columna que aparecera en el ALV (fieldcatalog).
*&  Columnas: ICON | PORPORCENTAJE | CONNID | FLDATE | SEATSMAX | SEATSOCC
*&  Nota: CARRID se omite porque ya aparece implicitamente en el filtro
*&        de seleccion (una sola aerolinea por ejecucion).
*&---------------------------------------------------------------------*
FORM construir_catalogo_alv.

  " --- Columna 1: Icono semaforo ---
  " ICON_D es el tipo DDIC del dominio de iconos SAP
  gs_fieldcat-fieldname = 'ICON'.
  gs_fieldcat-seltext   = 'Ocupacion'.
  gs_fieldcat-scrtext_m = 'Ocupacion'.
  gs_fieldcat-col_pos   = 1.
  gs_fieldcat-outputlen = 10.
  gs_fieldcat-datatype  = 'ICON_D'.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR  gs_fieldcat.

  " --- Columna 2: Porcentaje de ocupacion (formato entero/suma) ---
  " Usamos PORPORCENTAJE (S_SUM) en lugar de PORCENTAJE (FLTP)
  " porque S_SUM formatea correctamente como numero entero en el ALV
  gs_fieldcat-fieldname = 'PORPORCENTAJE'.
  gs_fieldcat-seltext   = 'Porcentaje de ocupacion'.
  gs_fieldcat-scrtext_m = '% Ocupacion'.
  gs_fieldcat-col_pos   = 2.
  gs_fieldcat-outputlen = 10.
  gs_fieldcat-datatype  = 'S_SUM'.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR  gs_fieldcat.

  " --- Columna 3: Numero de vuelo ---
  gs_fieldcat-fieldname = 'CONNID'.
  gs_fieldcat-seltext   = 'ID de vuelo'.
  gs_fieldcat-scrtext_m = 'ID vuelo'.
  gs_fieldcat-col_pos   = 3.
  gs_fieldcat-outputlen = 4.
  gs_fieldcat-datatype  = 'S_CONN_ID'.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR  gs_fieldcat.

  " --- Columna 4: Fecha de vuelo ---
  " DATS es el tipo DDIC correcto para fechas (8 caracteres YYYYMMDD)
  gs_fieldcat-fieldname = 'FLDATE'.
  gs_fieldcat-seltext   = 'Fecha de vuelo'.
  gs_fieldcat-scrtext_m = 'Fecha vuelo'.
  gs_fieldcat-col_pos   = 4.
  gs_fieldcat-outputlen = 8.
  gs_fieldcat-datatype  = 'DATS'.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR  gs_fieldcat.

  " --- Columna 5: Capacidad maxima del avion ---
  gs_fieldcat-fieldname = 'SEATSMAX'.
  gs_fieldcat-seltext   = 'Capacidad maxima'.
  gs_fieldcat-scrtext_m = 'Cap. maxima'.
  gs_fieldcat-col_pos   = 5.
  gs_fieldcat-outputlen = 10.
  gs_fieldcat-datatype  = 'S_SEATSMAX'.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR  gs_fieldcat.

  " --- Columna 6: Asientos ocupados ---
  gs_fieldcat-fieldname = 'SEATSOCC'.
  gs_fieldcat-seltext   = 'Asientos ocupados'.
  gs_fieldcat-scrtext_m = 'Ocupados'.
  gs_fieldcat-col_pos   = 6.
  gs_fieldcat-outputlen = 10.
  gs_fieldcat-datatype  = 'S_SEATSOCC'.
  APPEND gs_fieldcat TO gt_fieldcat.
  CLEAR  gs_fieldcat.

ENDFORM.

*&---------------------------------------------------------------------*
*&  FORM MOSTRAR_POPUP_INFORMACION
*&  Popup de detalle del vuelo para la fila seleccionada en el ALV.
*&  Se invoca desde HANDLE_USER_COMMAND (boton INFO de la toolbar).
*&  Valida que haya exactamente una fila seleccionada antes de actuar.
*&---------------------------------------------------------------------*
FORM mostrar_popup_informacion.
  DATA: lt_index_rows TYPE lvc_t_row,   " Filas marcadas en el ALV
        lt_row_no     TYPE lvc_t_roid,  " Numeros de fila seleccionadas
        lv_lines      TYPE i,           " Cantidad de filas seleccionadas
        lv_info       TYPE string.      " Texto a mostrar en el popup

  " Obtener las filas marcadas con el checkbox del ALV
  CALL METHOD gcl_gui_alv_grid->get_selected_rows
    IMPORTING
      et_index_rows = lt_index_rows.

  DESCRIBE TABLE lt_index_rows LINES lv_lines.

  " Solo mostramos el popup si hay exactamente UNA fila seleccionada
  IF lv_lines IS INITIAL OR lv_lines GT 1.
    MESSAGE s398(00) WITH 'Solo puede seleccionar una linea'.
    RETURN.
  ENDIF.

  " Leer el indice de la fila marcada y recuperar la linea de gt_sflight
  READ TABLE lt_index_rows INTO DATA(ls_index_rows) INDEX 1.
  READ TABLE gt_sflight    INTO DATA(ls_sflight)    INDEX ls_index_rows-index.

  " Construir el texto del popup con datos clave del vuelo
  CONCATENATE ls_sflight-carrid
              ls_sflight-carrname
              ls_sflight-fldate
    INTO lv_info SEPARATED BY space.

  CALL FUNCTION 'POPUP_TO_INFORM'
    EXPORTING
      titel = 'Informacion del vuelo'
      txt1  = lv_info
      txt2  = ' '.

ENDFORM.
