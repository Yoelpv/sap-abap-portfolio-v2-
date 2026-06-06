*&---------------------------------------------------------------------*
*& Programa : ZR_MATERIALES_MODULAR
*& Módulo   : MM — Materials Management
*& Entorno  : ECC / S/4HANA On-Premise
*&
*& Descripción:
*&   Reporte de materiales con arquitectura modular mediante INCLUDEs.
*&   Permite cargar datos de MARA/MAKT/MARC, guardarlos en una tabla Z
*&   (ZMATERIALES_YP) y borrar registros existentes.
*&
*& Basado en: ejercicio de formación TAW10 (ZNNAVARROI_INCLUDE.docx)
*&   Aquel ejercicio ya tenía INCLUDEs y FORMs, pero sin comentarios,
*&   con nombres poco descriptivos y mezcla de lógica en el main.
*&   Esta versión separa claramente las responsabilidades de cada include.
*&
*& Estructura de INCLUDEs:
*&   _TOP  → Declaraciones globales (TYPES, DATA, SELECTION-SCREEN)
*&   _F01  → Subrutinas (FORM/ENDFORM) con la lógica del programa
*&---------------------------------------------------------------------*
REPORT zr_materiales_modular.

" El include _TOP contiene toda la declaración de variables y tipos.
" Separarlo aquí permite que _F01 use esas declaraciones sin redefinirlas.
INCLUDE zr_materiales_modular_top.

*----------------------------------------------------------------------*
* EVENTOS DEL PROGRAMA
*----------------------------------------------------------------------*

" INITIALIZATION: se ejecuta antes de mostrar la pantalla de selección.
" Sirve para pre-rellenar parámetros con valores por defecto de negocio.
INITIALIZATION.
  PERFORM f_inicializar.

" START-OF-SELECTION: punto de entrada principal del reporte.
" Solo llamadas a FORMs — la lógica real vive en _F01.
START-OF-SELECTION.
  PERFORM f_buscar_datos.
  PERFORM f_procesar_datos.
  PERFORM f_mostrar_resultado.

" AT SELECTION-SCREEN: validar entradas antes de ejecutar.
AT SELECTION-SCREEN.
  PERFORM f_validar_seleccion.
