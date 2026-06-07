# Guía de estudio — Portafolio ABAP

Aprende a explicar cada ejercicio en una entrevista.
Para cada uno: qué es, qué hace el código, por qué es mejor que el original,
y cómo responder si te preguntan por él.

---

## Ejercicio 01 — Reporte de materiales
**Archivo:** `01_reporte_materiales/ZR_MATERIALES_YPALACIOS.abap`

### Qué es
Un reporte ABAP que lee materiales de SAP (tabla MARA) con su descripción
(tabla MAKT) y su centro asignado (tabla MARC), y los muestra en pantalla
con un ALV moderno.

### Qué hace el código, línea a línea

**1. TYPES**
```abap
TYPES: BEGIN OF ty_output,
         matnr TYPE mara-matnr,
         mtart TYPE mara-mtart,
         werks TYPE marc-werks,
         maktx TYPE makt-maktx,
       END OF ty_output.
```
Defines un tipo propio (TY_OUTPUT) con los campos que necesitas mostrar.
Por qué no usar directamente la tabla MARA: porque MARA tiene 200+ campos
y tú solo necesitas 4. Usar un tipo propio es más eficiente y claro.

**2. SELECTION-SCREEN**
```abap
SELECT-OPTIONS so_mtart FOR mara-mtart DEFAULT 'FERT'.
SELECT-OPTIONS so_werks FOR marc-werks.
```
Pantalla de filtros antes de ejecutar el reporte.
`SELECT-OPTIONS` es más potente que `PARAMETERS`: permite rangos (de X a Y),
múltiples valores y exclusiones. El DEFAULT 'FERT' pre-rellena el campo.

**3. El SELECT con JOIN**
```abap
SELECT mara~matnr, mara~mtart, marc~werks, makt~maktx
  FROM mara
  INNER JOIN marc ON marc~matnr = mara~matnr
  INNER JOIN makt ON makt~matnr = mara~matnr
                 AND makt~spras = @sy-langu
  INTO TABLE @gt_output
  WHERE mara~mtart IN @so_mtart
    AND mara~lvorm = ''
    AND marc~werks IN @so_werks.
```
Una sola consulta a base de datos que cruza 3 tablas.
- `INNER JOIN`: une tablas por campos relacionados (como un JOIN en SQL)
- `makt~spras = @sy-langu`: el texto en el idioma del usuario (no hardcodeado)
- `mara~lvorm = ''`: excluye materiales marcados para borrado
- `@` antes de variables: sintaxis moderna de Open SQL (obligatoria desde SAP 7.4)

**Por qué es mejor que el original del curso:**
El original hacía esto:
```abap
SELECT matnr mtart FROM mara INTO TABLE gt_mara WHERE lvorm EQ 'X'.
SELECT matnr spras maktx FROM makt INTO TABLE gt_makt
  FOR ALL ENTRIES IN gt_mara WHERE matnr = gt_mara-matnr AND spras EQ 'S'.
LOOP AT gt_mara INTO gs_mara.
  LOOP AT gt_makt INTO gs_makt WHERE matnr = gs_mara-matnr.
    " ... rellenar salida
  ENDLOOP.
ENDLOOP.
```
Problemas:
- 2 queries a BD + un bucle doble en memoria (O(n²))
- Idioma 'S' hardcodeado (no funciona en sistemas en inglés)
- Sin pantalla de selección (lee TODO)
- WRITE para mostrar (feo, sin opciones para el usuario)

**4. CL_SALV_TABLE**
```abap
cl_salv_table=>factory(
  IMPORTING r_salv_table = go_alv
  CHANGING  t_table      = gt_output
).
go_alv->get_functions( )->set_all( abap_true ).
go_alv->display( ).
```
Muestra los datos en una grid moderna con filtros, ordenación y exportación
a Excel de forma automática. El usuario puede hacer todo eso sin código extra.

### Cómo explicarlo en entrevista
> "Hice un reporte de materiales donde mejoré el código del curso. El original
> usaba dos SELECT separados y luego un doble LOOP para cruzar los datos, lo que
> es ineficiente. Lo reemplacé por un JOIN de tres tablas en una sola query.
> También añadí una pantalla de selección con SELECT-OPTIONS y cambié el WRITE
> por CL_SALV_TABLE para que el usuario pudiera filtrar y exportar a Excel."

---

## Ejercicio 02 — Modularización con INCLUDEs
**Archivos:** `02_modularizacion/ZR_MATERIALES_MODULAR*.abap` (3 archivos)

### Qué es
El mismo reporte de materiales pero dividido en 3 archivos siguiendo el
estándar de modularización que enseña SAP: programa principal + _TOP + _F01.

### Los 3 archivos y para qué sirve cada uno

**ZR_MATERIALES_MODULAR.abap** — El programa principal
Solo contiene el esqueleto: los INCLUDE y las llamadas a los eventos ABAP.
No tiene lógica. Solo dice: "ejecuta esto en cada evento".
```abap
INCLUDE zr_materiales_modular_top.   " primero las declaraciones

INITIALIZATION.
  PERFORM f_inicializar.

AT SELECTION-SCREEN.
  PERFORM f_validar_seleccion.

START-OF-SELECTION.
  PERFORM f_buscar_datos.
  PERFORM f_procesar_datos.
  PERFORM f_mostrar_resultado.
```

**ZR_MATERIALES_MODULAR_TOP.abap** — Las declaraciones
Solo DATA, TYPES, SELECT-OPTIONS y PARAMETERS. Nada de lógica.
Convención de nombres que pregunta mucho en entrevistas:
- `TY_` = tipo propio (TYPES)
- `GT_` = tabla interna global
- `GS_` = work area (estructura) global
- `GV_` = variable escalar global
- `SO_` = select-option
- `P_` = parameter

**ZR_MATERIALES_MODULAR_F01.abap** — La lógica
Todos los FORM/ENDFORM con la lógica real del programa.
Cada FORM hace una cosa concreta y tiene un nombre descriptivo.

### Los 3 eventos ABAP que debes conocer

| Evento | Cuándo se ejecuta | Para qué sirve |
|--------|-------------------|----------------|
| `INITIALIZATION` | Antes de mostrar la pantalla | Pre-rellenar valores por defecto |
| `AT SELECTION-SCREEN` | Al pulsar Ejecutar | Validar los parámetros antes de continuar |
| `START-OF-SELECTION` | Después de la pantalla (si no hay error) | Ejecutar la lógica principal |

### MODIFY vs INSERT vs UPDATE
```abap
MODIFY zmateriales_yp FROM TABLE gt_materials.
```
- `INSERT`: falla si el registro ya existe (dump)
- `UPDATE`: falla si el registro NO existe
- `MODIFY`: si existe lo actualiza, si no existe lo inserta. El más seguro.

### Cómo explicarlo en entrevista
> "Este ejercicio muestra la estructura de modularización estándar de SAP:
> programa principal limpio con solo los INCLUDE, el _TOP con todas las
> declaraciones y el _F01 con los FORM. También uso los tres eventos ABAP:
> INITIALIZATION para pre-rellenar la pantalla, AT SELECTION-SCREEN para
> validar, y START-OF-SELECTION para ejecutar."

---

## Ejercicio 03 — ALV SALV Avanzado
**Archivo:** `03_alv_salv_avanzado/ZR_ALV_SALV_AVANZADO.abap`

### Qué es
Este es el ejercicio más importante para explicar en entrevista porque
es una mejora directa de mi propio código del curso (`z_ypalacios_lock_t44_v2`).

### CL_SALV_TABLE vs REUSE_ALV_GRID_DISPLAY

Hay dos formas de hacer ALV en SAP:

**Forma antigua (REUSE_ALV_GRID_DISPLAY):**
```abap
CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
  EXPORTING i_structure_name = 'MARA'
  TABLES    t_outtab = gt_data.
```
Más sencillo de escribir pero menos flexible.

**Forma moderna (CL_SALV_TABLE):**
```abap
cl_salv_table=>factory(
  IMPORTING r_salv_table = go_alv
  CHANGING  t_table      = gt_data
).
go_alv->display( ).
```
Orientado a objetos, más configurable, es lo que se usa hoy en día.

### El coloreado de filas — la parte más llamativa

Para colorear filas en CL_SALV_TABLE necesitas:
1. Añadir un campo `T_COLOR TYPE LVC_T_SCOL` a tu estructura
2. Calcular el color en el LOOP y meterlo en ese campo
3. Activar `set_row_coloring( abap_true )`
4. Ocultar la columna T_COLOR (es técnica, el usuario no debe verla)

```abap
ls_color-col = col_positive.   " Verde
ls_color-int = 1.              " Intensidad
APPEND ls_color TO ls_mat-t_color.
```

Colores SAP estándar:
- `col_heading` = Azul
- `col_positive` = Verde
- `col_negative` = Rojo
- `col_total` = Amarillo/naranja

### Clase local de eventos
Para que el botón personalizado haga algo, necesitas una clase local:
```abap
CLASS lcl_eventos DEFINITION.
  PUBLIC SECTION.
    METHODS on_user_command
      FOR EVENT added_function OF cl_salv_events_functions
      IMPORTING e_salv_function.
ENDCLASS.
```
Y luego registrarla:
```abap
SET HANDLER go_eventos->on_user_command FOR go_alv->get_event( ).
```
`SET HANDLER` = "cuando ocurra este evento, llama a este método".

### La macro DEFINE — un truco de ABAP
```abap
DEFINE set_col_text.
  TRY.
    lo_col ?= go_alv->get_columns( )->get_column( &1 ).
    lo_col->set_short_text(  &2 ).
    lo_col->set_medium_text( &3 ).
    lo_col->set_long_text(   &4 ).
  CATCH cx_salv_not_found. "#EC NO_HANDLER
  ENDTRY.
END-OF-DEFINITION.

set_col_text 'MATNR' 'Material' 'N° Material' 'Número de Material'.
```
`DEFINE ... END-OF-DEFINITION` es una macro ABAP. Evita repetir el mismo
bloque de código para cada columna. El `&1, &2, &3` son los parámetros.

### Cómo explicarlo en entrevista
> "En el curso yo ya usaba CL_SALV_TABLE en mi código del ejercicio lock_t44_v2,
> pero solo el display básico. Lo mejoré añadiendo coloreado de filas según el
> tipo de material — FERT en azul, ROH en verde, HALB en amarillo — usando el
> campo T_COLOR. También añadí un botón personalizado en la toolbar capturando
> el evento con una clase local y SET HANDLER."

---

## Ejercicio 04 — Módulo de Función
**Archivo:** `04_modulo_funcion/ZFM_MATERIAL_GET_LIST.abap`

### Qué es
Una función reutilizable que cualquier otro programa puede llamar para
obtener una lista de materiales. Es la alternativa a copiar-pegar el SELECT
en cada sitio que lo necesites.

### La interfaz del módulo de función
```abap
FUNCTION zfm_material_get_list.
*" IMPORTING
*"   VALUE(IV_MTART) TYPE MARA-MTART OPTIONAL
*"   VALUE(IV_WERKS) TYPE MARC-WERKS OPTIONAL
*"   VALUE(IV_SPRAS) TYPE SPRAS DEFAULT SY-LANGU
*" EXPORTING
*"   VALUE(ET_MATERIALS) TYPE ZTT_MATERIAL_YP
*"   VALUE(ET_RETURN)    TYPE BAPIRET2_T
*"   VALUE(EV_SUBRC)     TYPE SY-SUBRC
```

Diferencia IMPORTING vs EXPORTING:
- `IMPORTING` = lo que el FM recibe (parámetros de entrada)
- `EXPORTING` = lo que el FM devuelve (resultados)
- `OPTIONAL` = el parámetro no es obligatorio
- `DEFAULT SY-LANGU` = si no se pasa, usa el idioma del usuario

VALUE vs REFERENCE:
- `VALUE(IV_MTART)` = el FM recibe una copia. Si lo modifica, el original no cambia.
- Sin VALUE = pasa por referencia. Si el FM lo modifica, cambia el original también.
- Para IMPORTING: siempre VALUE (más seguro)
- Para EXPORTING: siempre VALUE (el FM escribe en su copia, SAP la devuelve al salir)

### El patrón BAPIRET2 — estándar SAP para mensajes
```abap
DATA ls_return TYPE bapiret2.

ls_return-type       = 'E'.   " E=Error, W=Warning, I=Info, S=Success
ls_return-id         = 'ZFM_MATERIALES'.   " clase de mensaje
ls_return-number     = '001'.              " número de mensaje
ls_return-message_v1 = 'El idioma es obligatorio.'.
ls_return-message    = ls_return-message_v1.
APPEND ls_return TO et_return.
```

BAPIRET2 es la estructura estándar de SAP para devolver mensajes desde
un FM. En lugar de hacer `MESSAGE ... TYPE 'E'` (que para la ejecución),
añades el error a una tabla y el llamador decide qué hacer.

### EV_SUBRC — código de retorno
```abap
ev_subrc = 0.   " Todo OK
ev_subrc = 4.   " Warning (datos encontrados pero con aviso)
ev_subrc = 8.   " Error de negocio
ev_subrc = 1.   " Error técnico / parámetros inválidos
```
El llamador mira EV_SUBRC primero: si es 0, todo bien. Si no, mira ET_RETURN.

### Cómo llamar a un FM desde otro programa
```abap
CALL FUNCTION 'ZFM_MATERIAL_GET_LIST'
  EXPORTING
    iv_mtart     = 'FERT'
    iv_werks     = '1000'
  IMPORTING
    et_materials = lt_materials
    et_return    = lt_return
    ev_subrc     = lv_subrc.

IF lv_subrc > 0.
  " Hubo algún problema — mirar lt_return para el detalle
ENDIF.
```

### Cómo explicarlo en entrevista
> "El módulo de función encapsula la lógica de consulta de materiales para
> reutilizarla desde cualquier programa. Usa el patrón BAPIRET2 para devolver
> mensajes en lugar de interrumpir con MESSAGE TYPE 'E', lo que da más control
> al llamador. El parámetro IV_SPRAS tiene DEFAULT SY-LANGU para que por defecto
> use el idioma del usuario sin necesidad de pasarlo explícitamente."

---

## Ejercicio 05 — Clase OOP con patrón Factory [PLUS]
**Archivo:** `05_clase_oo/ZCL_MATERIAL_MANAGER.abap`

### Qué es
Una clase ABAP orientada a objetos que gestiona materiales.
Demuestra los 4 conceptos fundamentales de OOP que preguntan en entrevistas.

### Los 4 conceptos de OOP en ABAP

**1. Encapsulación**
Separar qué es público (API del objeto) de qué es privado (implementación interna).
```abap
PUBLIC SECTION.
  METHODS process ...    " Accesible desde fuera

PROTECTED SECTION.
  DATA mv_mode TYPE char1.   " Solo la clase y sus hijos

PRIVATE SECTION.
  " Solo esta clase
```

**2. Herencia**
Una clase hija hereda todo lo de la clase padre y puede añadir o cambiar cosas.
```abap
CLASS zcl_material_reader DEFINITION
  INHERITING FROM zcl_material_manager.  " Hereda de la base
```
La clase hija hereda el método `show_alv` sin tener que reescribirlo.

**3. Polimorfismo**
Puedes llamar al mismo método en objetos de tipos distintos y cada uno se comporta diferente.
```abap
" lo_manager puede ser un Reader o un Writer
lo_manager->process( ... ).   " El mismo código llama al método correcto de cada clase
```

**4. Abstracción**
La clase base define QUÉ se tiene que hacer (el contrato) sin decir CÓMO.
```abap
CLASS zcl_material_manager DEFINITION PUBLIC ABSTRACT.
  PUBLIC SECTION.
    METHODS process ABSTRACT.   " Las subclases DEBEN implementarlo
```
`ABSTRACT` = no se puede instanciar directamente. Solo las subclases.

### El patrón Factory
En lugar de que quien llama decida qué subclase crear, hay un método especial
(el Factory) que lo decide:
```abap
CLASS-METHODS get_instance
  IMPORTING iv_mode TYPE char1
  RETURNING VALUE(ro_instance) TYPE REF TO zcl_material_manager.

" Uso:
lo_manager = zcl_material_manager=>get_instance( iv_mode = 'R' ).
```
`CLASS-METHODS` = método estático (se llama en la clase, no en un objeto).
`=>` = acceso a método estático (como `::` en otros lenguajes).
`->` = acceso a método de instancia.

### CREATE PROTECTED
```abap
CLASS zcl_material_manager DEFINITION CREATE PROTECTED.
```
Solo la clase misma (el Factory) puede crear instancias.
Desde fuera, si intentas `CREATE OBJECT TYPE zcl_material_manager`, falla.
Esto fuerza a pasar por el Factory, que garantiza que siempre se crea bien.

### Cómo explicarlo en entrevista
> "Esta clase demuestra los conceptos de OOP de ABAP con un caso real.
> La clase base es abstracta y define el contrato: el método PROCESS que
> todas las subclases deben implementar. El Reader lo implementa con un SELECT,
> el Writer lo implementa guardando en una tabla Z. El patrón Factory decide
> cuál instanciar según el parámetro IV_MODE. Quien llama no sabe qué subclase
> está usando, solo llama a PROCESS y funciona — eso es polimorfismo."

---

## Ejercicio 06 — OData Clásico (SAP Gateway)
**Archivo:** `06_odata_clasico/ZCL_YPALACIOS_DPC_EXT.abap`

### Qué es
Un servicio OData es una API REST que SAP expone para que aplicaciones externas
(Fiori, SAPUI5, aplicaciones móviles, Excel...) puedan leer y escribir datos.
Esta clase es la que implementa la lógica de ese servicio.

Este es código que yo escribí en la formación (ZCL_Z_YPALACIOS_TRAINI_DPC_EXT).

### Cómo funciona un servicio OData en SAP

```
Transacción SEGW → defines la estructura (como un esquema de BD)
  ↓
SAP genera automáticamente dos clases:
  - MPC (Model Provider Class): define qué campos y entidades expone el servicio
  - DPC (Data Provider Class): lógica vacía — TÚ la rellenas heredando de ella
  ↓
Tu clase (ZCL_..._DPC_EXT) hereda de la DPC generada
y redefine los métodos que necesitas
  ↓
Activar en /IWFND/MAINT_SERVICE → ya es accesible por URL
```

### Los dos métodos que implementé

**GET_ENTITY** — leer un registro por su clave
```
HTTP GET → /sap/opu/odata/sap/ZGW_CENTROCOSTE_YP/CentroCostSet(Kokrs='A000',Kostl='0001000')
```
```abap
METHOD centrocostset_get_entity.
  " SAP pasa las claves en IT_KEY_TAB como pares nombre=valor
  LOOP AT it_key_tab ASSIGNING <fs_key>.
    CASE <fs_key>-name.
      WHEN 'Kokrs'. lv_kokrs = me->normalize_key( <fs_key>-value ).
      WHEN 'Kostl'. lv_kostl = me->normalize_key( <fs_key>-value ).
    ENDCASE.
  ENDLOOP.

  SELECT SINGLE ... FROM csks WHERE ... INTO @er_entity.

  IF sy-subrc <> 0.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception ...
  ENDIF.
ENDMETHOD.
```

**CREATE_ENTITY** — crear un registro nuevo
```
HTTP POST → /sap/opu/odata/sap/ZGW_CENTROCOSTE_YP/CentroCostSet
Body: { "Kokrs": "A000", "Kostl": "0001000", ... }
```
```abap
METHOD centrocostset_create_entity.
  " Leer el JSON que mandó el frontend
  io_data_provider->read_entry_data( IMPORTING es_data = ls_input ).

  INSERT zcsks_test FROM ls_input.

  IF sy-subrc = 0.
    COMMIT WORK AND WAIT.   " ← SIN ESTO LOS DATOS NO SE GUARDAN
    er_entity-mensaje = 'Creado correctamente.'.
  ELSE.
    ROLLBACK WORK.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception ...
  ENDIF.
ENDMETHOD.
```

### El error que tenía el original — lo más importante para la entrevista
```abap
" CÓDIGO ORIGINAL (malo):
if sy-subrc = 0.
else.
endif.
```
El IF/ELSE estaba completamente vacío. Si el registro no existía, el servicio
devolvía HTTP 200 (éxito) con datos vacíos. El frontend no podía saber si
el Centro de Coste existe o no.

La corrección: lanzar `/IWBEP/CX_MGW_BUSI_EXCEPTION` cuando no se encuentra.
SAP Gateway convierte esa excepción automáticamente en un HTTP 404 con
el mensaje de error en JSON.

### COMMIT WORK AND WAIT vs COMMIT WORK
- `COMMIT WORK`: confirma el LUW (unidad de trabajo) de forma asíncrona
- `COMMIT WORK AND WAIT`: espera a que el commit se complete antes de continuar
- En servicios OData siempre usar `AND WAIT` para asegurar que los datos
  están en BD antes de devolver la respuesta al frontend

### LUW — Logical Unit of Work
Una LUW es un conjunto de cambios en BD que se confirman todos a la vez o
ninguno. COMMIT WORK confirma todo. ROLLBACK WORK deshace todo.
SAP no hace COMMIT automático — si el programa termina sin COMMIT, los
cambios se pierden.

### CONVERSION_EXIT_ALPHA_INPUT
Las claves SAP (materiales, centros de coste...) se almacenan con ceros
a la izquierda: '0001000' en lugar de '1000'. Cuando el frontend manda '1000',
hay que convertirlo antes del SELECT. Eso hace CONVERSION_EXIT_ALPHA_INPUT.

El original repetía el CALL FUNCTION en cada WHEN del CASE. Esta versión
lo centraliza en el método privado `normalize_key`.

### Cómo explicarlo en entrevista
> "Este es mi propio código del curso mejorado. Implementé un servicio OData
> clásico con SAP Gateway para exponer Centros de Coste. La mejora más
> importante fue que el original dejaba el IF sy-subrc vacío en el GET_ENTITY,
> devolviendo HTTP 200 aunque el registro no existiera. Lo corregí lanzando
> la excepción de negocio de Gateway para que devuelva un 404 correcto.
> También añadí COMMIT WORK AND WAIT en el CREATE porque sin él los datos no
> se persistían si la LUW se cerraba antes."

---

## Conceptos clave para cualquier entrevista ABAP

### Tablas estándar SAP que usamos
| Tabla | Qué guarda | Campo clave |
|-------|-----------|-------------|
| MARA | Datos generales del material | MATNR |
| MAKT | Descripción del material (por idioma) | MATNR + SPRAS |
| MARC | Material por centro/planta | MATNR + WERKS |
| MBEW | Valoración del material | MATNR + BWKEY |
| CSKS | Centro de coste | KOKRS + KOSTL + DATBI |

### INNER JOIN vs LEFT OUTER JOIN vs FOR ALL ENTRIES
- `INNER JOIN`: solo devuelve filas donde hay match en AMBAS tablas. Si un material no tiene texto en MAKT, no aparece.
- `LEFT OUTER JOIN`: devuelve TODAS las filas de la tabla izquierda aunque no haya match. Si no hay texto, el campo queda vacío.
- `FOR ALL ENTRIES IN gt_tabla WHERE campo = gt_tabla-campo`: un SELECT por cada fila de la tabla interna (malo en rendimiento si la tabla es grande). Si la tabla interna está vacía, lee TODO.

### SY-SUBRC — el código de retorno del sistema
Después de casi cualquier operación SAP pone un valor en SY-SUBRC:
- `0` = éxito
- `4` = no encontrado / warning
- `8` o más = error

Siempre comprobar SY-SUBRC después de SELECT, INSERT, UPDATE, DELETE, CALL FUNCTION.

### Prefijos de nombres de objetos Z
- `ZR_` = Report (programa ejecutable)
- `ZCL_` = Class
- `ZFM_` o `ZFG_` = Function Module / Function Group
- `ZI_` = Interface
- `ZT_` o `ZTT_` = Type / Type Table (diccionario)
- `ZS_` = Structure (diccionario)

---

## Preguntas frecuentes en entrevista y cómo responderlas

**"¿Qué diferencia hay entre REUSE_ALV y CL_SALV_TABLE?"**
> REUSE_ALV es el ALV clásico basado en módulos de función, más sencillo pero
> menos flexible. CL_SALV_TABLE es la versión orientada a objetos, más moderna
> y configurable. Permite colorear filas, añadir botones propios, capturar
> eventos con clases. En proyectos nuevos se usa CL_SALV_TABLE o CL_GUI_ALV_GRID
> (esta última cuando necesitas edición inline).

**"¿Cuándo usarías un Módulo de Función en lugar de un método de clase?"**
> Los FM siguen siendo necesarios cuando: necesitas llamarlo desde un sistema
> externo por RFC, cuando es un FM estándar de SAP al que llamas tú, o cuando
> el proyecto ya tiene una arquitectura basada en FM. En proyectos nuevos
> prefiero encapsular la lógica en clases y exponer un método público.

**"¿Qué es un BAdI?"**
> Business Add-In. Es un punto de extensión que SAP deja en su código estándar
> para que podamos añadir lógica de negocio sin modificar el código de SAP.
> Funciona como un interfaz: SAP define qué métodos se pueden implementar y
> cuándo se llaman. Tú creates una clase que implementa esa interfaz y SAP
> la llama automáticamente en el momento adecuado.

**"¿Qué es un Enhancement Spot?"**
> Es el contenedor de BAdIs en el Enhancement Framework moderno (desde SAP 7.0).
> Agrupa varios BAdIs relacionados. Se gestiona en la transacción SE18 (definición)
> y SE19 (implementación). Los BAdIs dentro de un Enhancement Spot pueden ser
> clásicos o de instancia.

**"¿Qué hace COMMIT WORK AND WAIT?"**
> Confirma la Unidad de Trabajo Lógica (LUW) actual — todos los cambios en BD
> desde el último COMMIT. El AND WAIT hace que el programa espere a que el commit
> termine antes de continuar. Sin COMMIT, todos los INSERT/UPDATE/DELETE se
> deshacen al terminar el programa. En servicios OData es especialmente importante
> porque el framework cierra el contexto rápidamente y sin COMMIT los datos se pierden.

**"¿Qué es FOR ALL ENTRIES y cuándo NO usarlo?"**
> FOR ALL ENTRIES hace un SELECT por cada fila de la tabla interna. Si tienes
> 1000 filas, hace 1000 queries. El problema principal: si la tabla interna está
> vacía, el WHERE se ignora y lee TODA la tabla de BD (potencialmente millones de
> filas). Por eso siempre hay que comprobar que la tabla no está vacía antes de
> usarlo. Hoy en día se prefiere usar JOIN directo cuando es posible.
