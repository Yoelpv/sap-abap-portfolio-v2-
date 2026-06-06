*&---------------------------------------------------------------------*
*& Clase   : ZCL_MATERIAL_MANAGER
*& Módulo  : MM — Materials Management
*& Entorno : ECC / S/4HANA On-Premise
*&
*& Descripción:
*&   Clase ABAP orientada a objetos para gestionar materiales.
*&   Demuestra: encapsulación, herencia, polimorfismo y patrón Factory.
*&
*& PLUS del portafolio — nuevo ejercicio basado en lo visto en TAW11 OOP:
*&   La formación cubría clases, herencia e interfaces.
*&   Este ejercicio aplica esos conceptos a un caso de negocio real (MM).
*&
*& Jerarquía de clases:
*&   ZCL_MATERIAL_MANAGER (base abstracta)
*&     ├── ZCL_MATERIAL_READER  — solo lectura (consultas)
*&     └── ZCL_MATERIAL_WRITER  — escritura en tabla Z (alta/modificación)
*&
*& Patrón Factory:
*&   ZCL_MATERIAL_MANAGER=>GET_INSTANCE( iv_mode = 'R' ) → ZCL_MATERIAL_READER
*&   ZCL_MATERIAL_MANAGER=>GET_INSTANCE( iv_mode = 'W' ) → ZCL_MATERIAL_WRITER
*&---------------------------------------------------------------------*


"================================================================
" CLASE BASE ABSTRACTA: ZCL_MATERIAL_MANAGER
" Define el contrato común para lectores y escritores.
" ABSTRACT: no se puede instanciar directamente — solo subclases.
"================================================================
CLASS zcl_material_manager DEFINITION
  PUBLIC ABSTRACT
  CREATE PROTECTED.           " Solo las subclases pueden llamar al CONSTRUCTOR

  PUBLIC SECTION.

    " Tipo de tabla compartido por todas las subclases
    TYPES: BEGIN OF ty_material,
             matnr TYPE mara-matnr,
             mtart TYPE mara-mtart,
             werks TYPE marc-werks,
             maktx TYPE makt-maktx,
           END OF ty_material,
           tt_material TYPE TABLE OF ty_material WITH DEFAULT KEY.

    " ---------------------------------------------------------------
    " MÉTODO FACTORY: punto de entrada único para obtener instancias.
    " Quien llama no necesita saber qué subclase se usa — solo el modo.
    " IV_MODE: 'R' = Reader (solo lectura), 'W' = Writer (escritura)
    " ---------------------------------------------------------------
    CLASS-METHODS get_instance
      IMPORTING iv_mode            TYPE char1 DEFAULT 'R'
      RETURNING VALUE(ro_instance) TYPE REF TO zcl_material_manager
      RAISING   cx_sy_create_object_error.

    " Método abstracto: cada subclase DEBE implementarlo
    METHODS process
      IMPORTING iv_mtart             TYPE mara-mtart OPTIONAL
                iv_werks             TYPE marc-werks OPTIONAL
      EXPORTING et_materials         TYPE tt_material
                et_messages          TYPE bapiret2_t
      RAISING   cx_sy_open_sql_error.

    " Método concreto heredado: muestra los resultados en ALV (idéntico en todas las subclases)
    METHODS show_alv
      IMPORTING it_materials TYPE tt_material.

  PROTECTED SECTION.
    " Solo accesible desde la clase y sus hijos
    DATA mv_mode TYPE char1.

ENDCLASS.


CLASS zcl_material_manager IMPLEMENTATION.

  METHOD get_instance.
    " El Factory decide qué subclase crear según el modo solicitado
    CASE iv_mode.
      WHEN 'R'.
        " Modo Reader: instanciar la clase de solo lectura
        CREATE OBJECT ro_instance TYPE zcl_material_reader.
      WHEN 'W'.
        " Modo Writer: instanciar la clase de escritura
        CREATE OBJECT ro_instance TYPE zcl_material_writer.
      WHEN OTHERS.
        " Modo desconocido: lanzar excepción
        RAISE EXCEPTION TYPE cx_sy_create_object_error.
    ENDCASE.
  ENDMETHOD.

  METHOD show_alv.
    " Este método es idéntico para Reader y Writer — se hereda sin cambios
    DATA lt_show TYPE tt_material.
    lt_show = it_materials.

    IF lt_show IS INITIAL.
      MESSAGE 'No hay datos que mostrar.' TYPE 'S' DISPLAY LIKE 'W'.
      RETURN.
    ENDIF.

    TRY.
      DATA lo_alv TYPE REF TO cl_salv_table.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = lo_alv
        CHANGING  t_table      = lt_show
      ).
      lo_alv->get_functions( )->set_all( abap_true ).
      lo_alv->get_display_settings( )->set_fit_column_width( abap_true ).
      lo_alv->display( ).
    CATCH cx_salv_msg INTO DATA(lx_err).
      MESSAGE lx_err->get_text( ) TYPE 'E'.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


"================================================================
" SUBCLASE: ZCL_MATERIAL_READER — solo lectura
" Hereda de ZCL_MATERIAL_MANAGER e implementa PROCESS para consultar.
"================================================================
CLASS zcl_material_reader DEFINITION
  PUBLIC FINAL
  INHERITING FROM zcl_material_manager
  CREATE PUBLIC.

  PUBLIC SECTION.
    " Redefinición del método abstracto PROCESS
    METHODS process REDEFINITION.

ENDCLASS.


CLASS zcl_material_reader IMPLEMENTATION.

  METHOD process.
    " Limpiar exportaciones
    CLEAR: et_materials, et_messages.

    DATA ls_msg TYPE bapiret2.

    " Lectura de materiales con JOIN
    SELECT mara~matnr,
           mara~mtart,
           marc~werks,
           makt~maktx
      FROM mara
      INNER JOIN marc ON marc~matnr = mara~matnr
      INNER JOIN makt ON makt~matnr = mara~matnr
                     AND makt~spras = @sy-langu
      INTO TABLE @et_materials
      WHERE ( mara~mtart = @iv_mtart OR @iv_mtart IS INITIAL )
        AND ( marc~werks = @iv_werks OR @iv_werks IS INITIAL )
        AND mara~lvorm = ''.

    IF sy-subrc <> 0.
      ls_msg-type    = 'W'.
      ls_msg-message = 'No se encontraron materiales.'.
      APPEND ls_msg TO et_messages.
    ELSE.
      ls_msg-type    = 'S'.
      ls_msg-message = |{ lines( et_materials ) } materiales leídos.|.
      APPEND ls_msg TO et_messages.
    ENDIF.
  ENDMETHOD.

ENDCLASS.


"================================================================
" SUBCLASE: ZCL_MATERIAL_WRITER — escritura en tabla Z
" Hereda de ZCL_MATERIAL_MANAGER e implementa PROCESS para guardar.
"================================================================
CLASS zcl_material_writer DEFINITION
  PUBLIC FINAL
  INHERITING FROM zcl_material_manager
  CREATE PUBLIC.

  PUBLIC SECTION.
    " Redefinición del método abstracto PROCESS
    METHODS process REDEFINITION.

    " Método adicional solo disponible en el Writer (no en el Reader)
    METHODS delete_all
      EXPORTING ev_lines TYPE i.

ENDCLASS.


CLASS zcl_material_writer IMPLEMENTATION.

  METHOD process.
    " Este PROCESS primero lee los datos usando el Reader (reutilización)
    CLEAR: et_materials, et_messages.

    DATA ls_msg TYPE bapiret2.

    " Instanciar el Reader para la lectura de datos
    " Esto demuestra composición: el Writer usa al Reader internamente
    DATA lo_reader TYPE REF TO zcl_material_reader.
    CREATE OBJECT lo_reader.

    lo_reader->process(
      IMPORTING
        et_materials = et_materials
        et_messages  = et_messages
      EXPORTING
        iv_mtart = iv_mtart
        iv_werks = iv_werks
    ).

    " Si la lectura fue bien, guardar en tabla Z
    IF et_materials IS NOT INITIAL.
      MODIFY zmateriales_yp FROM TABLE et_materials.

      IF sy-subrc = 0.
        ls_msg-type    = 'S'.
        ls_msg-message = |{ lines( et_materials ) } materiales guardados en ZMATERIALES_YP.|.
      ELSE.
        ls_msg-type    = 'E'.
        ls_msg-message = 'Error al guardar los datos en la tabla Z.'.
      ENDIF.
      APPEND ls_msg TO et_messages.
    ENDIF.
  ENDMETHOD.

  METHOD delete_all.
    DELETE FROM zmateriales_yp.
    ev_lines = sy-dbcnt.          " SAP almacena el nº de filas afectadas en SY-DBCNT
  ENDMETHOD.

ENDCLASS.


"================================================================
" PROGRAMA DE PRUEBA — muestra cómo usar las clases
"================================================================
REPORT zr_test_material_manager.

START-OF-SELECTION.

  DATA: lo_manager   TYPE REF TO zcl_material_manager,
        lt_materials TYPE zcl_material_manager=>tt_material,
        lt_messages  TYPE bapiret2_t.

  " Usar el Factory para obtener un Reader sin conocer la implementación
  TRY.
    lo_manager = zcl_material_manager=>get_instance( iv_mode = 'R' ).
  CATCH cx_sy_create_object_error.
    MESSAGE 'Error al crear instancia.' TYPE 'E'.
    RETURN.
  ENDTRY.

  " Llamar al método polimórfico PROCESS — funciona igual para Reader y Writer
  TRY.
    lo_manager->process(
      EXPORTING
        iv_mtart     = 'FERT'
      IMPORTING
        et_materials = lt_materials
        et_messages  = lt_messages
    ).
  CATCH cx_sy_open_sql_error INTO DATA(lx_sql).
    MESSAGE lx_sql->get_text( ) TYPE 'E'.
    RETURN.
  ENDTRY.

  " Mostrar en ALV usando el método heredado de la clase base
  lo_manager->show_alv( lt_materials ).
