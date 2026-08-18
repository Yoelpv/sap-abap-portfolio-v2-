*&---------------------------------------------------------------------*
*& Report  ZALV_SFLIGHT_OCUPACION
*&---------------------------------------------------------------------*
*& Autor   : Yoel Palacios
*& Fecha   : 2024
*& Modulo  : BC-BSP / Formacion ABAP clasico (TAW10/TAW12)
*&
*& Descripcion:
*&   Reporte ALV OO (CL_GUI_ALV_GRID) sobre un JOIN entre SCARR y SFLIGHT.
*&   Calcula el porcentaje de ocupacion de cada vuelo y pinta un semaforo
*&   de iconos SAP en la primera columna:
*&     - Rojo    (@0A@) : ocupacion >= 80 %
*&     - Amarillo(@09@) : ocupacion entre 50 % y 79 %
*&     - Verde   (@08@) : ocupacion < 50 %
*&
*&   La clase local LCL_EVENT maneja tres eventos del ALV:
*&     - DOUBLE_CLICK      -> popup con detalle del vuelo
*&     - TOOLBAR           -> boton personalizado "Mostrar Info"
*&     - USER_COMMAND      -> logica asociada al boton INFO
*&
*&   Patron de diseno: Report clasico + Dynpro 0100 con contenedor ALV.
*&   Estructura: includes TOP / SEL / F01 / MOD (convencion estandar).
*&---------------------------------------------------------------------*
REPORT zalv_sflight_ocupacion.

INCLUDE zalv_sflight_ocupacion_top.   " Declaraciones globales y clase de eventos
INCLUDE zalv_sflight_ocupacion_sel.   " Pantalla de seleccion
INCLUDE zalv_sflight_ocupacion_f01.   " FORMs de logica de negocio
INCLUDE zalv_sflight_ocupacion_mod.   " Modulos PBO/PAI del Dynpro

INITIALIZATION.

* Validacion del parametro de aerolínea al salir del campo
AT SELECTION-SCREEN ON p_carrid.
  PERFORM chequear_aerolinea USING p_carrid.

START-OF-SELECTION.
* Punto de entrada principal: obtener datos, calcular semaforo y mostrar Dynpro
  PERFORM principal.
