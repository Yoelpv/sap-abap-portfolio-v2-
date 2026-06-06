*&---------------------------------------------------------------------*
*& Clase    : ZCL_BADI_MATERIAL_SAVE_IMPL
*& Módulo   : MM — Materials Management
*& Entorno  : S/4HANA On-Premise / ECC  (NO aplica en BTP Cloud ABAP)
*&
*& Descripción:
*&   Implementación de un BAdI del Enhancement Framework para validar
*&   datos de un material en el momento de guardarlo (MM01/MM02).
*&
*&   Caso de uso real: el negocio exige que todo material de tipo FERT
*&   (producto terminado) tenga informado el grupo de artículos (MATKL)
*&   antes de poder guardarlo. Sin esta validación, los usuarios crean
*&   materiales incompletos que luego fallan en planificación (PP/MRP).
*&
*& Qué demuestra este ejercicio:
*&   - Cómo encontrar un BAdI en la transacción SE18
*&   - Cómo crear una implementación en SE19 (ECC) o Eclipse (S/4)
*&   - Estructura de la clase de implementación (interfaz IF_EX_*)
*&   - RAISING de excepción para mostrar un mensaje de error al usuario
*&   - Diferencia entre BAdI clásico (SE18/SE19) y Enhancement Spot
*&
*& Cómo activarlo en el sistema:
*&   1. SE18 → buscar el BAdI: BADI_MATERIAL_SAVE (o el equivalente en tu sistema)
*&   2. SE19 → New Implementation → nombre: ZBADI_MATERIAL_SAVE_IMPL
*&   3. Asignar esta clase (ZCL_BADI_MATERIAL_SAVE_IMPL) como clase de implementación
*&   4. Activar la implementación
*&   5. Probar en MM01: crear un material FERT sin grupo de artículos → debe aparecer el error
*&---------------------------------------------------------------------*


"================================================================
" CLASE DE IMPLEMENTACIÓN DEL BAdI
"
" Reglas obligatorias de la clase:
"   - PUBLIC FINAL: SAP requiere que las implementaciones de BAdI
"     sean finales (no se pueden heredar)
"   - FOR TESTING no aplica aquí — los BAdI se prueban en el propio MM01
"================================================================
CLASS zcl_badi_material_save_impl DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    " Implementa la interfaz del BAdI — SAP la genera automáticamente
    " al crear el BAdI en SE18. El nombre siempre es IF_EX_<nombre_del_badi>
    INTERFACES if_ex_badi_material_save.

ENDCLASS.


CLASS zcl_badi_material_save_impl IMPLEMENTATION.

  "--------------------------------------------------------------
  " MÉTODO: CHECK_BEFORE_SAVE
  " SAP llama a este método justo antes de guardar el material.
  " Si lanzamos cx_badi_msg, SAP muestra el mensaje al usuario
  " y cancela el guardado — el material NO se crea/modifica.
  "
  " Parámetros de entrada (definidos en la interfaz del BAdI):
  "   iv_matnr  — número de material que se está guardando
  "   iv_mara   — estructura con los datos generales del material (tabla MARA)
  "--------------------------------------------------------------
  METHOD if_ex_badi_material_save~check_before_save.

    " Solo validamos materiales de tipo FERT (productos terminados)
    " Los demás tipos no requieren grupo de artículos según el negocio
    CHECK iv_mara-mtart = 'FERT'.

    " Regla de negocio: FERT sin grupo de artículos (MATKL) no se puede guardar
    IF iv_mara-matkl IS INITIAL.
      RAISE EXCEPTION TYPE cx_badi_msg
        EXPORTING
          " El usuario verá este mensaje en pantalla y no podrá guardar
          textid = cx_badi_msg=>textid
          msgty  = 'E'                          " E = Error (bloquea el guardado)
          msgid  = 'ZMM_MESSAGES'               " Clase de mensajes propia (crear en SE91)
          msgno  = '001'                        " Mensaje: "Material FERT debe tener grupo de artículos"
          msgv1  = iv_matnr.                    " Variable: muestra el número de material en el mensaje
    ENDIF.

  ENDMETHOD.

ENDCLASS.


*&---------------------------------------------------------------------*
*& NOTA EDUCATIVA — Diferencias entre tipos de Enhancement
*&
*& En proyectos reales encontrarás tres variantes principales:
*&
*& 1. USER EXIT (el más antiguo — ECC pre-2000)
*&    Función: EXIT_SAPMM06E_001
*&    Cómo: SE37 → buscar EXIT_* → código dentro de INCLUDE Z_EXIT_*
*&    Limitación: solo un desarrollador puede usar cada exit a la vez
*&
*& 2. BAdI CLÁSICO (ECC — la mayoría de sistemas legados)
*&    Cómo: SE18 (definición) + SE19 (implementación)
*&    Ventaja: múltiples implementaciones activas al mismo tiempo
*&    Sintaxis en el código que llama al BAdI:
*&      GET BADI lv_badi_handle TYPE badi_material_save.
*&      CALL BADI lv_badi_handle->check_before_save( ... ).
*&
*& 3. ENHANCEMENT SPOT (S/4HANA — el más moderno)
*&    Cómo: Eclipse ADT → Source Code Library → Enhancement Spots
*&    O transacción: SMOD/CMOD para exits de módulo de funciones
*&    Ventaja: se gestiona con transporte como cualquier objeto ABAP
*&    Sintaxis:
*&      ENHANCEMENT 1 ZENHANCEMENT_SPOT_MM.
*&        " Tu código aquí
*&      ENDENHANCEMENT.
*&
*& Para buscar BAdIs disponibles en un área funcional:
*&   SE18 → F4 en el campo BAdI → filtrar por paquete (ej: MM_MAT para MM)
*&   O en Eclipse: buscar por "Enhancement Spot" en el explorador de objetos
*&---------------------------------------------------------------------*
