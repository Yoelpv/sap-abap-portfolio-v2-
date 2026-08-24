/* ─────────────────────────────────────────────────────────────────────────────
   GENERADO con herramienta propia de generación y verificación de artefactos RAP/CDS
   (proyecto personal). Es una MUESTRA DE LA SALIDA del generador — no picado a mano.
   Lo relevante es el diseño del sistema que lo produce limpio. Ver README de la carpeta.
   ───────────────────────────────────────────────────────────────────────────── */
/*───────────────────────────────────────────────────────────────────────────────
  ZI_Equipment — Vista CDS de INTERFAZ (capa de datos del BO RAP).

  Es la raíz del business object: expone la tabla persistente ZEQUIPMENT como una
  entidad RAP. Lleva los campos de negocio + los campos de administración que RAP
  necesita para el bloqueo optimista (ETag) y la auditoría (quién/cuándo creó/cambió).

  Capas del BO (de abajo a arriba):
    tabla ZEQUIPMENT → [ZI_Equipment] (interfaz) → ZI_Equipment (behavior managed)
    → ZC_Equipment (proyección + @UI) → service definition → service binding (OData V4)
───────────────────────────────────────────────────────────────────────────────*/
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Equipos de mantenimiento — interfaz RAP'
define root view entity ZI_Equipment
  as select from zequipment
{
  key equipment_id                                       as EquipmentId,
      description                                        as Description,
      equipment_type                                     as EquipmentType,
      plant                                              as Plant,
      status                                             as Status,

      // --- Campos de administración (RAP los usa para ETag y auditoría) -----
      @Semantics.user.createdBy: true
      created_by                                         as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at                                         as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by                                    as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at                                    as LastChangedAt,   // ETag total
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at                              as LocalLastChangedAt // ETag de instancia
}
