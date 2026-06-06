# Portafolio ABAP — Basado en Formación Real

Estos ejercicios están construidos directamente sobre el código que desarrollé
durante la formación (cursos ALTIM/DISA/SCL, TAW10/11/12). Para cada ejercicio
se indica el archivo original del curso y qué se mejoró.

---

## Índice

| # | Ejercicio | Origen | Nivel |
|---|-----------|--------|-------|
| 01 | [Reporte materiales](#01) | `Report.docx` del curso | Básico |
| 02 | [Modularización con INCLUDEs](#02) | `ZNNAVARROI_INCLUDE.docx` | Básico-Medio |
| 03 | [ALV SALV avanzado](#03) | `z_ypalacios_lock_t44_v2` (mi código) | Medio |
| 04 | [Módulo de función](#04) | `full_list.docx` / `dashb_create.docx` | Medio |
| 05 | [Clase OOP + Factory](#05) | Nuevo (TAW11 OOP) | Medio-Alto |
| 06 | [OData clásico](#06) | `ZCL_Z_YPALACIOS_TRAINI_DPC_EXT` (mi código) | Medio-Alto |

---

## 01 — Reporte Materiales {#01}

**Archivo:** `01_reporte_materiales/ZR_MATERIALES_YPALACIOS.abap`

**Origen:** `Report.docx` — report `z_jjingles_formacion` del curso de formación.

**Lo que hacía el original:**
- `SELECT` con vieja sintaxis (`INTO TABLE gt_mara WHERE lvorm EQ 'X'`)
- Dos tablas internas separadas + LOOP anidado para cruzar datos (O(n²))
- Idioma hardcodeado a `'S'`
- Sin SELECTION-SCREEN
- Salida con `WRITE` (lista clásica)

**Lo que se mejoró:**
- JOIN de tres tablas en una sola query (MARA + MAKT + MARC)
- `SY-LANGU` para idioma dinámico
- SELECTION-SCREEN con SELECT-OPTIONS y bloque enmarcado
- `CL_SALV_TABLE` con cabeceras en español, ordenación y exportación a Excel
- Modularización con FORM/ENDFORM

---

## 02 — Modularización con INCLUDEs {#02}

**Archivos:** `02_modularizacion/ZR_MATERIALES_MODULAR*.abap` (3 archivos)

**Origen:** `ZNNAVARROI_INCLUDE.docx` — reporte con INCLUDEs del curso.

**Lo que hacía el original:**
- INCLUDEs y FORMs sin comentarios
- Nombres poco descriptivos (`busqueda`, `procesar`, `borrar`)
- Lógica mezclada en el programa principal
- Sin evento `AT SELECTION-SCREEN`

**Lo que se mejoró:**
- Main limpio: solo incluir INCLUDEs y llamar FORMs
- `_TOP`: solo declaraciones (convenio TAW10)
- `_F01`: FORMs con nombres descriptivos y comentarios de ABAP senior
- `INITIALIZATION` + `AT SELECTION-SCREEN` + `START-OF-SELECTION` bien separados
- Validación de la pantalla de selección antes de ejecutar

---

## 03 — ALV SALV Avanzado {#03}

**Archivo:** `03_alv_salv_avanzado/ZR_ALV_SALV_AVANZADO.abap`

**Origen:** `z_ypalacios_lock_t44_v2` — **mi propio código de la formación**.

**Lo que hacía el original:**
```abap
cl_salv_table=>factory(
  IMPORTING r_salv_table = data(go_alv)
  CHANGING  t_table      = et_dashboard
).
go_alv->display( ).
```
Solo el display básico, sin ninguna configuración adicional.

**Lo que se añadió:**
- Coloreado de filas por tipo de material (FERT=azul, ROH=verde, HALB=amarillo)
- Ordenación por defecto al abrir el ALV
- Botón personalizado "Refrescar" en la toolbar
- Clase local de eventos (`SET HANDLER`) para capturar el botón
- Cabeceras de columna en español con macro `DEFINE`
- Columna técnica `T_COLOR` oculta automáticamente

---

## 04 — Módulo de Función {#04}

**Archivo:** `04_modulo_funcion/ZFM_MATERIAL_GET_LIST.abap`

**Origen:** `full_list.docx` + `dashb_create.docx` del curso.

**Lo que hacía el original:**
- SELECT directo en el FM sin validación de parámetros
- Si el SELECT fallaba: `IF sy-subrc <> 0 / ELSE / ENDIF` vacíos
- Parámetros sin OPTIONAL documentado
- Tablas específicas de la empresa (ZEMES_B_TB_00043) no exportables al portafolio

**Lo que se mejoró:**
- Usa tablas SAP estándar (MARA/MAKT/MARC) — portafolio neutral
- Patrón BAPIRET2 completo: type + id + number + message_v1
- `EV_SUBRC` con valores documentados (0=OK, 4=warning, 1=error)
- Límite de seguridad `UP TO 1000 ROWS` si no hay filtros
- Mensaje de éxito con número de registros devueltos

---

## 05 — Clase OOP con Patrón Factory {#05} [PLUS]

**Archivo:** `05_clase_oo/ZCL_MATERIAL_MANAGER.abap`

**Origen:** Nuevo ejercicio basado en lo visto en TAW11 (OOP ABAP).

**Qué demuestra:**
- Clase abstracta como contrato base
- Herencia: `ZCL_MATERIAL_READER` y `ZCL_MATERIAL_WRITER`
- Polimorfismo: el llamador usa `PROCESS()` sin saber la subclase
- Patrón Factory: `GET_INSTANCE( iv_mode = 'R' )` devuelve el Reader
- Composición: el Writer usa al Reader internamente para la lectura
- `CREATE PROTECTED`: solo el Factory puede instanciar subclases
- Programa de prueba incluido en el mismo archivo

---

## 06 — OData Clásico (SAP Gateway) {#06}

**Archivo:** `06_odata_clasico/ZCL_YPALACIOS_DPC_EXT.abap`

**Origen:** `ZCL_Z_YPALACIOS_TRAINI_DPC_EXT` — **mi propio código de la formación**.

El servicio OData que implementé durante la formación para exponer
la tabla de Centros de Coste (CSKS) a través de SAP Gateway.

**Lo que hacía el original:**
```abap
if sy-subrc = 0.
else.
endif.
```
El IF/ELSE estaba completamente vacío — si el registro no existía,
el servicio devolvía HTTP 200 con datos vacíos en lugar de un 404.

**Lo que se mejoró:**
- `GET_ENTITY`: lanza `/IWBEP/CX_MGW_BUSI_EXCEPTION` cuando no se encuentra el CC → HTTP 404 correcto
- `CREATE_ENTITY`: añadido `COMMIT WORK AND WAIT` (sin esto los datos no se persistían)
- Validación de duplicados antes del INSERT
- Método privado `NORMALIZE_KEY` para centralizar `CONVERSION_EXIT_ALPHA_INPUT`
- Guía de activación en SEGW en los comentarios del archivo

---

## Entorno de desarrollo utilizado

- **Sistema:** ECC 6.0 / S/4HANA 2022 (on-premise)
- **Herramienta:** SAP GUI + Eclipse ADT
- **Curso base:** TAW10 + TAW11 + TAW12 (ALTIM/XPERIS)
