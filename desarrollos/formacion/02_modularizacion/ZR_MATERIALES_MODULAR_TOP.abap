*&---------------------------------------------------------------------*
*& Include : ZR_MATERIALES_MODULAR_TOP
*& Programa: ZR_MATERIALES_MODULAR
*&
*& Contenido: Declaraciones globales — tipos, tablas internas y pantalla
*& de selección.
*&
*& Convención de nombres (del curso TAW10):
*&   TY_  → tipo local definido con TYPES
*&   GT_  → tabla interna global
*&   GS_  → work area (estructura) global
*&   GV_  → variable escalar global
*&   SO_  → select-option
*&   P_   → parameter
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
* TIPOS
*----------------------------------------------------------------------*
" Estructura de trabajo interno — combina campos de MARA, MARC y MAKT
TYPES: BEGIN OF ty_material,
         matnr TYPE mara-matnr,   " Clave: número de material
         mtart TYPE mara-mtart,   " Tipo (ROH, FERT, HALB...)
         werks TYPE marc-werks,   " Centro/planta
         maktx TYPE makt-maktx,   " Descripción en idioma del usuario
       END OF ty_material.

*----------------------------------------------------------------------*
* VARIABLES GLOBALES
*----------------------------------------------------------------------*
DATA: gt_materials TYPE TABLE OF ty_material,  " Tabla interna principal
      gs_material  TYPE ty_material,            " Work area de lectura
      gv_error     TYPE char1.                  " Flag de error en proceso

*----------------------------------------------------------------------*
* PANTALLA DE SELECCIÓN
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b_filtros WITH FRAME TITLE TEXT-001.

  " Tipo de material: en el curso original era hardcodeado a ROH/HALB/FERT
  SELECT-OPTIONS so_mtart FOR mara-mtart DEFAULT 'FERT'.

  " Centro: necesario para limitar la consulta a MARC
  SELECT-OPTIONS so_werks FOR marc-werks.

SELECTION-SCREEN END OF BLOCK b_filtros.

SELECTION-SCREEN BEGIN OF BLOCK b_acciones WITH FRAME TITLE TEXT-002.

  " Modo de operación: el ejercicio del curso tenía un checkbox P_BORR
  " para alternar entre "cargar datos" y "borrar tabla Z"
  PARAMETERS: p_carga  RADIOBUTTON GROUP rbg1 DEFAULT 'X',  " Cargar datos en tabla Z
              p_borrar RADIOBUTTON GROUP rbg1.              " Borrar tabla Z

SELECTION-SCREEN END OF BLOCK b_acciones.
