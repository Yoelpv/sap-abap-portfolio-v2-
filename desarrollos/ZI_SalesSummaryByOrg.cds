/*───────────────────────────────────────────────────────────────────────────────
  ZI_SalesSummaryByOrg — Vista CDS analítica: resumen de ventas por organización.

  QUÉ HACE: une cabecera (VBAK) y posiciones (VBAP) de pedidos de venta y AGREGA el
  importe neto, la cantidad y el nº de líneas por organización de ventas y divisa.

  POR QUÉ ASÍ:
   · JOIN cabecera↔posición: el importe (NETWR) vive en la posición (VBAP) y la
     organización de ventas (VKORG) en la cabecera (VBAK).
   · sum(...) + GROUP BY solo por las DIMENSIONES (vkorg, waerk) → agregación real.
   · @Semantics.amount.currencyCode: 'Currency' → el importe viaja SIEMPRE con su
     divisa (regla de oro de los campos monetarios en SAP; nunca un número suelto).

  Nota: ejercicio de formación (CDS on-premise sobre VBAK/VBAP). En S/4HANA moderno se
  construiría igual sobre las vistas released (I_SalesDocument / I_SalesDocumentItem).
───────────────────────────────────────────────────────────────────────────────*/
@AbapCatalog.sqlViewName: 'ZISALESSUMORG'
@AbapCatalog.compiler.compareFilter: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Resumen de ventas por organización'

define view ZI_SalesSummaryByOrg
  as select from vbak as Cabecera
    inner join   vbap as Posicion on Posicion.vbeln = Cabecera.vbeln
{
      // --- Dimensiones: por lo que agrupamos --------------------------------
  key Cabecera.vkorg                    as SalesOrganization,
  key Cabecera.waerk                    as Currency,

      // --- Medidas: lo que agregamos ----------------------------------------
      @Semantics.amount.currencyCode: 'Currency'
      sum( Posicion.netwr )             as NetAmount,

      sum( Posicion.kwmeng )            as TotalQuantity,

      count( * )                        as ItemCount
}
group by
  Cabecera.vkorg,
  Cabecera.waerk
