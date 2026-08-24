# Fiori RAP — Gestión de Equipos de Mantenimiento (PM)

Business Object **RAP managed** completo: una app Fiori Elements de CRUD sobre equipos de
mantenimiento, construida siguiendo el patrón estándar de S/4HANA. Ejercicio de formación
en BTP / S/4HANA Cloud (Eclipse ADT).

## Las capas del BO (de datos a UI)

| Capa | Objeto | Qué aporta |
|------|--------|------------|
| Tabla persistente | `ZEQUIPMENT` | Almacena los datos (clave `equipment_id` + campos de admin para ETag) |
| CDS de interfaz | [`ZI_Equipment`](ZI_Equipment.ddls.asddls) | Expone la tabla como entidad RAP; campos de admin con `@Semantics` |
| Behavior (managed) | [`ZI_Equipment` bdef](ZI_Equipment.bdef.asbdef) | Qué se puede hacer (create/update/delete), obligatorios, ETag, mapping |
| CDS de proyección + @UI | [`ZC_Equipment`](ZC_Equipment.ddls.asddls) | Lo que ve la app + anotaciones `@UI` (lista, página objeto, filtros) |
| Behavior de proyección | [`ZC_Equipment` bdef](ZC_Equipment.bdef.asbdef) | Qué operaciones expone a la app (`use create/update/delete`) |
| Service definition | [`ZUI_EQUIPMENT_O2`](ZUI_EQUIPMENT_O2.srvd.srvdsrv) | Qué entidades se publican |
| Service binding | *(se crea en ADT)* | Genera el OData **V4** que consume Fiori Elements |

## Conceptos clave (para explicarlo)

- **Managed:** el framework RAP hace la persistencia (INSERT/UPDATE/DELETE) por mí; sin
  lógica extra no programo nada — solo declaro el comportamiento.
- **ETag (bloqueo optimista):** `etag master LocalLastChangedAt`. Si dos usuarios editan
  el mismo equipo a la vez, el segundo recibe un error de ETag en vez de pisar el cambio
  del primero.
- **Fiori Elements sin código:** la UI se genera desde las anotaciones `@UI` del CDS de
  proyección. **Trampa clásica:** si el `$metadata` publicado no trae esas `@UI`, la lista
  Fiori sale vacía aunque el servicio esté activo.

## Tabla `ZEQUIPMENT` (estructura)

```
equipment_id          KEY   CHAR(18)     -- clave de negocio (nº de equipo)
description                 CHAR(40)
equipment_type              CHAR(10)
plant                       CHAR(4)      -- centro (werks)
status                      CHAR(4)
created_by                  syuname      (@Semantics createdBy)
created_at                  timestampl   (@Semantics createdAt)
last_changed_by             syuname      (@Semantics lastChangedBy)
last_changed_at             timestampl   (@Semantics lastChangedAt)   -- ETag total
local_last_changed_at       timestampl   (@Semantics localInstanceLastChangedAt) -- ETag instancia
```

## Cómo se activa/publica (resumen)

1. Activar tabla → interfaz → behavior → proyección → behavior de proyección → service def.
2. Crear el **service binding** sobre `ZUI_EQUIPMENT_O2` (tipo OData V4 - UI) y **publicar**.
3. Previsualizar con Fiori Elements desde el binding.
