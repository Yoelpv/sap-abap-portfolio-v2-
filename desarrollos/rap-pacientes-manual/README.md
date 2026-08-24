# BO RAP — Gestión de Pacientes (construido a mano en formación)

Business Object **RAP managed** que construí **a mano** en formación (S/4HANA BTP · Eclipse ADT),
exportado con **abapGit**. Modela pacientes y centros hospitalarios.

> ✍ **Escrito por mí durante el curso — NO generado.** Es un export abapGit, por eso los objetos
> aparecen como XML de diccionario (tablas, dominios, data elements) + las fuentes RAP legibles
> (`.asbdef`, `.srvdsrv`, `.asddlxs`).

## Objetos (todos con mi sufijo `_ypv`)

| Capa | Objeto |
|------|--------|
| Tablas | `zpacientes_ypv` (id, nombre, apellido, población, provincia, teléfono, email + campos de ETag) · `zcentro_hosp_ypv` |
| Dominios + Data Elements | `zdom_*_ypv` · `zed_*_ypv` (capa DDIC completa, un dominio/DE por campo) |
| Behavior (managed) | [`zcds_zpaciente_ypv.bdef.asbdef`](src/zcds_zpaciente_ypv.bdef.asbdef) — create/update/delete, claves readonly, validation |
| Metadata Extension @UI | [`zcds_me_zpaciente_ypv.ddlx.asddlxs`](src/zcds_me_zpaciente_ypv.ddlx.asddlxs) — headerInfo + facet para Fiori Elements |
| Service Definition + Binding | `zcds_zpaciente_ypv.srvd` + `zsb_zcds_zpaciente_ypv` (OData) |

## Nota honesta (es un ejercicio de formación)
Es trabajo de curso en modo aprendizaje: la vista CDS base no entró en este export abapGit del
paquete, y algún detalle (validation, `strict` mode) está en forma de tutorial. Lo importante es
que demuestra que **construí a mano** la pila RAP —DDIC → behavior → metadata extension → service
binding— entendiendo cómo encajan las capas.
