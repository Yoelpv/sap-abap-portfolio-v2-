*&---------------------------------------------------------------------*
*&  Include  ZALV_SFLIGHT_OCUPACION_MOD
*&  Modulos PBO/PAI del Dynpro 0100 que contiene el ALV.
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&  MODULE STATUS_0100  OUTPUT (PBO)
*&  Establece el status de menu y el titulo de la ventana del Dynpro.
*&  ZSTATUS_0100 debe tener activadas las funciones BACK/EXIT/CANCEL.
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'ZSTATUS_0100'.
  SET TITLEBAR  'ZTITLE_0100'.
ENDMODULE.

*&---------------------------------------------------------------------*
*&  MODULE USER_COMMAND_0100  INPUT (PAI)
*&  Captura el codigo de funcion del usuario y lo delega al FORM
*&  USER_COMMAND_0100 para mantener el modulo limpio (sin logica directa).
*&---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  PERFORM user_command_0100 USING sy-ucomm.
ENDMODULE.

*&---------------------------------------------------------------------*
*&  MODULE CARGAR_DATOS  OUTPUT (PBO)
*&  Inicializa y refresca el ALV en cada ciclo PBO del Dynpro.
*&  La logica de creacion de objetos esta protegida por IS INITIAL
*&  dentro de CARGA_DATOS_ALV para no recrear el grid en cada PBO.
*&---------------------------------------------------------------------*
MODULE cargar_datos OUTPUT.
  PERFORM carga_datos_alv.
ENDMODULE.
