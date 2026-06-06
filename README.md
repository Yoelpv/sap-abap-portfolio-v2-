# Portafolio ABAP — Yoel Palacios

Ejercicios de desarrollo SAP construidos durante la formación TAW10 / TAW11 / TAW12
y proyectos prácticos con **SAP GUI**, **Eclipse ADT** y **SAP Gateway**.

Entornos: **ECC / S/4HANA On-Premise** · **S/4HANA BTP Cloud**

---

## Ejercicios de formación (TAW10 / TAW11 / TAW12)

Construidos a partir del código real del curso — cada ejercicio muestra el antes y el después.

| # | Ejercicio | Tecnología | Qué demuestra |
|---|-----------|------------|---------------|
| 1 | [Reporte materiales](desarrollos/formacion/01_reporte_materiales/ZR_MATERIALES_YPALACIOS.abap) | Open SQL · SELECTION-SCREEN · CL_SALV_TABLE | JOIN de 3 tablas, idioma dinámico, ALV moderno |
| 2 | [Modularización con INCLUDEs](desarrollos/formacion/02_modularizacion/) | FORM/ENDFORM · INCLUDE · Eventos ABAP | Arquitectura Main + _TOP + _F01, MODIFY tabla Z |
| 3 | [ALV SALV avanzado](desarrollos/formacion/03_alv_salv_avanzado/ZR_ALV_SALV_AVANZADO.abap) | CL_SALV_TABLE · Eventos · Clase local | Coloreado de filas, botón toolbar, SET HANDLER |
| 4 | [Módulo de función](desarrollos/formacion/04_modulo_funcion/ZFM_MATERIAL_GET_LIST.abap) | Function Group · BAPIRET2 | Patrón de error estándar SAP, parámetros opcionales |
| 5 | [Clase OOP + Factory](desarrollos/formacion/05_clase_oo/ZCL_MATERIAL_MANAGER.abap) | ABAP OO | Abstracta · Herencia · Polimorfismo · Patrón Factory |
| 6 | [OData clásico SAP Gateway](desarrollos/formacion/06_odata_clasico/ZCL_YPALACIOS_DPC_EXT.abap) | SAP Gateway · MPC/DPC · SEGW | GET_ENTITY + CREATE_ENTITY, COMMIT WORK, HTTP 404 |

---

## Ejercicios adicionales (On-Premise)

| Ejercicio | Módulo | Tecnología |
|-----------|--------|------------|
| [ALV Clásico — Equipos PM](desarrollos/alv_clasico/ZR_EQUIP_ALV.abap) | PM | cl_salv_table · Selection Screen · Iconos de estado |
| [Enhancement — BAdI MM](desarrollos/enhancements/ZBADI_MATERIAL_SAVE.abap) | MM | Enhancement Framework · BAdI · Interface ABAP OO |

---

## Ejercicios avanzados (BTP Cloud / RAP)

| Ejercicio | Módulo | Tecnología |
|-----------|--------|------------|
| [Fiori RAP — Equipos PM](desarrollos/fiori/) | PM | RAP Managed · Fiori Elements · OData V4 |
| [Fiori RAP — Reclamaciones SD](desarrollos/sd_claims/) | SD | RAP · Determinations · Actions · DCL · ETag |
| [CDS Views — Analítica SD](desarrollos/ZI_SalesSummaryByOrg.cds) | SD | CDS Views · JOIN · Agregaciones |

---

## Herramientas

SAP GUI · Eclipse ADT · SAP BTP Trial · SE11 · SE19 · SEGW · ST05
