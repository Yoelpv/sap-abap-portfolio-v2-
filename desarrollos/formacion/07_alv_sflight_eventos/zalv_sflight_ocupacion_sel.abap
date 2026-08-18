*&---------------------------------------------------------------------*
*&  Include  ZALV_SFLIGHT_OCUPACION_SEL
*&  Pantalla de seleccion: filtro por codigo de aerolinea.
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-000.
  " P_CARRID: codigo de aerolinea IATA (p.ej. LH, AA, UA).
  " Obligatorio; se valida en AT SELECTION-SCREEN ON p_carrid
  " mediante la funcion CHEQUEAR_AEROLINEA.
  PARAMETERS: p_carrid TYPE scarr-carrid.
SELECTION-SCREEN END OF BLOCK b1.
