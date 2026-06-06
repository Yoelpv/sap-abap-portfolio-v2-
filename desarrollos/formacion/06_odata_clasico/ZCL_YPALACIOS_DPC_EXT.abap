*&---------------------------------------------------------------------*
*& Clase   : ZCL_YPALACIOS_DPC_EXT
*& Tipo    : Data Provider Extension (OData Clásico SAP Gateway)
*& Módulo  : CO — Controlling (tabla CSKS - Centros de Coste)
*& Entorno : ECC / S/4HANA On-Premise (SAP Gateway / SEGW)
*&
*& Descripción:
*&   Servicio OData clásico para consultar y crear Centros de Coste.
*&   Expone la tabla CSKS a través de una EntitySet llamado 'CentroCostSet'.
*&   Permite operaciones: GET_ENTITY (leer un CC) y CREATE_ENTITY (crear).
*&
*& ORIGEN DIRECTO: Este es mi propio código de la formación.
*& Archivo original: ZCL_Z_YPALACIOS_TRAINI_DPC_EXT (Dpc_ext_CLASS_ODATA.docx)
*&
*& Qué se mejoró respecto al código original:
*&   1. GET_ENTITY: el original dejaba el IF sy-subrc empty sin hacer nada.
*&      Esta versión lanza excepción de negocio si no se encuentra el CC.
*&   2. CREATE_ENTITY: el original no tenía COMMIT WORK — los datos no se
*&      persistían si el LUW se cerraba antes. Añadido COMMIT WORK AND WAIT.
*&   3. Manejo de claves: CONVERSION_EXIT_ALPHA_INPUT centralizado en un
*&      método privado para no repetirlo en cada CASE del LOOP.
*&   4. Mensajes de retorno informativos en ER_ENTITY para que el frontend
*&      sepa si el alta fue correcta sin tener que hacer un GET posterior.
*&   5. Validación de duplicados antes de INSERT (el original no validaba).
*&
*& Cómo crear este servicio en SAP (SEGW):
*&   1. SEGW → Nuevo proyecto → ZGW_CENTROCOSTE_YP
*&   2. Crear EntityType: CentroCost con propiedades de CSKS (kokrs, kostl, datbi, verak)
*&   3. Crear EntitySet: CentroCostSet
*&   4. Generar → se crean MPC y DPC automáticamente
*&   5. Esta clase hereda de la DPC generada y redefine los métodos
*&   6. Activar en /IWFND/MAINT_SERVICE
*&---------------------------------------------------------------------*
CLASS zcl_ypalacios_dpc_ext DEFINITION
  PUBLIC
  INHERITING FROM zcl_ypalacios_dpc   " DPC generada por SEGW
  CREATE PUBLIC.

  PUBLIC SECTION.

  PROTECTED SECTION.
    " Redefinición de los métodos del EntitySet CentroCostSet
    METHODS centrocostset_get_entity   REDEFINITION.
    METHODS centrocostset_create_entity REDEFINITION.

  PRIVATE SECTION.
    " Método auxiliar: aplica CONVERSION_EXIT_ALPHA_INPUT a un valor
    " para normalizar claves SAP (p.ej. '100' → '0000000100')
    METHODS normalize_key
      IMPORTING iv_raw         TYPE string
      RETURNING VALUE(rv_norm) TYPE string.

ENDCLASS.


CLASS zcl_ypalacios_dpc_ext IMPLEMENTATION.

  "----------------------------------------------------------------------
  " MÉTODO: CENTROCOSTSET_GET_ENTITY
  " Lee un Centro de Coste de la tabla CSKS por su clave primaria.
  " La clave viene en IT_KEY_TAB como pares nombre=valor.
  "
  " Mejora: el original dejaba el IF/ELSE vacío. Esta versión lanza
  " /IWBEP/CX_MGW_BUSI_EXCEPTION cuando no se encuentra el registro,
  " lo que hace que el frontend reciba un HTTP 404 correcto.
  "----------------------------------------------------------------------
  METHOD centrocostset_get_entity.

    DATA: lv_kokrs TYPE csks-kokrs,
          lv_kostl TYPE csks-kostl,
          lv_datbi TYPE csks-datbi.

    " Extraer claves del request (vienen como lista nombre=valor)
    LOOP AT it_key_tab ASSIGNING FIELD-SYMBOL(<fs_key>).
      CASE <fs_key>-name.
        WHEN 'Kokrs'.
          lv_kokrs = me->normalize_key( <fs_key>-value ).
        WHEN 'Kostl'.
          lv_kostl = me->normalize_key( <fs_key>-value ).
        WHEN 'Datbi'.
          " Fecha: convertir de formato OData (YYYYMMDD) a tipo D de ABAP
          lv_datbi = <fs_key>-value(8).
      ENDCASE.
    ENDLOOP.

    " Leer el Centro de Coste de la tabla estándar CSKS
    SELECT SINGLE FROM csks
      FIELDS kokrs,
             kostl,
             CAST( datbi AS CHAR( 8 ) ) AS datbi,    " Exportar fecha como string
             verak,
             datab                                    " Fecha de inicio de validez
      WHERE kokrs = @lv_kokrs
        AND kostl = @lv_kostl
        AND datbi = @lv_datbi
      INTO @er_entity.

    IF sy-subrc <> 0.
      " Lanzar excepción de negocio para que el framework devuelva HTTP 404
      " El frontend (Fiori/SAPUI5) puede mostrar el mensaje al usuario
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid  = /iwbep/cx_mgw_busi_exception=>business_error
          message = |Centro de Coste { lv_kostl } no encontrado para área { lv_kokrs }.|.
    ENDIF.

  ENDMETHOD.


  "----------------------------------------------------------------------
  " MÉTODO: CENTROCOSTSET_CREATE_ENTITY
  " Crea un nuevo Centro de Coste en la tabla Z de prueba (ZCSKS_TEST).
  " Nota: en un proyecto real se usaría una BAPI o un Business Object,
  " no un INSERT directo en CSKS (tabla estándar protegida por SAP).
  "
  " Mejoras respecto al original:
  "   - Validación de duplicados antes del INSERT
  "   - COMMIT WORK AND WAIT para persistir el LUW correctamente
  "   - Mensajes de retorno en ER_ENTITY (el original los dejaba vacíos)
  "----------------------------------------------------------------------
  METHOD centrocostset_create_entity.

    " Leer el payload enviado por el frontend (body del POST)
    DATA ls_input TYPE zcl_ypalacios_mpc=>ts_centrocost.
    io_data_provider->read_entry_data( IMPORTING es_data = ls_input ).

    " Validar que los campos obligatorios estén informados
    IF ls_input-kokrs IS INITIAL OR ls_input-kostl IS INITIAL.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid  = /iwbep/cx_mgw_busi_exception=>business_error
          message = 'Los campos Área de Controlling (KOKRS) y Centro de Coste (KOSTL) son obligatorios.'.
    ENDIF.

    " Validar que el registro no exista ya (evitar duplicados)
    SELECT SINGLE 1 FROM zcsks_test
      WHERE kokrs = @ls_input-kokrs
        AND kostl = @ls_input-kostl
        AND datbi = @ls_input-datbi
      INTO @DATA(lv_exists).

    IF sy-subrc = 0.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid  = /iwbep/cx_mgw_busi_exception=>business_error
          message = |El Centro de Coste { ls_input-kostl } ya existe para el área { ls_input-kokrs }.|.
    ENDIF.

    " Insertar en la tabla Z de prueba
    INSERT zcsks_test FROM ls_input.

    IF sy-subrc = 0.
      " COMMIT WORK AND WAIT: sin esto los datos NO se guardan en BD
      " El AND WAIT asegura que el commit se completa antes de continuar
      COMMIT WORK AND WAIT.

      " Devolver el registro creado y un mensaje de éxito
      er_entity-kokrs    = ls_input-kokrs.
      er_entity-kostl    = ls_input-kostl.
      er_entity-datbi    = ls_input-datbi.
      er_entity-verak    = ls_input-verak.
      er_entity-mensaje  = 'Centro de Coste creado correctamente.'.
      er_entity-cod_retor = '0'.

    ELSE.
      " El INSERT falló — deshacer cualquier cambio parcial
      ROLLBACK WORK.

      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid  = /iwbep/cx_mgw_busi_exception=>business_error
          message = 'Error al crear el Centro de Coste. Contacte con el administrador.'.
    ENDIF.

  ENDMETHOD.


  "----------------------------------------------------------------------
  " MÉTODO PRIVADO: NORMALIZE_KEY
  " Aplica CONVERSION_EXIT_ALPHA_INPUT para normalizar valores de clave.
  " Centralizar aquí evita repetir el CALL FUNCTION en cada CASE.
  "----------------------------------------------------------------------
  METHOD normalize_key.

    rv_norm = iv_raw.

    IF iv_raw IS NOT INITIAL.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING input  = iv_raw
        IMPORTING output = rv_norm.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
