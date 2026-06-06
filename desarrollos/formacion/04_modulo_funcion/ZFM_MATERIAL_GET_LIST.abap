*&---------------------------------------------------------------------*
*& Función  : ZFM_MATERIAL_GET_LIST
*& Grupo    : ZFG_MATERIALES_YP
*& Módulo   : MM — Materials Management
*& Entorno  : ECC / S/4HANA On-Premise
*&
*& Descripción:
*&   Módulo de función reutilizable que devuelve una lista de materiales
*&   filtrada por tipo y/o centro, con su descripción en el idioma activo.
*&   Retorna errores mediante la estructura estándar BAPIRET2.
*&
*& ORIGEN DIRECTO: evolución del FM 'ZEMES_B_FM_PP_DASHB_GET_F_LIST'
*& que escribimos en la formación (full_list.docx, get_f_list.docx).
*&
*& Qué se mejoró respecto al FM del curso:
*&   1. Usa tablas SAP estándar (MARA/MAKT) en lugar de tablas Z de empresa
*&   2. JOIN en el SELECT (el original tenía SELECT + LOOP para el texto)
*&   3. Parámetros con IMPORTING/EXPORTING correctamente tipados
*&   4. Manejo BAPIRET2 completo: severity + id + number + message_v1
*&   5. Devuelve EV_SUBRC para que el llamador sepa si fue bien o mal
*&
*& Interfaz:
*&   IMPORTING: IV_MTART (opcional), IV_WERKS (opcional), IV_SPRAS
*&   EXPORTING: ET_MATERIALS, ET_RETURN, EV_SUBRC
*&---------------------------------------------------------------------*
FUNCTION zfm_material_get_list.
*"----------------------------------------------------------------------
*"*"Interfase local
*"  IMPORTING
*"     VALUE(IV_MTART)     TYPE  MARA-MTART OPTIONAL
*"     VALUE(IV_WERKS)     TYPE  MARC-WERKS OPTIONAL
*"     VALUE(IV_SPRAS)     TYPE  SPRAS DEFAULT SY-LANGU
*"  EXPORTING
*"     VALUE(ET_MATERIALS) TYPE  ZTT_MATERIAL_YP
*"     VALUE(ET_RETURN)    TYPE  BAPIRET2_T
*"     VALUE(EV_SUBRC)     TYPE  SY-SUBRC
*"----------------------------------------------------------------------

  " Estructura de trabajo para BAPIRET2
  DATA ls_return TYPE bapiret2.

  " Limpiar exportaciones al inicio de la función
  " (buena práctica: el llamador no debe preocuparse del estado anterior)
  CLEAR: et_materials, et_return, ev_subrc.

  " Validar parámetro de idioma — es el único obligatorio implícitamente
  " (viene por defecto SY-LANGU, pero podría llegar vacío si el llamador lo sobreescribe)
  IF iv_spras IS INITIAL.
    ev_subrc = 1.
    ls_return-type       = 'E'.
    ls_return-id         = 'ZFM_MATERIALES'.
    ls_return-number     = '001'.
    ls_return-message_v1 = 'El idioma (IV_SPRAS) es obligatorio.'.
    ls_return-message    = ls_return-message_v1.
    APPEND ls_return TO et_return.
    RETURN.
  ENDIF.

  " Construir WHERE dinámico según los parámetros opcionales recibidos
  " El truco: si IV_MTART está vacío, el CASE no filtra por tipo
  DATA(lv_mtart_filter) = iv_mtart.
  DATA(lv_werks_filter) = iv_werks.

  " Lectura principal con JOIN MARA + MAKT + MARC
  " LEFT JOIN en MARC para devolver también materiales sin centro asignado
  IF lv_mtart_filter IS NOT INITIAL AND lv_werks_filter IS NOT INITIAL.
    " Ambos filtros activos
    SELECT mara~matnr,
           mara~mtart,
           marc~werks,
           makt~maktx,
           mara~meins,
           mara~matkl
      FROM mara
      INNER JOIN makt ON makt~matnr = mara~matnr
                     AND makt~spras = @iv_spras
      LEFT OUTER JOIN marc ON marc~matnr = mara~matnr
      INTO TABLE @et_materials
      WHERE mara~mtart = @lv_mtart_filter
        AND mara~lvorm = ''
        AND marc~werks = @lv_werks_filter.

  ELSEIF lv_mtart_filter IS NOT INITIAL.
    " Solo filtro de tipo de material
    SELECT mara~matnr,
           mara~mtart,
           marc~werks,
           makt~maktx,
           mara~meins,
           mara~matkl
      FROM mara
      INNER JOIN makt ON makt~matnr = mara~matnr
                     AND makt~spras = @iv_spras
      LEFT OUTER JOIN marc ON marc~matnr = mara~matnr
      INTO TABLE @et_materials
      WHERE mara~mtart = @lv_mtart_filter
        AND mara~lvorm = ''.

  ELSEIF lv_werks_filter IS NOT INITIAL.
    " Solo filtro de centro
    SELECT mara~matnr,
           mara~mtart,
           marc~werks,
           makt~maktx,
           mara~meins,
           mara~matkl
      FROM mara
      INNER JOIN makt ON makt~matnr = mara~matnr
                     AND makt~spras = @iv_spras
      INNER JOIN marc ON marc~matnr = mara~matnr
      INTO TABLE @et_materials
      WHERE mara~lvorm = ''
        AND marc~werks = @lv_werks_filter.

  ELSE.
    " Sin filtros: devolver mensaje de aviso (sin filtros puede ser lento en producción)
    ev_subrc = 4.
    ls_return-type       = 'W'.
    ls_return-id         = 'ZFM_MATERIALES'.
    ls_return-number     = '002'.
    ls_return-message_v1 = 'Sin filtros activos: la consulta puede devolver muchos registros.'.
    ls_return-message    = ls_return-message_v1.
    APPEND ls_return TO et_return.

    " Aun así ejecutamos la consulta (el llamador decide si la acepta)
    SELECT mara~matnr,
           mara~mtart,
           marc~werks,
           makt~maktx,
           mara~meins,
           mara~matkl
      FROM mara
      INNER JOIN makt ON makt~matnr = mara~matnr
                     AND makt~spras = @iv_spras
      LEFT OUTER JOIN marc ON marc~matnr = mara~matnr
      INTO TABLE @et_materials
      WHERE mara~lvorm = ''
      UP TO 1000 ROWS.          " Límite de seguridad sin filtros

  ENDIF.

  ev_subrc = sy-subrc.

  " Si no se encontraron datos, informar al llamador con tipo 'I' (info)
  IF et_materials IS INITIAL.
    ev_subrc = 4.
    ls_return-type       = 'I'.
    ls_return-id         = 'ZFM_MATERIALES'.
    ls_return-number     = '003'.
    ls_return-message_v1 = 'No se encontraron materiales con los parámetros indicados.'.
    ls_return-message    = ls_return-message_v1.
    APPEND ls_return TO et_return.
  ELSE.
    " Éxito: añadir mensaje informativo con el número de registros
    ls_return-type       = 'S'.
    ls_return-id         = 'ZFM_MATERIALES'.
    ls_return-number     = '000'.
    ls_return-message_v1 = CONV char50( lines( et_materials ) ).
    ls_return-message    = |{ lines( et_materials ) } materiales recuperados correctamente.|.
    APPEND ls_return TO et_return.
  ENDIF.

ENDFUNCTION.
