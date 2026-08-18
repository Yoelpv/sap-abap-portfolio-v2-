*&---------------------------------------------------------------------*
*&  Include  ZALV_SFLIGHT_OCUPACION_TOP
*&  Declaraciones globales: tablas DDIC, estructura de salida,
*&  variables ALV y clase local de eventos LCL_EVENT.
*&---------------------------------------------------------------------*

* Tablas DDIC necesarias para MESSAGE y screen-painter
TABLES: scarr,     " Tabla maestra de aerolineas
        sflight,   " Tabla de vuelos por aerolinea
        icon.      " Tabla de iconos SAP (clave: ICON_D)

*----------------------------------------------------------------------*
* Estructura de salida propia:
*   Amplia SFLIGHT con dos campos extra:
*     ICON        -> icono semaforo que se pinta en ALV
*     PORCENTAJE  -> valor decimal del % de ocupacion (FLTP_VALUE)
*     PORPORCENTAJE -> valor entero/suma del % (S_SUM, se muestra en ALV)
*----------------------------------------------------------------------*
DATA: BEGIN OF st_sflight,
        icon          TYPE icon_d,       " Codigo de icono SAP  (p.ej. @0A@)
        porcentaje    TYPE fltp_value,   " % ocupacion en coma flotante
        porporcentaje TYPE s_sum,        " % ocupacion formateado para ALV
        carrid        TYPE s_carr_id,    " Codigo de aerolinea  (p.ej. LH)
        carrname      TYPE s_carrname,   " Nombre de aerolinea  (p.ej. Lufthansa)
        connid        TYPE s_conn_id,    " Numero de vuelo
        fldate        TYPE s_date,       " Fecha de vuelo
        seatsmax      TYPE s_seatsmax,   " Capacidad maxima del avion
        seatsocc      TYPE s_seatsocc,   " Asientos ocupados
      END OF st_sflight.

* Tabla interna y area de trabajo de la estructura de salida
DATA: gt_sflight         LIKE TABLE OF st_sflight,  " Tabla de resultados
      gs_sflight         LIKE st_sflight,            " Area de trabajo
      gv_nombreaerolinea TYPE string.                " Nombre completo para el titulo

*----------------------------------------------------------------------*
* Referencias a objetos ALV OO:
*   CL_GUI_ALV_GRID        -> grid principal
*   CL_GUI_CUSTOM_CONTAINER -> contenedor Dynpro donde vive el grid
*----------------------------------------------------------------------*
DATA: gcl_gui_alv_grid     TYPE REF TO cl_gui_alv_grid,          " Objeto ALV principal
      g_container          TYPE REF TO cl_gui_custom_container,  " Contenedor del Dynpro 0100
      gs_layout            TYPE lvc_s_layo,                      " Opciones visuales del ALV
      gt_fieldcat          TYPE lvc_t_fcat,                      " Catalogo de columnas
      gs_fieldcat          TYPE lvc_s_fcat,                      " Estructura de una columna
      gt_toolbar_excluding TYPE ui_functions,                     " Botones a ocultar
      gv_exclude           TYPE ui_func.                         " Codigo de boton a excluir

*----------------------------------------------------------------------*
* Clase local LCL_EVENT:
*   Maneja los eventos del ALV grid mediante el patron Observer.
*   Se registra con SET HANDLER en CARGA_DATOS_ALV (include _F01).
*
*   Eventos manejados:
*     ON_DOBLE_CLICK     -> muestra popup con fila/columna clicadas
*     HANDLE_TOOLBAR     -> agrega boton "Mostrar Info" a la barra
*     HANDLE_USER_COMMAND-> ejecuta MOSTRAR_POPUP_INFORMACION al pulsar INFO
*----------------------------------------------------------------------*
CLASS lcl_event DEFINITION.
  PUBLIC SECTION.
    " Evento: usuario hace doble clic en una celda del ALV
    METHODS: on_doble_click
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING es_row_no e_column.

    " Evento: ALV construye la barra de herramientas (PBO del grid)
    METHODS: handle_toolbar
      FOR EVENT toolbar OF cl_gui_alv_grid
      IMPORTING e_object e_interactive.

    " Evento: usuario pulsa un boton de la barra (BACK, INFO, etc.)
    METHODS: handle_user_command
      FOR EVENT user_command OF cl_gui_alv_grid
      IMPORTING e_ucomm.
ENDCLASS.

CLASS lcl_event IMPLEMENTATION.

  METHOD on_doble_click.
    " Muestra en un popup la fila y columna seleccionadas por el usuario
    DATA: lv_txt  TYPE string,
          lv_char TYPE char5.

    lv_char = CONV #( es_row_no-row_id ).
    CONCATENATE 'Linea seleccionada:' lv_char ' Columna:' e_column
      INTO lv_txt SEPARATED BY space.

    CALL FUNCTION 'POPUP_TO_INFORM'
      EXPORTING
        titel = 'Detalle de celda'
        txt1  = lv_txt
        txt2  = ' '.
  ENDMETHOD.

  METHOD handle_toolbar.
    " Agrega un boton personalizado 'INFO' a la barra de herramientas del ALV.
    " El icono @0P@ es el de informacion en SAP.
    DATA: ls_toolbar TYPE stb_button.
    CLEAR ls_toolbar.

    ls_toolbar-function  = 'INFO'.           " Codigo capturado en USER_COMMAND
    ls_toolbar-icon      = '@0P@'.           " Icono de informacion SAP
    ls_toolbar-quickinfo = 'Mostrar Info'.   " Tooltip al pasar el raton
    ls_toolbar-text      = 'Mostrar info'.   " Texto visible en boton
    APPEND ls_toolbar TO e_object->mt_toolbar.
  ENDMETHOD.

  METHOD handle_user_command.
    " Dispatcher de comandos de la barra de herramientas.
    " Cuando el usuario pulsa INFO se muestra el popup de detalle del vuelo.
    CASE e_ucomm.
      WHEN 'INFO'.
        PERFORM mostrar_popup_informacion.
      WHEN OTHERS.
        " Otros comandos no manejados: SAP los procesa por defecto
    ENDCASE.
  ENDMETHOD.

ENDCLASS.

" Instancia global del manejador de eventos (se crea en CARGA_DATOS_ALV)
DATA: glcl_event TYPE REF TO lcl_event.
