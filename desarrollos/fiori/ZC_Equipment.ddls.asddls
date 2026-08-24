/*───────────────────────────────────────────────────────────────────────────────
  ZC_Equipment — Vista CDS de PROYECCIÓN + anotaciones @UI.

  Es lo que la app Fiori consume. La proyección expone (un subconjunto de) la interfaz
  y las anotaciones @UI le dicen a Fiori Elements CÓMO pintarse SIN escribir una línea
  de JavaScript: qué columnas van en la lista (lineItem), qué campos en la página de
  objeto (identification), por qué se puede filtrar (selectionField) y la cabecera.

  Regla de oro (la trampa clásica): si el $metadata publicado NO trae estas @UI, la lista
  Fiori sale VACÍA aunque el servicio esté activo. La UI vive en las anotaciones.
───────────────────────────────────────────────────────────────────────────────*/
@EndUserText.label: 'Equipos de mantenimiento — App Fiori (RAP)'
@UI: {
  headerInfo: {
    typeName:       'Equipo',
    typeNamePlural: 'Equipos',
    title:          { value: 'EquipmentId' },
    description:    { value: 'Description' }
  }
}
define root view entity ZC_Equipment
  provider contract transactional_query
  as projection on ZI_Equipment
{
      @UI.facet: [ { id:       'General',
                     purpose:  #STANDARD,
                     type:     #IDENTIFICATION_REFERENCE,
                     label:    'Información General',
                     position: 10 } ]

      @UI: { lineItem:       [ { position: 10 } ],
             identification: [ { position: 10 } ],
             selectionField: [ { position: 10 } ] }
  key EquipmentId,

      @UI: { lineItem: [ { position: 20 } ], identification: [ { position: 20 } ] }
      Description,

      @UI: { lineItem: [ { position: 30 } ], identification: [ { position: 30 } ] }
      EquipmentType,

      @UI: { lineItem:       [ { position: 40 } ],
             identification: [ { position: 40 } ],
             selectionField: [ { position: 20 } ] }
      Plant,

      @UI: { lineItem: [ { position: 50 } ], identification: [ { position: 50 } ] }
      Status,

      // Campos de administración (no se muestran; los usa RAP para ETag/auditoría)
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt
}
